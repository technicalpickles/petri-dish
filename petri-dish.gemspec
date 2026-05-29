# frozen_string_literal: true

require_relative "lib/petri_dish/version"

Gem::Specification.new do |spec|
  spec.name = "pickleton-petri-dish"
  spec.version = PetriDish::VERSION
  spec.authors = ["Josh Nichols"]
  spec.email = ["josh.nichols@gmail.com"]

  spec.summary     = "Isolated, repeatable experiments against agentic coding tools."
  spec.description = "petri-dish runs Claude Code sessions inside isolated cenv environments, captures hook events, and correlates them into structured results. Your ~/.claude is production; the dish is where you do science."
  spec.homepage = "https://github.com/technicalpickles/petri-dish"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir[
    "lib/**/*",
    "bin/petri-dish",
    "hooks/**/*",
    "scripts/**/*",
    "README.md",
    "LICENSE",
    "CONTRIBUTING.md"
  ]
  spec.bindir = "bin"
  spec.executables = ["petri-dish"]
  spec.require_paths = ["lib"]
end
