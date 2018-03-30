#!/usr/bin/env ruby

require 'rest-client'
require 'json'

require_relative 'options'
require_relative 'helpers'

@options = Options.new

site = RestClient::Resource.new(
  "#{@options.proto}://#{@options.host}:#{@options.port}/rest/",
  user:     @options.user,
  password: @options.passwd
)
