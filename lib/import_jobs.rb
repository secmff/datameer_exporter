
require 'import_section'

class ImportJobs < ImportSection
  def initialize(site, options)
    super(site, options, 'import-job')
  end

  def touch(job, oldid, newid)
    return unless @options.upload
    if job['properties'].has_key?('file')
      upload_file(job, oldid)
      trigger_job(newid)
    end
  end

  def upload_file(job, id)
    job['properties']['file'].each do |full_fn|
      fn      = File.basename(full_fn)
      begin
        content = File.read(File.join(@options.output, @section, id, fn))
      rescue Errno::ENOENT
        puts "Ignore file #{fn}"
        next
      end
      url     = u("#{@options.webhdfs}/webhdfs/v1#{full_fn}")
      RestClient.put(url, content, params: hadoop_create_params )
    end
  end

  def trigger_job(id)
    @site['job-execution'].post("", params: {configuration: id})
  end

  def hadoop_create_params
    {
      'op'                 => 'CREATE',
      'user.name'          => 'datameer',
      'namenoderpcaddress' => @options.datanode,
      'createflag'         => '',
      'createparent'       => true,
      'overwrite'          => true,
    }
  end
end
