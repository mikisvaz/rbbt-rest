require 'rbbt/entity'
require 'cgi'

module Entity

  class << self
    attr_accessor :entity_list_cache
  end

  self.entity_list_cache     = Path.setup("var/entity_list")
  
  module List

    def self.list_file(entity_type, id, user = nil)
      id = Entity::REST.clean_element(id)
      id = Misc.sanitize_filename(id)

      entity_type = entity_type.to_s.split(":").first

      raise "Ilegal list id: #{ id }" unless Misc.path_relative_to Entity.entity_list_cache, File.join(Entity.entity_list_cache, id)

      path = if user.nil?
        Entity.entity_list_cache[entity_type.to_s][id]
      else
        Entity.entity_list_cache[entity_type.to_s][user.to_s][id]
      end

      path.find
    end

    def self.list_files(user = nil)

      path = user.nil? ?
        File.join(Entity.entity_list_cache, '*', '*') :
        File.join(Entity.entity_list_cache, user, '*', '*') 

      lists = {}
      Dir.glob(path).each do |file|
        next if File.directory? file

        file = File.expand_path(file)
        raise "Ilegal path: #{ file }. Not relative to #{File.expand_path(Entity.entity_list_cache)}" unless 
          Misc.path_relative_to(File.expand_path(Entity.entity_list_cache), file)

        if user.nil?
          entity_type, list = file.split("/")[-2..-1]
        else
          user, entity_type, list = file.split("/")[-3..-1]
        end

        lists[entity_type] ||= []
        lists[entity_type] << list
      end

      lists
    end

    def self.load_list(entity_type, id, user = nil)
      path = list_file(entity_type, id, user)
      path = list_file(entity_type, id, :public) unless path != nil and File.exist? path
      path = list_file(entity_type, id) unless path != nil and File.exist? path

      raise "List not found: #{ id }" if path.nil? or not File.exist? path

      begin
        list = Annotated.load_tsv TSV.open(path)
        list.extend AnnotatedArray
        list
      rescue
        Log.exception $!
        nil
      end
    end

    def self.save_list(entity_type, id, list, user = nil)
      path = list_file(entity_type, id, user)

      Misc.lock path do
        begin
          Open.write(path, Annotated.tsv(list, :all).to_s)
        rescue
          FileUtils.rm path if File.exist? path
          raise $!
        end
      end
    end

    def self.delete_list(entity_type, id, user)
      path = list_file(entity_type, id, user)

      "This list does not belong to #{ user }: #{[entity_type, id] * ": "}" unless File.exist? path

      Misc.lock path do
        begin
          FileUtils.rm path if File.exist? path
        rescue
          raise $!
        end
      end
    end
  end
end

