
require 'import_section'

class WorkBooks < ImportSection
  def initialize(site, options)
    super(site, options, 'workbook')
  end

  def skip(item)
    item['file']['path'] =~ /\.unsaved-configurations\/unsaved/
  end

  # make sure we create the workbooks in a sequence that will work
  def resolve_depends(item)
    item['sheets'].each do |sheet|
      next unless sheet.has_key?('referencedSheet')
      path = sheet['referencedSheet']['workbook']['path']
      wanted.select do |want, oldid|
        want['file']['path'] == path
      end.each do |insert, oldid|
        if i = @state.index {|a| a['path'] == insert['file']['path'] }
          next
        end

        create(insert)
        remove(insert)
      end
    end
  end

  def create(item)
    resolve_depends(item)
    id = super(item)
  end
end
