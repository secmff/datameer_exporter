require 'pp'
require 'pry'

require_relative 'helpers'

module TopLevelSummary
  def wanted_items
    filename = File.join(@options.output, "#{@section}.json")
    if ! File.file? filename
      puts "Unable to open #{filename}: is this a datameer export?"
      exit -1
    end

    JSON[File.read(filename)]['elements']
  end
end

class ImportSection
  def initialize(site, options, section)
    @site = site
    @options = options
    @section = section
  end

  def sync
    wanted  = wanted_items

    wanted.each do |item|
      (current_item, id) = find_and_remove(item)
      if current_item
        next if skip(item)

        unless compare(item, current_item)
          update(item, id)
        end
      else
        create(item)
      end
    end

    @current.each do |item|
      delete(item)
    end
  end

  def update(item, id)
    @site[u("#{@section}/#{id}")].put(update_item(item))
  end

  def update_item(item)
    item.to_json
  end

  def create(item)
    @site["#{@section}"].post(item.to_json)
  end

  def delete(item)
    @site[u("#{@section}/#{name(item)}")].delete
  end

  def current
    return @current if @current
    @current = current_items
  end

  def name(item)
    item['file']['name']
  end

  def same?(a, b)
    a['name'] == name(b)
  end

  def find_and_remove(item)
    i = current.index { |a| same?(a, item) }
    if i
      found = @current.delete_at(i)
      [JSON[@site["#{@section}/#{found['id']}"].get], found['id']]
    end
  end

  def skip(item)
    false
  end

  def compare(a, b)
    true
  end

  def current_items
    JSON[@site[@section].get]
  end

  def wanted_items
    wanted = []
    config_dir = File.join(@options.output, @section)
    Dir.foreach(config_dir) do |item|
      next if item == '.' or item == '..'
      wanted << JSON[File.read(File.join(config_dir, item, 'item.json'))]
    end
    wanted
  end
end

class Connections < ImportSection
  def initialize(site, options)
    super(site, options, 'connections')
  end

  def compare(a, b)
    a = cleanup_before_compare(a)
    b = cleanup_before_compare(b)
    a == b
  end

  def cleanup_before_compare(item)
    item.delete('version')
    item['file'].delete('uuid')
    %w(password sshKey tableau_password jdbc_connection_authentication_type
       dataStoreTemplate).each do |key|
      item['properties'].delete(key)
    end
  end
end

class ImportJobs < ImportSection
  def initialize(site, options)
    super(site, options, 'import-job')
  end

  def create(item)
    PP.pp(item)
    super(item)
  end
end
