#!/usr/bin/env ruby
# frozen_string_literal: true

# Migrates prompt.md files from v1 (prompt-check protocol) to v2 (hook-driven).
#
# Changes:
# 1. Replace Protocol sections that mention "Prompt check" with simplified version
# 2. Replace "After All Tests" sections with SIGNAL_FILE instruction
# 3. Add "After All Tests" + SIGNAL_FILE if missing

TESTS_DIR = File.join(__dir__, "..", "tests")

SIMPLE_PROTOCOL = <<~PROTOCOL.rstrip
  ## Protocol

  Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.
PROTOCOL

SIMPLE_AFTER = <<~AFTER.rstrip
  ## After All Tests

  Write "done" to the SIGNAL_FILE.
AFTER

Dir.glob("#{TESTS_DIR}/*/prompt.md").sort.each do |path|
  test_name = File.basename(File.dirname(path))
  text = File.read(path)
  changed = false

  # Skip if already has SIGNAL_FILE (already v2)
  if text.include?("SIGNAL_FILE") && !text.include?("Prompt check") && !text.include?("prompt check")
    puts "Skip (already v2): #{test_name}"
    next
  end

  # 1. Replace Protocol section that contains "Prompt check"
  #    Match from "## Protocol" to the next "##" heading or "## Test" heading
  if text =~ /^## Protocol\n/
    # Find the protocol section boundaries
    proto_start = text.index("## Protocol\n")
    # Find the next ## heading after the protocol
    rest_after_proto = text[proto_start + "## Protocol\n".length..]
    next_heading = rest_after_proto.index(/^## /)

    if next_heading
      old_protocol = text[proto_start, "## Protocol\n".length + next_heading]
      if old_protocol.include?("Prompt check") || old_protocol.include?("prompt check")
        text = text.sub(old_protocol, SIMPLE_PROTOCOL + "\n\n")
        changed = true
      end
    end
  end

  # 2. Replace "After All Tests" section
  if text =~ /^## After All Tests\n/
    after_start = text.index("## After All Tests\n")
    old_after = text[after_start..]

    unless old_after.include?("SIGNAL_FILE")
      text = text[0...after_start] + SIMPLE_AFTER + "\n"
      changed = true
    end
  elsif !text.include?("SIGNAL_FILE")
    # 3. Add After All Tests if missing entirely
    text = text.rstrip + "\n\n" + SIMPLE_AFTER + "\n"
    changed = true
  end

  if changed
    File.write(path, text)
    puts "Migrated: #{test_name}"
  else
    puts "Skip (no changes needed): #{test_name}"
  end
end
