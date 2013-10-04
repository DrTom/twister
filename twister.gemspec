# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'twister/version'

Gem::Specification.new do |spec|
  spec.name          = "twister"
  spec.version       = Twister::VERSION
  spec.authors       = ["Thomas Schank"]
  spec.email         = ["DrTom@schank.ch"]
  spec.description   = %q{"Invoke commands on a remote machine through ssh"}
  spec.summary       = %q{"Invoke commands on a remote machine through ssh"}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "net-ssh", ">= 2.6.0"
  spec.add_runtime_dependency "net-scp", ">= 1.1.2"
  spec.add_runtime_dependency "slop", ">= 3.4.0"
end
