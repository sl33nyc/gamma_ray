require 'bundler/setup'
require 'active_record'

Bundler.setup

require 'gamma_ray'
require 'aws-sdk'

ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require 'rspec/rails'
require 'dummy/db/schema.rb'

def active_record_gem_version
  Gem::Version.new(ActiveRecord::VERSION::STRING)
end

def params_wrapper(args)
  if defined?(::Rails) && active_record_gem_version >= Gem::Version.new("5.0.0.beta1")
    { params: args }
  else
    args
  end
end

RSpec.configure do |config|
  # some (optional) config here
end
