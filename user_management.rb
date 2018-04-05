require 'pp'
require 'net/http'
require 'uri'

require_relative 'helpers'
require_relative 'import_section'


class UserManagement < ImportSection
  def update(item, _id)
    @site[u("#{@section}/#{name(item)}")].put(update_item(item))
  end

  def name(item)
    item['name']
  end

  def same?(a, b)
    name(a) == name(b)
  end

  def find_and_remove(item)
    i = current.index { |a| same?(a, item) }
    i && @current.delete_at(i)
  end

  def current_items
    items = JSON[@site[@section].get]
    if items['maxResults'] < items['total']
      items = JSON[@site["#{@section}?maxResults=#{items['total']}"].get]
    end
    items['elements']
  end

end

class UserManagementRoles < UserManagement
  include TopLevelSummary

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
  include TopLevelSummary

  def initialize(site, options)
    super(site, options, 'user-management/groups')
  end
end

class UserManagementUsers < UserManagement
  def initialize(site, options)
    super(site, options, 'user-management/users')
  end

  def for_all_users
    current.each do |user|
      next if name(user) == 'admin'
      yield(user)
    end
  end

  def reset_passwords
    for_all_users { |user| reset_password(user) }
  end

  def login_users
    for_all_users { |user| login_user(user) }
  end

  def name(item)
    item['username']
  end

  def update_item(item)
    item.delete('username')
    item.to_json
  end

  def create(item)
    super(item)
  end

  def reset_password(user)
    @site[u("/user-management/password/#{name(user)}")].put('Welcome01')
  end

  def login_user(user)
    uri = URI.parse("#{@options.proto}://#{@options.host}:#{@options.port}/browser")

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(name(user), "Welcome01")
    response = http.request(request)
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
