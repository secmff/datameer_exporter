require 'pp'

require_relative 'helpers'
require_relative 'import_section'


class UserManagement < ImportSection
  def current_items
    items = JSON[@site[@section].get]
    if items['maxResults'] < items['total']
      items = JSON[@site["#{@section}?maxResults=#{items['total']}"].get]
    end
    items['elements']
  end
end

class UserManagementRoles < UserManagement
  def initialize(site, options)
    super(site, options, 'user-management/roles')
  end

  def skip(item)
    ['ANALYST', 'ADMIN'].index(name(item))
  end

  def compare(a, b)
    a['capabilities'].sort == b['capabilities'].sort
  end
end

class UserManagementGroups < UserManagement
  def initialize(site, options)
    super(site, options, 'user-management/groups')
  end
end

class UserManagementUsers < UserManagement
  include DirectoryConfigurable

  def initialize(site, options)
    super(site, options, 'user-management/users')
  end

  def name(item)
    item['username']
  end

  def update_item(item)
    item.delete('username')
    item.to_json
  end

  def find_and_remove(item)
    user = super(item)
    JSON[@site["user-management/users/#{name(user)}"].get] if user
  end

  def compare(a, b)
    a['username'] == b['username'] &&
      a['groups'].sort == b['groups'].sort &&
      a['enabled'] == b['enabled'] &&
      a['roles'].sort == b['roles'].sort &&
      a['additionalInformation'] == b['additionalInformation'] &&
      a['email'] == b['email']
  end
end
