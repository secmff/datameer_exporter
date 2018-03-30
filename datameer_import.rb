#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'pp'

require_relative 'options'
require_relative 'helpers'

@options = Options.new

site = RestClient::Resource.new(
  "#{@options.proto}://#{@options.host}:#{@options.port}/rest/",
  user:     @options.user,
  password: @options.passwd
)

def user_management_items(site, section)
  items = JSON[site["user-management/#{section}"].get]
  if items['maxResults'] < items['total']
    items = JSON[site["user-management/#{section}"].get(
                   maxResults: items['total']
                 )]
  end
  items = items['elements']
end

def user_management_sync(site, section, compare = Proc.new { :true })
  filename = File.join(@options.output, 'user-management', "#{section}.json")
  if ! File.file? filename
    puts "I don't think #{@options.output} contains a datameer export"
    exit -1
  end

  current = user_management_items(site, section)
  wanted  = JSON[File.read(filename)]['elements']

  wanted.each do |item|
    begin
      # does it exits?
      if i = current.index { |a| a['name'] == item['name'] }
        # don't fix default items
        next if ['ANALYST', 'ADMIN'].index(item['name'])
        unless compare.call(item, current[i])
          # update
          site[u("user-management/#{section}/#{item['name']}")].put(item.to_json)
        end
      else
        # create
        site["user-management/#{section}"].post(item.to_json)
      end
    ensure
      # no longer wanted
      current.delete_if { |a| a['name'] == item['name'] }
    end
  end

  # remove
  current.each do |item|
    puts "delete #{item['name']}"
    site[u("user-management/#{section}/#{item['name']}")].delete
  end
end

def compare_roles(a, b)
  a['capabilities'].sort == b['capabilities'].sort
end

user_management_sync(site, 'roles', method(:compare_roles))
user_management_sync(site, 'groups')
