# frozen_string_literal: true

require "optparse"
require "fileutils"

module PetriDish
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def run
      if @argv.empty?
        usage
        exit 1
      end

      command = @argv.shift
      case command
      when "run"      then cmd_run
      when "list"     then cmd_list
      when "results"  then cmd_results
      when "setup"    then cmd_setup
      when "help", "--help", "-h"
        usage
      else
        $stderr.puts "Unknown command: #{command}"
        usage
        exit 1
      end
    end

    private

    def tests_dir
      @tests_dir ||= ENV["PETRIDISH_CULTURES_DIR"] || File.join(Dir.pwd, "petri")
    end

    def results_dir
      @results_dir ||= File.join(Dir.pwd, "results")
    end

    def parse_tests_dir_flag!
      parser = OptionParser.new do |opts|
        opts.on("--tests-dir DIR", "Override the tests directory") { |d| @tests_dir = d }
      end
      parser.order!(@argv)
    end

    def cmd_run
      parse_tests_dir_flag!
      options = { deny: false, debug: false, keep: false }
      parser = OptionParser.new do |opts|
        opts.on("--deny", "Deny all permission prompts") { options[:deny] = true }
        opts.on("--debug", "Show hook events in real time") { options[:debug] = true }
        opts.on("--keep", "Don't kill tmux on completion") { options[:keep] = true }
      end
      parser.parse!(@argv)

      test_name = @argv.shift
      unless test_name
        $stderr.puts "Usage: petri run <test> [options]"
        exit 1
      end

      validate_test!(test_name)
      runner = Runner.new(test_name, tests_dir: tests_dir, results_dir: results_dir, **options)
      runner.run!
    end

    def cmd_list
      parse_tests_dir_flag!
      puts "Available tests in #{tests_dir}:\n\n"
      each_test do |name, config|
        puts "  \e[32m#{name}\e[0m"
        puts "    #{config.description}"
        puts "    env: #{config.environment[:name]}, mode: #{config.prompt_mode}, timeout: #{config.runtime[:timeout]}s"
        puts ""
      end
    end

    def cmd_results
      test_filter = @argv.shift

      unless File.directory?(results_dir)
        puts "No results yet."
        return
      end

      Dir.glob("#{results_dir}/*/").sort.each do |test_dir|
        test_name = File.basename(test_dir)
        next if test_filter && test_name != test_filter

        runs = Dir.glob("#{test_dir}/*/").sort.reverse
        next if runs.empty?

        puts "\e[32m#{test_name}\e[0m (#{runs.size} run#{'s' if runs.size != 1})"
        runs.each do |run_dir|
          timestamp = File.basename(run_dir)
          has_results = File.exist?(File.join(run_dir, "results.md"))
          has_transcript = File.exist?(File.join(run_dir, "transcript.log"))
          status = has_results ? "results" : "no results"
          status += ", transcript" if has_transcript
          puts "  #{timestamp}  (#{status})"
        end
        puts ""
      end
    end

    def cmd_setup
      parse_tests_dir_flag!
      clean = @argv.delete("--clean")
      test_filter = @argv.shift

      tests = if test_filter
                validate_test!(test_filter)
                [test_filter]
              else
                available_tests
              end

      if clean
        tests.each { |name| teardown_test(name) }
      else
        tests.each { |name| setup_test(name) }
      end
    end

    def setup_test(test_name)
      config = Config.new(File.join(tests_dir, test_name))
      env = Environment.new(config.environment[:name])

      puts "\e[32m[setup]\e[0m Setting up: #{test_name}"

      if config.runtime[:work_dir] == "/tmp/sandbox-test"
        setup_scratch_project
      end

      env.create!
      env.merge_settings!(config.environment[:settings])
      env.inject_hooks!(prompt_mode: config.prompt_mode)
      env.trust!(config.runtime[:work_dir])

      config.environment[:plugins].each do |plugin|
        env.install_plugin!(marketplace: plugin[:marketplace], plugin: plugin[:plugin])
      end

      puts "\e[32m[setup]\e[0m #{test_name} ready\n\n"
    end

    def teardown_test(test_name)
      config = Config.new(File.join(tests_dir, test_name))
      env = Environment.new(config.environment[:name])
      puts "\e[32m[setup]\e[0m Cleaning: #{test_name}"
      env.clean!
    end

    def setup_scratch_project
      scratch = "/tmp/sandbox-test"
      if File.directory?(File.join(scratch, ".git"))
        puts "\e[32m[setup]\e[0m Scratch project already exists"
        return
      end

      puts "\e[32m[setup]\e[0m Creating scratch project at #{scratch}"
      FileUtils.mkdir_p(scratch)
      system("git", "-C", scratch, "init")
      File.write(File.join(scratch, "README.md"), "# Sandbox Test Project\n")
      system("git", "-C", scratch, "add", "README.md")
      system("git", "-C", scratch, "commit", "-m", "init")
      FileUtils.mkdir_p(File.join(scratch, ".claude"))
    end

    def validate_test!(name)
      test_dir = File.join(tests_dir, name)
      unless File.directory?(test_dir)
        $stderr.puts "Test not found: #{name}"
        $stderr.puts "Tests dir: #{tests_dir}"
        $stderr.puts "Available tests: #{available_tests.join(', ')}"
        exit 1
      end
    end

    def available_tests
      Dir.glob("#{tests_dir}/*/config.yml").map { |p| File.basename(File.dirname(p)) }.sort
    end

    def each_test
      available_tests.each do |name|
        config = Config.new(File.join(tests_dir, name))
        yield name, config
      end
    end

    def usage
      puts <<~USAGE
        Usage: petri <command> [options]

        Commands:
          run <test> [--deny] [--debug] [--keep] [--tests-dir DIR]
          list                    List available tests
          results [test]          Show past results
          setup [test]            Create environments
          setup --clean [test]    Tear down environments
          help                    Show this help

        Tests dir resolution order:
          1. --tests-dir flag
          2. $PETRIDISH_CULTURES_DIR environment variable
          3. ./petri/ in current working directory
      USAGE
    end
  end
end
