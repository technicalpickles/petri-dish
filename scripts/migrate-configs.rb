#!/usr/bin/env ruby
# frozen_string_literal: true

# Migrates test configs from v1 (sidecar) to v2 (hooks) format.
# Uses text manipulation rather than YAML.dump to preserve formatting.

require "yaml"

TESTS_DIR = File.join(__dir__, "..", "tests")

Dir.glob("#{TESTS_DIR}/*/config.yml").sort.each do |path|
  test_name = File.basename(File.dirname(path))
  text = File.read(path)

  # Skip if already migrated (has prompt_mode, no sidecar)
  unless text.include?("sidecar:")
    puts "Skip (no sidecar): #{test_name}"
    next
  end

  data = YAML.safe_load(text)
  sidecar = data["sidecar"] || {}
  mode = sidecar["mode"] || "accept"
  timeout = sidecar["timeout"] || 300

  # 1. Remove the sidecar block (and trailing newline)
  text.gsub!(/\nsidecar:\n(?:  .+\n)*/, "\n")

  # 2. Add prompt_mode at the end
  text.rstrip!
  text << "\n\nprompt_mode: #{mode}\n"

  # 3. Add timeout to runtime if not already there
  unless text.match?(/^  timeout:/)
    # Insert timeout as last line of runtime block
    text.sub!(/^(runtime:\n(?:  .+\n)*)/) do
      "#{$1}  timeout: #{timeout}\n"
    end
  end

  # 4. Move permissions array into settings.permissions.allow
  env = data["environment"] || {}
  if env["permissions"].is_a?(Array)
    perms = env["permissions"]
    if perms.empty?
      # Just remove empty permissions
      text.sub!(/^  permissions: \[\]\n/, "")
    else
      # Build the settings.permissions.allow block
      perms_yaml = perms.map { |p| "        - #{p}" }.join("\n")

      # Remove the old permissions block
      text.sub!(/^  permissions:\n(?:    - .+\n)*/, "")

      # Add permissions into settings
      if text.match?(/^    sandbox:/)
        # Insert after settings block content
        text.sub!(/^(  settings:\n(?:    .+\n(?:      .+\n)*)*)/) do
          "#{$1}    permissions:\n      allow:\n#{perms_yaml}\n"
        end
      elsif text.match?(/^  settings: \{\}/)
        text.sub!("  settings: {}", "  settings:\n    permissions:\n      allow:\n#{perms_yaml}")
      end
    end
  end

  # 5. Update preamble path
  text.gsub!("lib/preamble-sandbox-lean.md", "lib/preambles/sandbox.md")
  text.gsub!("lib/preamble-sandbox.md", "lib/preambles/sandbox.md")

  File.write(path, text)
  puts "Migrated: #{test_name}"
end
