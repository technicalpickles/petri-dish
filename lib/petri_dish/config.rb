# frozen_string_literal: true

require "yaml"
require "pathname"

module PetriDish
  class Config
    REQUIRED_KEYS = %w[name description environment runtime].freeze
    REQUIRED_ENV_KEYS = %w[name].freeze
    VALID_PROMPT_MODES = %w[accept deny].freeze

    attr_reader :name, :description, :environment, :runtime, :prompt_mode, :test_dir

    def initialize(test_dir)
      @test_dir = Pathname.new(test_dir).expand_path
      config_path = @test_dir / "config.yml"
      raise "Config not found: #{config_path}" unless config_path.exist?

      data = YAML.safe_load(config_path.read, permitted_classes: [Symbol])
      validate!(data)

      @name = data["name"]
      @description = data["description"]
      @environment = parse_environment(data["environment"])
      @runtime = parse_runtime(data["runtime"])
      @prompt_mode = parse_prompt_mode(data["prompt_mode"])
    end

    def prompt_path
      test_dir / "prompt.md"
    end

    private

    def validate!(data)
      REQUIRED_KEYS.each do |key|
        raise "Missing required key: #{key}" unless data.key?(key)
      end
      REQUIRED_ENV_KEYS.each do |key|
        raise "Missing environment.#{key}" unless data.dig("environment", key)
      end
    end

    def parse_environment(env)
      {
        name: env["name"],
        plugins: (env["plugins"] || []).map { |p| { marketplace: p["marketplace"], plugin: p["plugin"] } },
        settings: env["settings"] || {}
      }
    end

    def parse_runtime(rt)
      {
        work_dir: expand_home(rt["work_dir"] || "."),
        preamble: rt["preamble"],
        inject_results_file: rt.fetch("inject_results_file", true),
        part_suffix: rt["part_suffix"],
        model: rt["model"],
        timeout: rt.fetch("timeout", 300),
        prepare: Array(rt["prepare"])
      }
    end

    def parse_prompt_mode(mode)
      mode ||= "accept"
      raise "Invalid prompt_mode: #{mode}" unless VALID_PROMPT_MODES.include?(mode)

      mode
    end

    def expand_home(path)
      path.sub(/\A~/, Dir.home)
    end
  end
end
