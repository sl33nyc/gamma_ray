# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gamma_ray/version'

Gem::Specification.new do |spec|
  spec.name          = "gamma_ray"
  spec.version       = GammaRay::VERSION
  spec.authors       = ["Transfix"]
  spec.email         = ["jonathan@transfix.io"]
  spec.summary       = 'GammaRay data logger'
  spec.description   = 'Ruby client interface for GammaRay logging'
  spec.homepage      = 'http://transfix.io'
  spec.license       = 'MIT'

  spec.files         = Dir.glob('lib/**/*')
  spec.test_files    = Dir.glob('spec/**/*')
  spec.require_paths = ["lib"]

  spec.add_dependency "request_store", '1.3.1'

  spec.add_dependency "aws-sdk", '2.3.9'

  spec.add_dependency "rails", [">= 4.0", "< 5.2"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'activerecord', [">= 4.0", "< 5.2"]
end
