require 'rbbt/util/open'
require 'rbbt/rest/common/render'

require 'haml'
module KnowledgeBaseRESTHelpers

  def association_render(pair, database = nil)
    database ||= pair.database
    template_file = locate_association_template(database)

    locals = {:pair => pair, :database => database}

    render(template_file, locals, nil)
  end
end
