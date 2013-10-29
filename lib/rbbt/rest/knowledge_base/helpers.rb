require 'rbbt/util/misc'
require 'rbbt/knowledge_base'

module KnowledgeBaseRESTHelpers
  class << self
    attr_accessor :knowledge_base_dir, :knowledge_bases
  end

  self.knowledge_base_dir     = "var/knowledge_base"

  def prepare_entities_for_json(entities)
    case entities
    when AnnotatedArray
      list_hash(entities)
    when Array
      entities.inject([]){|acc,e| acc << prepare_entities_for_json(e); acc }
    when Hash
      hash = {}
      entities.each do |key,values|
        hash[key] = prepare_entities_for_json(values)
      end
      hash
    when String
      entities
    end
  end

  def get_kb(name)
    @knowledge_bases ||= IndiferentHash.setup({})
    case name
    when :genomics, "genomics"
      @knowledge_bases[name] ||= Genomics.knowledge_base
    else
      @knowledge_bases[name] ||= KnowledgeBase.new File.join(KnowledgeBaseRESTHelpers.knowledge_base_dir, name)
    end
  end

  def user_kb(user)
    @user_knowledge_bases ||= IndiferentHash.setup({})
    @user_knowledge_bases[user] ||= begin
                                 kb = KnowledgeBase.new File.join(KnowledgeBaseRESTHelpers.knowledge_base_dir, File.join('user', user))

                                 kb.syndicate Genomics.knowledge_base, :genomics

                                 user_studies[user].each do |study|
                                   kb.syndicate study.knowledge_base, study
                                 end

                                 kb
                               end
  end

  def get_knowledge_base(name, namespace = nil)
    @knowledge_bases ||= IndiferentHash.setup({})
    @knowledge_bases[name] ||= begin
                                 kb = case 
                                      when [:genomics, "genomics"].include?(name)
                                        Genomics.knowledge_base
                                      when (Misc.path_relative_to(settings.cache_dir, name) and File.exists?(name))
                                        KnowledgeBase.new name
                                      when KnowledgeBase.registry.include?(name)
                                        KnowledgeBase.registry[name]
                                      when Study.studies.include?(name)
                                        Study.setup(name).knowledge_base
                                      when name.to_s == "user"
                                        user_kb(user)
                                      else
                                        KnowledgeBase.new File.join(KnowledgeBaseRESTHelpers.knowledge_base_dir, name)
                                      end

                                 namespace ? kb.version(namespace) : kb
                               end
  end

end
