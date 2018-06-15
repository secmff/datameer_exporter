
require 'import_section'

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
    item
  end
end
