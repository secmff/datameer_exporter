#!/usr/bin/env ruby

require 'rest-client'
require 'json'

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'options'

require 'connections'
require 'import_jobs'
require 'workbooks'
require 'export_jobs'
require 'info_graphics'
require 'user_management'

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

  if options.inituser
    UserManagementUsers.new(site,  options).reset_passwords
    UserManagementUsers.new(site,  options).login_users
  end

  Connections.new(site, options).sync # TODO: put connections doesn't work
  ImportJobs.new(site, options).sync
  WorkBooks.new(site, options).sync
  InfoGraphics.new(site, options).sync
  ExportJobs.new(site, options).sync

  # ExportJobs.new(site, options).delete_all
  # InfoGraphics.new(site, options).delete_all
  # WorkBooks.new(site, options).delete_all

rescue RestClient::ExceptionWithResponse => e
  puts e.message
  puts JSON[e.response]['reason']
  exit
end
