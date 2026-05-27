# frozen_string_literal: true

require "fileutils"
require "json"
require "shellwords"
require "tempfile"
require_relative "config"
require_relative "environment"
require_relative "hook_log"
require_relative "results_builder"
require_relative "transcript"

module Petri
  class StartupFailure < StandardError; end
  class AuthFailure < StandardError; end

  class Runner
    HARNESS_ROOT = File.expand_path("../..", __FILE__)
    POLL_INTERVAL = 2 # seconds
    STARTUP_DEADLINE = 60 # seconds, must see a SessionStart event by then or fail loud
    AUTH_ERROR_PATTERN = %r{API Error: 40[13]|Please run /login|Invalid authentication credentials|authentication_error}

    def initialize(test_name, deny: false, debug: false, keep: false)
      @test_dir = File.join(HARNESS_ROOT, "tests", test_name)
      @config = Config.new(@test_dir)
      @deny = deny
      @debug = debug
      @keep = keep
      @tmux_session = "test-#{@config.name}"
    end

    def run!
      preflight!
      ensure_env!
      run_prepare!

      env = Environment.new(@config.environment[:name])

      # Re-trust after prepare. The setup-time trust call runs before the
      # work_dir exists, so File.realpath falls back to expand_path and stores
      # the trust key under /tmp/... — but Claude resolves symlinks and looks
      # under /private/tmp/... on macOS. Re-trusting here, with the path now
      # existing, lets realpath canonicalize properly.
      env.trust!(@config.runtime[:work_dir])

      results_dir = create_results_dir
      signal_file = File.join(results_dir, "signal")
      transcript_path = File.join(results_dir, "transcript.log")

      env.clear_hook_log!

      prompt = build_prompt(signal_file)
      launch_tmux!(prompt)

      failure = nil
      begin
        poll_for_completion(signal_file, env)
      rescue Interrupt
        log "Interrupted by user"
      rescue StartupFailure, AuthFailure => e
        failure = e
      end

      # Capture transcript first. If we failed, tmux may be dying and we
      # want whatever output Claude printed (auth error, version mismatch, etc.).
      transcript = Transcript.new(@tmux_session)
      transcript.save!(transcript_path) if tmux_alive?

      # Collect artifacts
      hook_log_dest = File.join(results_dir, "hook-events.jsonl")
      FileUtils.cp(env.hook_log_path, hook_log_dest) if File.exist?(env.hook_log_path)

      if failure
        # Tear down tmux now so the error message isn't competing with a live session.
        system("tmux kill-session -t #{@tmux_session} 2>/dev/null")
        report_failure!(failure, transcript_path, results_dir)
        exit 1
      end

      # Build results
      if File.exist?(hook_log_dest)
        builder = ResultsBuilder.new(hook_log_dest, transcript_path, results_dir)
        builder.build!
      end

      # Teardown
      unless @keep
        system("tmux kill-session -t #{@tmux_session} 2>/dev/null")
      end

      # Summary
      results_file = File.join(results_dir, "results.md")
      log ""
      log "Run complete: #{@config.name}"
      log "  Results:    #{File.exist?(results_file) ? results_file : '(not written)'}"
      log "  Hook log:   #{File.exist?(hook_log_dest) ? hook_log_dest : '(not captured)'}"
      log "  Transcript: #{File.exist?(transcript_path) ? transcript_path : '(not captured)'}"
      if @keep
        log "  tmux:       tmux attach -t #{@tmux_session}"
      end
    end

    private

    def run_prepare!
      commands = @config.runtime[:prepare] || []
      return if commands.empty?

      log "Running #{commands.length} prepare step(s)"
      commands.each do |cmd|
        log "  prepare: #{cmd}"
        raise "prepare step failed: #{cmd}" unless system(cmd)
      end
    end

    def preflight!
      %w[claude tmux].each do |cmd|
        unless system("command -v #{cmd} > /dev/null 2>&1")
          raise "Required command not found: #{cmd}"
        end
      end
    end

    def ensure_env!
      env = Environment.new(@config.environment[:name])
      unless env.exists?
        raise "Environment '#{@config.environment[:name]}' not found. Run: petri setup #{@config.name}"
      end
    end

    def create_results_dir
      timestamp = Time.now.strftime("%Y-%m-%dT%H-%M")
      dir = File.join(HARNESS_ROOT, "results", @config.name, timestamp)
      FileUtils.mkdir_p(dir)
      dir
    end

    def build_prompt(signal_file)
      parts = []

      # Preamble
      if @config.runtime[:preamble]
        preamble_path = File.join(HARNESS_ROOT, @config.runtime[:preamble])
        if File.exist?(preamble_path)
          parts << File.read(preamble_path)
          parts << "\n---\n"
        end
      end

      # Main prompt
      prompt_path = @config.prompt_path
      raise "Prompt not found: #{prompt_path}" unless prompt_path.exist?
      parts << prompt_path.read

      # Part suffix
      if @config.runtime[:part_suffix]
        parts << "\n---\n"
        parts << "**INSTRUCTION: #{@config.runtime[:part_suffix]}**"
      end

      # Signal file injection
      if @config.runtime[:inject_results_file]
        parts << "\n---\n"
        parts << "**SIGNAL_FILE: #{signal_file}**"
      end

      parts.join("\n")
    end

    def launch_tmux!(prompt)
      system("tmux kill-session -t #{@tmux_session} 2>/dev/null")

      work_dir = @config.runtime[:work_dir]
      env_dir = Environment.new(@config.environment[:name]).env_path

      prompt_file = Tempfile.new(["petri-prompt-", ".md"], Dir.tmpdir)
      prompt_file.write(prompt)
      prompt_file.close

      model_flag = @config.runtime[:model] ? " --model #{@config.runtime[:model]}" : ""
      launcher = Tempfile.new(["petri-launcher-", ".sh"], Dir.tmpdir)
      launcher.write(<<~SH)
        #!/usr/bin/env bash
        exec env CLAUDE_CONFIG_DIR='#{env_dir}' ENABLE_CLAUDEAI_MCP_SERVERS='false' claude#{model_flag} "$(cat '#{prompt_file.path}')"
      SH
      launcher.close
      File.chmod(0o755, launcher.path)

      @_prompt_file = prompt_file
      @_launcher = launcher

      system("tmux new-session -d -s #{@tmux_session} -c #{work_dir.shellescape}")
      system("tmux send-keys -t #{@tmux_session} #{launcher.path.shellescape} Enter")

      log "Claude launched in tmux session '#{@tmux_session}'"
      log "Attach to watch: tmux attach -t #{@tmux_session}"

      sleep 3
    end

    def poll_for_completion(signal_file, env)
      timeout = @config.runtime[:timeout]
      start = Time.now
      hook_log_lines_seen = 0
      startup_confirmed = false

      log "Polling for completion (timeout: #{timeout}s)"

      loop do
        unless tmux_alive?
          unless startup_confirmed
            raise StartupFailure, "tmux session exited before any SessionStart hook event fired"
          end
          break
        end

        if File.exist?(signal_file) && File.size(signal_file) > 0
          log "Signal file detected. Session complete."
          break
        end

        # Watch for SessionStart in the hook log, firmest signal that Claude
        # actually booted (vs. exited on auth failure / version mismatch / etc.).
        if !startup_confirmed && File.exist?(env.hook_log_path)
          if File.read(env.hook_log_path).include?('"hook_event_name":"SessionStart"')
            startup_confirmed = true
            log "Session started (SessionStart event observed)"
          end
        end

        # Once booted, watch the visible pane for mid-session auth failures.
        # Claude fires SessionStart before its first API call, so an OAuth-stale
        # session can confirm startup, hit 401/403, then sit waiting for input.
        if startup_confirmed && (match = AUTH_ERROR_PATTERN.match(Transcript.new(@tmux_session).capture_visible))
          raise AuthFailure, "API auth error mid-session: #{match[0]}"
        end

        elapsed = Time.now - start
        if !startup_confirmed && elapsed >= STARTUP_DEADLINE
          raise StartupFailure, "no SessionStart event within #{STARTUP_DEADLINE}s (tmux still alive, Claude may be stuck at a login prompt)"
        end

        if elapsed >= timeout
          log "Timeout reached (#{timeout}s). Stopping."
          break
        end

        # Debug: print new hook events as they arrive
        if @debug && File.exist?(env.hook_log_path)
          lines = File.readlines(env.hook_log_path)
          lines[hook_log_lines_seen..].each do |line|
            data = JSON.parse(line) rescue next
            p = data["payload"]
            event = p["hook_event_name"]
            tool = p["tool_name"] || ""
            cmd = p.dig("tool_input", "command") || ""
            $stderr.puts "\e[2m[hook] #{event} #{tool} #{cmd[0..60]}\e[0m"
          end
          hook_log_lines_seen = lines.size
        end

        sleep POLL_INTERVAL
      end
    end

    def report_failure!(err, transcript_path, results_dir)
      label = err.is_a?(AuthFailure) ? "AUTH FAILURE" : "STARTUP FAILURE"
      marker_file = err.is_a?(AuthFailure) ? "AUTH_FAILURE.txt" : "STARTUP_FAILURE.txt"

      $stderr.puts ""
      $stderr.puts "\e[31m[runner] #{label}\e[0m"
      $stderr.puts "  #{err.message}"
      $stderr.puts ""
      $stderr.puts "  Likely causes:"
      $stderr.puts "    - Stale OAuth credentials in the cenv environment."
      $stderr.puts "    - Claude Code version installed for this env can't auth."
      $stderr.puts "    - claude binary missing from PATH inside tmux."
      $stderr.puts ""
      $stderr.puts "  Recovery:"
      $stderr.puts "    petri setup --clean #{@config.name}"
      $stderr.puts "    petri setup #{@config.name}"
      $stderr.puts "    cenv login #{@config.environment[:name]}  # if a /login prompt was shown"
      $stderr.puts ""
      if File.exist?(transcript_path) && File.size(transcript_path) > 0
        $stderr.puts "  Captured tmux output: #{transcript_path}"
        last = File.read(transcript_path).lines.last(20).join
        $stderr.puts "  --- last 20 lines ---"
        $stderr.puts last.gsub(/^/, "  ")
      else
        $stderr.puts "  No tmux output captured (session may have died before printing)."
      end
      $stderr.puts ""
      # Drop a marker so the empty results dir is self-explanatory later.
      File.write(File.join(results_dir, marker_file), "#{err.message}\n")
    end

    def tmux_alive?
      system("tmux has-session -t #{@tmux_session} 2>/dev/null")
    end

    def log(msg)
      puts "\e[32m[runner]\e[0m #{msg}"
    end
  end
end
