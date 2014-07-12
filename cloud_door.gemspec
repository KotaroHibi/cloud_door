# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloud_door/version'

Gem::Specification.new do |spec|
  spec.name          = 'cloud_door'
  spec.version       = CloudDoor::VERSION
  spec.authors       = ['Kotaro Hibi']
  spec.email         = ['hibiheion@gmail.com']
  spec.summary       = %q{This gem can access different cloud storage through same interface.}
  spec.description   = %q{This gem can access different cloud storage through same interface.
This gem supports OneDrive and Dropbox, now.
It will be supported also google drive in the future.}
  spec.homepage      = 'https://github.com/KotaroHibi/cloud_door'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3', '>= 10.3.2'
  spec.add_runtime_dependency 'rest-client', '~> 1.6', '>= 1.6.7'
  spec.add_runtime_dependency 'commander', '~> 4.2', '>= 4.2.0'
  spec.add_runtime_dependency 'rubyzip', '~> 1.1', '>= 1.1.4'
  spec.add_runtime_dependency 'watir', '~> 5.0', '>= 5.0.0'
  spec.add_runtime_dependency 'watir-webdriver', '~> 0.6', '>= 0.6.9'
  spec.add_runtime_dependency 'dropbox-sdk', '~> 1.6', '>= 1.6.4'
  # test libraries
  spec.add_development_dependency 'rspec', '~> 2.99', '>= 2.99.0'
  spec.add_development_dependency 'webmock', '~> 1.18', '>= 1.18.0'
  spec.add_development_dependency 'guard-rspec', '~> 4.2', '>= 4.2.10'
  spec.add_development_dependency 'terminal-notifier-guard', '~> 1.5', '>= 1.5.3'
  spec.add_development_dependency 'fabrication', '~> 2.11', '>= 2.11.2'
  spec.add_development_dependency 'rubocop', '~> 0.23', '>= 0.23.0'
end
