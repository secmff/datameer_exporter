#!/usr/bin/env ruby

require 'rest-client'
require 'json'

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'options'
require 'helpers'

@options = Options.new

site = RestClient::Resource.new(
  "#{@options.proto}://#{@options.host}:#{@options.port}/rest/",
  user:     @options.user,
  password: @options.passwd
)

def download_config(site, section)
  base = File.join(@options.output, section)
  mkdir base
  section_ids =  JSON[site[section].get]
  section_ids.each do |item|
    id = item['id'].to_s
    mkdir(File.join(base, id))
    item_json = site["#{section}/#{id}"].get
    File.write(File.join(base, id, 'item.json'), item_json)
    yield(base, id, item_json) if block_given?
  end
end

def user_management(site, section)
  section=File.join('user-management', section)
  base = File.join(@options.output, section)
  mkdir base
  section_names = JSON[site[section].get]
  if section_names['maxResults'] < section_names['total']
    section_names = JSON[site["#{section}?maxResults=#{section_names['total']}"].get]
  end
  section_names['elements'].each do |element|
    id = element['username']
    mkdir(File.join(base, id))
    File.write(File.join(base, id, 'item.json'), site["#{section}/#{id}"].get)
  end
end

notfound = 0

download_config(site, 'connections')
download_config(site, 'export-job')
download_config(site, 'infographics')
download_config(site, 'workbook')
download_config(site, 'import-job') do |base, id, job_json|
  File.write(File.join(base, id, 'sheet.json'), site["sheet-details/#{id}"].get)
  job = JSON[job_json]

  # download the uploaded files
  if job['properties'].has_key?('file')
    job['properties']['file'].each do |fn|
      filename = File.basename(fn)
      begin
        File.write(File.join(base, id, filename),
                   site["data/import-job/#{id}/download"].get)
      rescue RestClient::NotFound
        puts "didn't find: data/import-job/#{id}/download"
        notfound += 1
        next
      end
    end
  else
    begin
      File.write(File.join(base, id, 'metadata.json'),
                 site["data/import-job/#{id}"].get)
    rescue RestClient::NotFound
      puts "didn't find: data/import-job/#{id}"
      notfound += 1
      next
    end
  end
end

base=File.join(@options.output, 'user-management')
mkdir base
File.write(File.join(base, 'groups.json'), site["user-management/groups"].get)
File.write(File.join(base, 'roles.json'), site["user-management/roles"].get)
user_management(site, 'users')

puts "did not find #{notfound} files"
