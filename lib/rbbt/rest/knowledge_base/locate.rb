module KnowledgeBaseRESTHelpers

  def self.association_resources
    @association_resources ||= []
  end

  def association_resources
    [Rbbt.share.views.find(:lib)] +  KnowledgeBaseRESTHelpers.association_resources
  end

  def locate_association_template_from_resource(resource, database = nil)
    if database == "Default" 
      path = resource.association["Default.haml"]
      if path.exists?
        return path
      else
        return nil
      end
    end

    path = resource.association[database + '.haml']
    return path if path.exists?

    nil
  end   

  def locate_association_template(database)

    association_resources.each do |resource|
      path = locate_association_template_from_resource(resource, database)
      return path if path and path.exists?
    end

    association_resources.each do |resource|
      path = locate_association_template_from_resource(resource, "Default")
      return path if path and path.exists?
    end

    raise "Template not found for association database: #{ Misc.fingerprint database }"
  end
end
