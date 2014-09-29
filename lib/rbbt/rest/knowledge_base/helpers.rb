require 'rbbt/util/misc'
require 'rbbt/knowledge_base'

module KnowledgeBaseRESTHelpers
  class << self
    attr_accessor :knowledge_base_dir, :syndications

    def add_syndication(name, kb)
      @syndications ||= {}
      @syndications[name] = kb
    end

    def syndications
      @syndications ||= {}
    end
  end

  self.knowledge_base_dir     = Path.setup("var/sinatra/knowledge_bases")

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

  def user_kb(user)
    @@user_kbs ||= {}
    @@user_kbs[user] ||= begin
                           kb = KnowledgeBase.new(KnowledgeBaseRESTHelpers.knowledge_base_dir.users[user], Organism.default_code("Hsa"))
                           
                           KnowledgeBaseRESTHelpers.syndications.each do |name, new|
                             Log.low "Syndicating database #{ name } for user #{user}"
                             kb.syndicate name, new
                           end if KnowledgeBaseRESTHelpers.syndications.any?

                           kb
                         end
  end

  def get_knowledge_base(name=:user, namespace = nil)
    kb = case name.to_s
           when "user"
             user_kb(user)
           else
             Genomics.knowledge_base
           end

    (namespace and namespace != kb.namespace) ? kb.version(namespace) : kb
  end

  def association_table(associations, options = {})
    options = Misc.add_defaults options, :row_ids => :consume, :footer => true
    tsv = case associations
          when Array
            associations.tsv
          when TSV
            associations
          else
            TSV.open(tsv)
          end

    tsv = tsv.to_double{|v| v.split ";;" } unless tsv.type == :double

    tsv2html tsv, options
  end
end
