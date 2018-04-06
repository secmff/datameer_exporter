
require 'addressable/uri'

def mkdir(directory)
  Dir.mkdir(directory) unless File.directory?(directory)
end

def u(url)
  Addressable::URI.parse(url).normalize.to_str
end
