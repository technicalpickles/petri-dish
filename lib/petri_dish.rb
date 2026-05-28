# frozen_string_literal: true

require_relative "petri_dish/version"

module PetriDish
  # Root directory of the installed gem. Used to locate ship-with assets
  # (hooks, preambles). Distinct from user-provided cultures_dir and results_dir.
  def self.root
    File.expand_path("..", __dir__)
  end
end

require_relative "petri_dish/config"
require_relative "petri_dish/environment"
require_relative "petri_dish/hook_log"
require_relative "petri_dish/results_builder"
require_relative "petri_dish/runner"
require_relative "petri_dish/transcript"
require_relative "petri_dish/cli"
