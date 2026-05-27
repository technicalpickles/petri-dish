# frozen_string_literal: true

require_relative "lib/petri/version"

Gem::Specification.new do |spec|
  spec.name = "petri"
  spec.version = Petri::VERSION
  spec.authors = ["Josh Nichols"]
  spec.email = ["josh.nichols@gmail.com"]

  spec.summary = "Isolated, repeatable Claude Code experiments"
  spec.description = "Petri runs Claude Code sessions inside isolated cenv environments, captures hook events, and correlates them into structured results. The cenv environment is the dish; petri is the technician."
  spec.homepage = "https://github.com/technicalpickles/petri"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir[
    "lib/**/*",
    "bin/petri",
    "hooks/**/*",
    "scripts/**/*",
    "README.md",
    "LICENSE",
    "CONTRIBUTING.md"
  ]
  spec.bindir = "bin"
  spec.executables = ["petri"]
  spec.require_paths = ["lib"]
end
