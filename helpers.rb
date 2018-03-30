
def mkdir(directory)
  Dir.mkdir(directory) unless File.directory?(directory)
end
