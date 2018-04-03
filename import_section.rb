require 'pp'

require_relative 'helpers'

class ImportSection
  def initialize(site, options, section)
    @site = site
    @options = options
    @section = section
  end

  def sync
    wanted  = wanted_items

    wanted.each do |item|
      if current_item = find_and_remove(item)
        next if skip(item)

        unless compare(item, current_item)
          update(item)
        end
      else
        create(item)
      end
    end

    @current.each do |item|
      delete(item)
    end
  end

  def update(item)
    @site[u("#{@section}/#{name(item)}")].put(update_item(item))
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
    item['name']
  end

  def find_and_remove(item)
    i = current.index { |a| name(a) == name(item) }
    i && @current.delete_at(i)
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
    filename = File.join(@options.output, "#{@section}.json")
    if ! File.file? filename
      puts "I don't think #{@options.output} contains a datameer export"
      exit -1
    end

    JSON[File.read(filename)]['elements']
  end
end

module DirectoryConfigurable
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
  include DirectoryConfigurable

  def initialize(site, options)
    super(site, options, 'connections')
  end

  def name(item)
    item['file']['name']
  end

  def skip(item)
    true
  end

  def current_items
    items = super
    current = []
    items.each do |item|
      current << JSON[@site["#{@section}/#{item['id']}"].get]
    end
    current
  end
end
