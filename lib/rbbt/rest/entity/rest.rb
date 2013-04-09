require 'rbbt/util/misc'
require 'rbbt/rest/entity/list'

module Entity
  module REST
    USE_ENSEMBL = true

    REST_ENTITIES = []

    def self.included(base)
      REST_ENTITIES << base
    end

    #{{{ MISC
    
    def self.clean_element(elem)
      elem.gsub('/', '--')
    end
 
    def self.restore_element(elem)
      CGI.unescape(elem.gsub('--', '/'))
    end

    def entity_link_params
      info = self.info
      info.delete :format
      info.delete :annotation_types
      info.delete :annotated_array
      info
    end

    def base_type
      annotation_types.select{|mod| mod.include? Entity::REST }.first.to_s
    end

    def klasses
      klasses = []
      klasses << base_type.to_s if base_type
      klasses << format if self.respond_to? :format and format
      klasses.collect{|klass| klass.gsub(/\s/, '_') }
    end
    
    def entity_type
      entity_type = self.respond_to?(:format) ? [base_type, format].compact.join(":") : base_type
    end

    def process_link_options(options = {}, include_entity_params = true)
      attributes = {}
      link_params = include_entity_params ? entity_link_params : {}

      %w(class style title).each do |at|
        attributes[at.to_sym] = options.delete(at.to_sym) || 
          options.delete(at.to_s) || 
          nil
      end

      attributes[:class] = attributes[:class].split(" ") if String === attributes[:class]

      attributes[:class] = [] if attributes[:class].nil?

      link_params = link_params.merge(options)

      [attributes, link_params]
    end

    #{{{ URLS
    
    def self.entity_url(entity, type, params = {})
      url = File.join('/', 'entity', Entity::REST.clean_element(type.to_s), entity) 
      url << "?" << Misc.hash2GET_params(params) if params.any?
      url
    end

    def self.entity_action_url(entity, type, action, params = {})
      url = File.join('/', 'entity_action', Entity::REST.clean_element(type.to_s), action.to_s, entity)
      url << "?" << Misc.hash2GET_params(params) if params.any?
      url
    end

    def self.entity_list_url(list, type)
      File.join('/', 'entity_list', Entity::REST.clean_element(type.to_s), Entity::REST.clean_element(list))
    end

    def self.entity_list_action_url(list, type, action, params)
      url = File.join('/', 'entity_list_action', Entity::REST.clean_element(type.to_s), action.to_s, Entity::REST.clean_element(list))
      url << "?" << Misc.hash2GET_params(params) if params.any?
      url
    end


    #{{{ LINKS

    def link(text = nil, options = {})
      return self.collect{|e| e.link(text, options) } if Array === self

      klasses = self.klasses
      klasses <<  'entity'

      attributes, link_params = process_link_options(options)

      attributes[:class] << klasses
      attributes[:href] = Entity::REST.entity_url(self, entity_type.to_s, link_params)

      text = self.respond_to?(:name)? self.name || self : self if text.nil?
      attributes[:title] = text if attributes[:title].nil?

      Misc.html_tag('a', text, attributes)
    end


    def action_link(action, text = nil, options = {})
      return self.collect{|e| e.link(action, text) } if Array === self

      klasses = self.klasses
      klasses << 'entity_action'

      attributes, link_params = process_link_options({:title => [action, self] * ": " }.merge(options))

      attributes[:class] << klasses
      attributes[:href] = Entity::REST.entity_action_url(self, entity_type.to_s, action, link_params)

      if text.nil? or (String === text and text.empty?)
        text = self.respond_to?(:name)? self.name || self : self if text.nil?
        text = [text, action] * "&rarr;"
      end
      Misc.html_tag('a', text, attributes)
    end

    def list_link(text = nil, id = nil, options = {})
      options = Misc.add_defaults options, :ensembl => USE_ENSEMBL
      ensembl = Misc.process_options options, :ensembl

      if ensembl and self.respond_to? :ensembl and self.format !~ /^Ensembl /
        return self.ensembl.compact.uniq.list_link(text, id, options.merge({:ensembl => false}))
      end

      text = self.length if text.nil? or text == :length or (String === text and text.strip.empty?)
      id = options[:id] || Misc.digest((self * "|").inspect) if id.nil? or (String === id and id.empty?)

      reuse = options.delete(:reuse)
      reuse = options.delete("reuse") if reuse.nil?
      reuse = true if reuse.nil?

      Entity::List.save_list(entity_type.to_s, id, self) unless reuse and File.exists? Entity::List.list_file(entity_type.to_s, id, self)

      klasses = self.klasses
      klasses << 'entity_list'

      attributes, link_params = process_link_options(options)

      attributes[:class] = klasses
      attributes[:href] = Entity::REST.entity_list_url(id, entity_type.to_s)

      attributes[:title] = id
      Misc.html_tag('a', text, attributes)
    end

    def list_action_link(action, text = nil, id = nil, options = {})
      text = [id, action] * "&rarr;" if text.nil? or (String === text and text.strip.empty?)
      id = options[:id] || Misc.digest((self * "|").inspect) if id.nil? or (String === id and id.empty?)

      reuse = options.delete(:reuse)
      reuse = options.delete("reuse") if reuse.nil?
      reuse = true if reuse.nil?

      Entity::List.save_list(entity_type.to_s, id, self) unless reuse and File.exists? Entity::List.list_file(entity_type.to_s, id, self)

      klasses = self.klasses
      klasses << 'entity_list_action'

      attributes, link_params = process_link_options({:title => [action, id] * ": " }.merge(options), false)

      attributes[:class] = klasses
      attributes[:href] = Entity::REST.entity_list_action_url(id, entity_type.to_s, action, link_params)

      attributes[:title] = id if attributes[:title].nil?
      Misc.html_tag('a', text, attributes)
    end
  end
end
