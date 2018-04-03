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

# UserManagementRoles.new(site,  options).sync
# UserManagementGroups.new(site, options).sync
# UserManagementUsers.new(site,  options).sync

Connections.new(site, options).sync
