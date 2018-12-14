require 'rbbt/util/misc'
require 'rbbt/knowledge_base'
require 'rbbt/sources/organism'

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

  def user_kb(user = nil)
    user ||= @user
    @@user_kbs ||= {}
    @@user_kbs[user] ||= begin
                           dir = KnowledgeBaseRESTHelpers.knowledge_base_dir.users.common
                           kb = KnowledgeBase.new(dir, Organism.default_code("Hsa"))
                           
                           KnowledgeBaseRESTHelpers.syndications.each do |name, new|
                             Log.low "Syndicating database #{ name } for user #{user}"
                             kb.syndicate name, new
                           end if KnowledgeBaseRESTHelpers.syndications.any?

                           user_studies[user].each do |study|
                             Study.setup(study)
                             kb.syndicate study, study.knowledge_base
                           end if defined? user_studies

                           kb
                         end
  end

  def get_knowledge_base(name=:user, namespace = nil)
    kb = case name.to_s
           when 'step'
             step_path = cookies[:step_path]
             step_path = params[:step_path] if step_path.nil?
             raise "No step_path" if step_path.nil?
             step = Workflow.fast_load_step(step_path)
             step.knowledge_base
           when "user"
             user_kb(user)
           else
             Genomics.knowledge_base
           end

    (namespace and namespace != kb.namespace) ? kb.version(namespace) : kb
  end

  def association_table(associations = nil, options = {}, &block)
    options = Misc.add_defaults options, :row_ids => :consume, :footer => true
    associations = yield if block_given?

    tsv = case associations
          when Array
            associations.tsv
          when TSV
            associations
          else
            TSV.open(tsv)
          end

    tsv = tsv.to_double{|v| v.nil? ? nil : v.split(";;") } unless tsv.fields.nil? or tsv.fields.empty? or tsv.type == :double

    tsv2html tsv, options
  end

  def serialize_entities(obj)
    case obj
    when Array
      obj.collect{|e| serialize_entities(e)}
    when String
      e = obj
      name = e.respond_to?(:name) ? e.name || e : e
      {:id => e, :name => name, :type => e.base_type, :info => e.info}
    end
  end

  def get_matrix(code)
    name, study = code.split("@")
    Study.setup(study).matrix(name)
  end
end
