# frozen_string_literal: true

require_relative "petri/version"

module Petri
  # Root directory of the installed gem. Used to locate ship-with assets
  # (hooks, preambles). Distinct from user-provided tests_dir and results_dir.
  def self.root
    File.expand_path("..", __dir__)
  end
end

require_relative "petri/config"
require_relative "petri/environment"
require_relative "petri/hook_log"
require_relative "petri/results_builder"
require_relative "petri/runner"
require_relative "petri/transcript"
require_relative "petri/cli"
