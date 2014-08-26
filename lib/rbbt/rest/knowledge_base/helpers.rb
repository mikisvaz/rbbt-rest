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
    @@knowledge_bases ||= IndiferentHash.setup({})
    case name
    when :genomics, "genomics"
      @@knowledge_bases[name] ||= Genomics.knowledge_base
    else
      @@knowledge_bases[name] ||= KnowledgeBase.new File.join(KnowledgeBaseRESTHelpers.knowledge_base_dir, name)
    end
  end

  def user_kb(user)
    user = "guest" if user.nil?
    @@user_knowledge_bases ||= IndiferentHash.setup({})
    @@user_knowledge_bases[user] ||= begin
                                       kb = KnowledgeBase.new File.join(KnowledgeBaseRESTHelpers.knowledge_base_dir, File.join('user', user)), Organism.default_code("Hsa")
                                       kb.format["Gene"] = "Ensembl Gene ID"

                                       kb.syndicate Genomics.knowledge_base, :genomics

                                       TSV.traverse user_studies[user], :cpus => 10 do |study|
                                         Study.setup(study)
                                         study.sample_genes if study.has_genotypes?
                                       end 

                                       user_studies[user].each do |study|
                                         Study.setup(study)
                                         kb.syndicate study.knowledge_base, study
                                       end

                                       kb
                                     end
  end

  def get_knowledge_base(name, namespace = nil)
    @@knowledge_bases ||= IndiferentHash.setup({})
    @@knowledge_bases[name] ||= begin
                                  begin
                                    mod = Kernel.const_get name
                                    return mod.knowledge_base if mod.respond_to? :knowledge_base
                                  rescue Exception
                                  end
                                  kb = case 
                                      when [:genomics, "genomics"].include?(name)
                                        Genomics.knowledge_base
                                      when (Misc.path_relative_to(settings.cache_dir, name) and File.exists?(name))
                                        KnowledgeBase.new name
                                      when KnowledgeBase.registry.include?(name)
                                        KnowledgeBase.registry[name]
                                      when (defined? Study and Study.studies.include?(name))
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
