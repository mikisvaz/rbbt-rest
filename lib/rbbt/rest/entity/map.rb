require 'rbbt/entity'
require 'cgi'

module Entity

  class << self
    attr_accessor :entity_map_cache
  end

  self.entity_map_cache     = "var/entity_map"
  

  module Map
    def self.map_file(entity_type, column, id, user = nil)
      id = Misc.sanitize_filename(Entity::REST.clean_element(id))
      column = Entity::REST.clean_element(column)

      entity_type = entity_type.split(":").first

      raise "Ilegal map id: #{ id }" unless Misc.path_relative_to Entity.entity_map_cache, File.join(Entity.entity_map_cache, id)

      path = if user.nil?
               Dir.glob(File.join(Entity.entity_map_cache, entity_type.to_s, column, Regexp.quote(id))).first || File.join(Entity.entity_map_cache, entity_type.to_s, column, id)
             else
               Dir.glob(File.join(Entity.entity_map_cache, user.to_s, entity_type.to_s, column, Regexp.quote(id))).first || File.join(Entity.entity_map_cache, user.to_s, entity_type.to_s, column, id)
             end

      path
    end

    def self.map_files(user = nil)
      path = user.nil? ?
        File.join(Entity.entity_map_cache, '*', '*') :
        File.join(Entity.entity_map_cache, user, '*', '*') 

      maps = {}
      Dir.glob(path).each do |file|
        next if File.directory? file

        file = File.expand_path(file)
        raise "Ilegal path: #{ file }. Not relative to #{File.expand_path(Entity.entity_map_cache)}" unless 
          Misc.path_relative_to(File.expand_path(Entity.entity_map_cache), file)

        if user.nil?
          entity_type, column, map = file.split("/")[-2..-1]
        else
          user, entity_type, column, map = file.split("/")[-3..-1]
        end

        maps[entity_type] ||= []
        maps[entity_type][column] ||= []
        maps[entity_type][column] << map
      end

      maps
    end

    def self.load_map(entity_type, column, id, user = nil)
      path = map_file(entity_type, column, id, user)
      path = map_file(entity_type, column, id, :public) unless path != nil and File.exist? path
      path = map_file(entity_type, column, id) unless path != nil and File.exist? path

      begin
        RbbtRESTHelpers.load_tsv(path).first
      rescue
        Log.error{"Error loading map #{ path }: #{$!.message}"}
        nil
      end
    end

    def self.save_map(entity_type, column, id, map, user = nil)
      path = map_file(entity_type, column, id, user)

      Misc.lock path do
        begin
          RbbtRESTHelpers.save_tsv(map, path)
        rescue
          FileUtils.rm path if path and File.exist? path
          raise $!
        end
      end
    end

    def self.delete_map(entity_type, column, id, user)
      path = map_file(entity_type, column, id, user)

      "This map does not belong to #{ user }: #{[entity_type, column, id] * ": "}" unless File.exist? path

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

