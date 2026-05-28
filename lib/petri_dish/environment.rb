# frozen_string_literal: true

require "json"
require "fileutils"
require "shellwords"

module PetriDish
  class Environment
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def exists?
      path = env_path
      path && File.directory?(path)
    end

    def env_path
      `cenv path #{name} 2>/dev/null`.strip
    end

    def hook_log_path
      "#{env_path}/hook-events.jsonl"
    end

    def clear_hook_log!
      path = hook_log_path
      File.write(path, "") if File.exist?(path)
    end

    def inject_hooks!(prompt_mode:)
      hooks = {
        "hooks" => {
          "PreToolUse" => [event_logger_hook_with_matcher],
          "PostToolUse" => [event_logger_hook_with_matcher],
          "UserPromptSubmit" => [event_logger_hook_without_matcher],
          "Notification" => [event_logger_hook_without_matcher],
          "Stop" => [event_logger_hook_without_matcher],
          "SubagentStop" => [event_logger_hook_without_matcher],
          "PreCompact" => [event_logger_hook_with_matcher],
          "SessionStart" => [event_logger_hook_with_matcher],
          "SessionEnd" => [event_logger_hook_with_matcher],
          "PermissionRequest" => [permission_handler_hook(prompt_mode)],
          "PermissionDenied" => [event_logger_hook_with_matcher]
        }
      }
      merge_settings!(hooks)
    end

    def create!(bare: false)
      if exists?
        log "Environment '#{name}' already exists, skipping create"
        return
      end
      cmd = "cenv create #{name}"
      cmd += " --bare" if bare
      run!(cmd)
    end

    def clean!
      run("cenv remove #{name}")
    end

    def merge_settings!(settings)
      return if settings.nil? || settings.empty?

      json = JSON.generate(settings)
      run!("cenv settings merge #{name} '#{json}'")
      log "Merged settings into '#{name}'"
    end

    def install_plugin!(marketplace:, plugin:)
      # Add marketplace (idempotent, errors if already added)
      run("cenv run #{name} -- plugin marketplace add #{marketplace}")

      # cenv stores the marketplace under its canonical name (from marketplace.json),
      # which is not always the slug derived from the source URL. Detect it from the
      # list, fall back to the slug if detection fails.
      marketplace_name = detect_marketplace_name(marketplace) || marketplace.tr("/", "-")

      # Install plugin
      run!("cenv run #{name} -- plugin install #{plugin}@#{marketplace_name}")
      log "Installed #{plugin}@#{marketplace_name}"
    end

    def detect_marketplace_name(source)
      output = `cenv run #{name.shellescape} -- plugin marketplace list 2>/dev/null`
      lines = output.lines
      source_idx = lines.index { |l| l.include?("Source:") && l.include?("(#{source})") }
      return nil unless source_idx && source_idx > 0
      lines[source_idx - 1].strip.sub(/^❯\s+/, "").strip
    end

    def trust!(work_dir)
      path = File.realpath(File.expand_path(work_dir)) rescue File.expand_path(work_dir)
      run!("cenv trust #{name} #{path.shellescape}")
      log "Trusted #{path}"
    end

    private

    def event_logger_command
      "PETRIDISH_HOOK_LOG_FILE='#{hook_log_path}' '#{PetriDish.root}/hooks/event-logger.sh'"
    end

    def permission_handler_command(mode)
      "PETRIDISH_HOOK_LOG_FILE='#{hook_log_path}' PETRIDISH_PERMISSION_MODE=#{mode} '#{PetriDish.root}/hooks/permission-handler.sh'"
    end

    def event_logger_hook_with_matcher
      {
        "matcher" => "",
        "hooks" => [{ "type" => "command", "command" => event_logger_command, "timeout" => 5 }]
      }
    end

    def event_logger_hook_without_matcher
      {
        "hooks" => [{ "type" => "command", "command" => event_logger_command, "timeout" => 5 }]
      }
    end

    def permission_handler_hook(mode)
      {
        "matcher" => "",
        "hooks" => [{ "type" => "command", "command" => permission_handler_command(mode), "timeout" => 5 }]
      }
    end

    def run(cmd)
      system(cmd, out: File::NULL, err: File::NULL)
    end

    def run!(cmd)
      unless system(cmd)
        raise "Command failed (exit #{$?.exitstatus}): #{cmd}"
      end
    end

    def log(msg)
      puts "\e[32m[env]\e[0m #{msg}"
    end
  end
end
