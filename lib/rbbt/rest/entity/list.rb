require 'rbbt/entity'
require 'cgi'

module Entity

  class << self
    attr_accessor :entity_list_cache
  end

  self.entity_list_cache     = "var/entity_list"
  
  module List

    def self.list_file(entity_type, id, user = nil)
      id = Misc.sanitize_filename(id)

      entity_type = entity_type.split(":").first

      raise "Ilegal list id: #{ id }" unless Misc.path_relative_to Entity.entity_list_cache, File.join(Entity.entity_list_cache, id)

      path = if user.nil?
        File.join(Entity.entity_list_cache, entity_type.to_s, id)
      else
        File.join(Entity.entity_list_cache, user.to_s, entity_type.to_s, id)
      end

      path
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
      path = list_file(entity_type, id, :public) unless path != nil and File.exists? path
      path = list_file(entity_type, id) unless path != nil and File.exists? path

      begin
        list = Annotated.load_tsv TSV.open(path)
        list.extend AnnotatedArray
        list
      rescue
        nil
      end
    end

    def self.save_list(entity_type, id, list, user = nil)
      path = list_file(entity_type, id, user)

      Misc.lock path do
        begin
          Open.write(path, Annotated.tsv(list, :all).to_s)
        rescue
          FileUtils.rm path if File.exists? path
          raise $!
        end
      end
    end

    def self.delete_list(entity_type, id, user)
      path = list_file(entity_type, id, user)

      "This list does not belong to #{ user }: #{[entity_type, id] * ": "}" unless File.exists? path

      Misc.lock path do
        begin
          FileUtils.rm path if File.exists? path
        rescue
          raise $!
        end
      end
    end
  end
end

