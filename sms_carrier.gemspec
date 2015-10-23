# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sms_carrier/version'

Gem::Specification.new do |spec|
  spec.name          = "sms_carrier"
  spec.version       = SmsCarrier::VERSION
  spec.authors       = ["Chen Yi-Cyuan"]
  spec.email         = ["emn178@gmail.com"]

  spec.summary       = %q{SMS composition and delivery framework.}
  spec.description   = %q{SMS on Rails. Compose, deliver and test SMSes using the familiar controller/view pattern.}
  spec.homepage      = "https://github.com/emn178/sms_carrier"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", '>= 4.2.0'
  spec.add_dependency 'actionview', '>= 4.2.0'
  spec.add_dependency "activejob", '>= 4.2.0'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "mocha"
end
