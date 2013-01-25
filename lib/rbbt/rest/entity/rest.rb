require 'rbbt/util/misc'
require 'rbbt/rest/entity/list'

module Entity
  module REST

    #{{{ MISC

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
      klasses << base_type.to_s
      klasses << format if self.respond_to? :format
      klasses.collect{|klass| klass.gsub(/\s/, '_') }
    end
    
    def entity_type
      entity_type = self.respond_to?(:format) ? [base_type, format].compact.join(":") : base_type
    end

    def process_link_options(options)
      attributes = {}
      link_params = entity_link_params

      %w(class style title).each do |at|
        attributes[at.to_sym] = options.delete(at.to_sym) || options.delete(at.to_s) || ""
      end

      attributes[:class] = attributes[:class].split(" ") if String === attributes[:class]

      link_params.merge(options)

      link_params = Misc.hash2GET_params(link_params)

      [attributes, link_params]
    end

    #{{{ LINKS

    def link(options = {})
      return self.collect{|e| e.link } if Array === self

      klasses = self.klasses
      klasses <<  'entity'

      attributes, link_params = process_link_options(options)

      attributes[:class] << klasses
      attributes[:href] = File.join('/', 'entity', entity_type.to_s, self) + "?" + link_params

      text = self.respond_to?(:name)? self.name || self : self
      attributes[:title] = text
      Misc.html_tag('a', text, attributes)
    end

    def action_link(action, text = nil, options = {})
      return self.collect{|e| e.link(action, text) } if Array === self

      klasses = self.klasses
      klasses << 'entity_action'

      attributes, link_params = process_link_options(options)

      attributes[:class] << klasses
      attributes[:href] = File.join('/', 'entity_action', entity_type.to_s, action, self) + "?" + link_params

      if text.nil? or (String === text and text.empty?)
        text = self.respond_to?(:name)? self.name || self : self if text.nil?
        text = [text, action] * "&rarr;"
      end
      Misc.html_tag('a', text, attributes)
    end

    def list_link(text = nil, id = nil, options = {})
      text = self.length if text.nil? or text == :length or (String === text and text.strip.empty?)
      id = options[:id] || Misc.digest((self * "|").inspect) if id.nil? or (String === id and id.empty?)

      Entity::List.save_list(entity_type.to_s, id, self)

      klasses = self.klasses
      klasses << 'entity_list'

      attributes, link_params = process_link_options(options)

      attributes[:class] = klasses
      attributes[:href] = File.join('/', 'entity_list', entity_type.to_s, CGI.escape(id)) + "?" + link_params

      attributes[:title] = id
      Misc.html_tag('a', text, attributes)
    end

    def list_action_link(action, text = nil, id = nil, options = {})
      text = [id, action] * "&rarr;" if text.nil? or (String === text and text.strip.empty?)
      id = options[:id] || Misc.digest((self * "|").inspect) if id.nil? or (String === id and id.empty?)

      Entity::List.save_list(entity_type.to_s, id, self)

      klasses = self.klasses
      klasses << 'entity_list_action'

      attributes, link_params = process_link_options(options)

      attributes[:class] = klasses
      attributes[:href] = File.join('/', 'entity_list', entity_type.to_s, CGI.escape(id)) + "?" + link_params

      attributes[:title] = id
      Misc.html_tag('a', text, attributes)
    end
  end
end

if __FILE__ == $0
  require 'rbbt/entity/gene'

  module Gene
    include Entity::REST
  end

  gene = Gene.setup(["SF3B1"], "Associated Gene Name", "Hsa")

  ddd gene.link
  ddd gene.first.action_link "overview", "Overview", :class => "embedded"
  ddd gene.list_link :length, "test/foo"
  ddd gene.list_action_link 'overview', "test/foo", "just one gene"
  
end
