# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'epub_book/version'

Gem::Specification.new do |spec|
  spec.name          = "epub_book"
  spec.version       = EpubBook::VERSION
  spec.authors       = ["qmliu"]
  spec.email         = ["javy_liu@163.com"]

  spec.summary       = %q{create epub from a book index url and mail to you.}
  spec.description   = %q{create epub from a book index url and mail to you. by setting a default_setting.yml you can use it in shell. }
  spec.homepage      = "https://github.com/javyliu/epub_book"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'http','~> 2.1'
  #spec.add_dependency 'nokogiri','1.6.8.1'
  spec.add_dependency "nokogiri", ">= 1.11.4"
  spec.add_dependency 'eeepub', '~> 0.8.1'
  spec.add_dependency 'zip-zip', '~> 0.3'
  spec.add_dependency 'mail', '~>2.7.0'


  spec.add_development_dependency "bundler",  ">= 2.2.10"
  spec.add_development_dependency "rake",  ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.14.1"
  spec.add_development_dependency "pry-byebug", "~> 3.9"
  spec.add_development_dependency "pry-doc", "~>1.1.0"
end
