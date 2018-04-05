#!/usr/bin/env ruby

require 'rest-client'
require 'json'

require_relative 'options'
require_relative 'import_section'
require_relative 'user_management'

options = Options.new

site = RestClient::Resource.new(
  "#{options.proto}://#{options.host}:#{options.port}/rest/",
  user:     options.user,
  password: options.passwd
)

begin
  UserManagementRoles.new(site,  options).sync
  UserManagementGroups.new(site, options).sync
  UserManagementUsers.new(site,  options).sync

  if options.init
    UserManagementUsers.new(site,  options).reset_passwords
    UserManagementUsers.new(site,  options).login_users
  end

  Connections.new(site, options).sync # TODO: put connections doesn't work
  ImportJobs.new(site, options).sync
rescue RestClient::ExceptionWithResponse => e
  puts e.message
  puts JSON[e.response]['reason']
  exit
end
