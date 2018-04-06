
require 'helpers'

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
    @state = current.clone
  end

  def sync
    wanted.each do |item, old_id|
      if skip(item)
        remove(item)
        next
      end

      (current_item, id) = find(item)
      if current_item
        unless compare(item, current_item)
          update(item, id)
        end
      else
        id = create(item)
      end
      remove(item)
      touch(item, old_id, id)
    end

    @current.each do |item|
      delete(item)
    end
  end

  def delete_all
    current.each do |item|
      next if skip(item)
      delete(item)
    end
  end

  def find(item)
    found = @state.select { |a| same?(a, item) }.first
    [get(found['id']), found['id']] if found
  end

  def remove(item)
    @current.delete_if {|a| same?(a, item) }
  end

  def update(item, id)
    @site[u("#{@section}/#{id}")].put(update_item(item))
  end

  def update_item(item)
    item.to_json
  end

  def create(item)
    ret = @site["#{@section}"].post(item.to_json)
    id  = JSON[ret.body]['configuration-id']
    update_state(item, id)
  end

  def delete(item)
    @site["#{@section}/#{item['id']}"].delete
  end

  def update_state(item, id)
    @state << item['file'].merge('id' => id)
    id
  end

  def touch(_item, _oldid, _newid)
  end

  def resolve_depends(_wanted, _item)
  end

  def current
    return @current if @current
    @current = current_items
  end

  def wanted
    return @wanted if @wanted
    @wanted = wanted_items
  end

  def name(item)
    item['file']['path']
  end

  def same?(a, b)
    a['path'] == name(b)
  end

  def get(id)
    JSON[@site["#{@section}/#{id}"].get]
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
    return @wanted_items if @wanted_items
    wanted = []
    config_dir = File.join(@options.output, @section)
    Dir.foreach(config_dir) do |item|
      next if item == '.' or item == '..' or item == '.DS_Store'
      wanted << [JSON[File.read(File.join(config_dir, item, 'item.json'))],
                 item]
    end
    wanted
  end
end
