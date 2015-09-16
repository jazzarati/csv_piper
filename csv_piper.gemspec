# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'csv_piper/version'

Gem::Specification.new do |spec|
  spec.name          = "csv_piper"
  spec.version       = CsvPiper::VERSION
  spec.authors       = ["Jarrod Sibbison"]
  spec.email         = [""]

  spec.summary       = %q{CSV processing pipeline}
  spec.description   = %q{Simple wrapper to process csv's with a pipeline of testable processors.}
  spec.homepage      = "https://github.com/jazzarati/csv_piper"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 2'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3"
end
