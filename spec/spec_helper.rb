require 'mongoid'
require 'terminal-table'
require File.expand_path('../../lib/mongoid_map_reduce_helper', __FILE__)

ENV["RACK_ENV"] ||= "test"

Mongoid.load!(File.expand_path("../fixtures/mongoid.yml", __FILE__))

require File.expand_path("../fixtures/model", __FILE__)