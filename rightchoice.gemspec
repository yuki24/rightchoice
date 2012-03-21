# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rightchoice/version"

Gem::Specification.new do |s|
  s.name        = "rightchoice"
  s.version     = Rightchoice::VERSION
  s.platform    = Gem::Platform::RUBY
  s.homepage    = "http://github.com/yuki24/rightchoice"
  s.license     = "MIT"
  s.summary     = "always make the right choice!"
  s.description = "rightchoice makes it easier to do a/b testing and multivariate testing. it comes with a beautiful front-end interface."
  s.email       = "mail@yukinishijima.net"
  s.authors     = ["Yuki Nishijima"]

  s.rubyforge_project = "rightchoice"

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.extra_rdoc_files = ['README.rdoc']
  s.require_paths    = ["lib"]

  s.add_dependency 'railties', '> 3.0.0'
  s.add_dependency 'redis', '~> 2.2.2'
  s.add_dependency 'redis-namespace', '~> 1.1.0'
  s.add_dependency 'sinatra', '~> 1.3.1'
  s.add_dependency 'json', '~> 1.6.3'
  s.add_dependency 'rubytree', '~> 0.8.2'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'ruby-debug19'
end
