
require 'optparse'
require 'ostruct'

require 'helpers'

class Options < OpenStruct
  def initialize
    super
    defaults
    parse
  end

  private

  def defaults
    self.proto    = 'http'
    self.host     = 'localhost'
    self.port     = 8080
    self.user     = 'admin'
    self.passwd   = 'admin'
    self.output   = '.'
    self.inituser = false
    self.upload   = false
    self.webhdfs  = 'http://localhost:50075'
    self.datanode = 'localhost:8020'
  end

  def parse
    OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename($0)} -h <host> -p <port>"

      opts.on('-i', '--initialze', 'initialize the users?') do
        self.inituser = true
      end

      opts.on('-f', '--file-upload', 'upload the data files') do
        self.upload = true
      end

      opts.on('-h', '--host HOST', 'datameer hostname HOST') do |arg|
        self.host = arg
      end

      opts.on('-p', '--port PORT', 'datameer port PORT') do |arg|
        self.port = arg
      end

      opts.on('-u', '--user USER', 'datameer user USER') do |arg|
        self.user = arg
      end

      opts.on('-c', '--passwd PASSWORD', 'datameer password PASSWORD') do |arg|
        self.passwd = arg
      end

      opts.on('-s', '--proto PROTO', 'datameer protocol PROTO') do |arg|
        self.proto = arg
      end

      opts.on('-w', '--webhdfs URL', 'hadoop webhdfs URL') do |arg|
        self.webhdfs = arg
      end

      opts.on('-d', '--datanode URL', 'hadoop datanode URL') do |arg|
        self.datanode = arg
      end

      opts.on('-o', '--output DIRECTORY', 'configuration output DIRECTORY') do |arg|
        self.output = File.expand_path(arg)
        begin
          mkdir output
        rescue SystemCallError
          puts "#{arg} unable to create directory"
          puts opts
          exit -1
        end
      end
    end.parse!
  end
end
