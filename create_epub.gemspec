# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'create_epub/version'

Gem::Specification.new do |spec|
  spec.name          = "create_epub"
  spec.version       = CreateEpub::VERSION
  spec.authors       = ["qmliu"]
  spec.email         = ["javy_liu@163.com"]

  spec.summary       = %q{create epub from a book index url and mail to you.}
  spec.description   = %q{create epub from a book index url and mail to you.}
  spec.homepage      = "https://githubs.com/javyliu/create_epub"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'nokogiri','~> 1.6.8'
  spec.add_dependency 'eeepub'
  spec.add_dependency 'zip-zip'
  spec.add_dependency 'mail'


  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-doc"
end
