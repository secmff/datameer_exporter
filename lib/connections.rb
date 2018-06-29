
require 'import_section'

class Connections < ImportSection
  def initialize(site, options)
    super(site, options, 'connections')
  end

  def compare(a, b)
    return false if @options.force
    a = cleanup_before_compare(copy_of(a))
    b = cleanup_before_compare(copy_of(b))
    a == b
  end

  def copy_of(original)
    item = original.dup
    item['file'] = original['file'].dup
    item['properties'] = original['properties'].dup
    item
  end

  def cleanup_before_compare(item)
    item.delete('version')
    item['file'].delete('uuid')
    %w(password sshKey tableau.password jdbc_connection_authentication_type
       dataStoreTemplate).each do |key|
      item['properties'].delete(key)
    end
    item
  end
end
