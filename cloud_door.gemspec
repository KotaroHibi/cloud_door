# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloud_door/version'

Gem::Specification.new do |spec|
  spec.name          = 'cloud_door'
  spec.version       = CloudDoor::VERSION
  spec.authors       = ['Kotaro Hibi']
  spec.email         = ['hibiheion@gmail.com']
  spec.summary       = %q{This gem accesses cloud storage through command line.}
  spec.description   = %q{This gem accesses cloud storage through command line.}
  spec.homepage      = 'https://github.com/KotaroHibi/cloud_door'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rest-client'
  spec.add_development_dependency 'commander'
  spec.add_development_dependency 'rubyzip'
  spec.add_development_dependency 'watir'
  spec.add_development_dependency 'watir-webdriver'
  spec.add_development_dependency 'dropbox-sdk'
  # test libraries
  spec.add_development_dependency 'rspec', '~> 2.99.0'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'terminal-notifier-guard'
  spec.add_development_dependency 'fabrication'
  spec.add_development_dependency 'rubocop'
end
