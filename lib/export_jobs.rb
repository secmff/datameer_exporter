
require 'import_section'

class ExportJobs < ImportSection
  def initialize(site, options)
    super(site, options, 'export-job')
  end
end
