require 'rbbt'
require 'rbbt/workflow'
require 'sinatra/base'
require 'json'

require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/misc'
require 'rbbt/rest/common/users'

require 'rbbt/rest/entity/locate'
require 'rbbt/rest/entity/helpers'
require 'rbbt/rest/entity/render'
require 'rbbt/rest/entity/list'
require 'rbbt/rest/entity/map'
require 'rbbt/rest/entity/rest'
require 'rbbt/rest/entity/favourites'
require 'rbbt/rest/entity/finder'

require 'rbbt/rest/entity/entity_card'
require 'rbbt/rest/entity/entity_list_card'
require 'rbbt/rest/entity/entity_map_card'
require 'rbbt/rest/entity/action_card'
require 'rbbt/rest/entity/list_container'
require 'rbbt/rest/entity/action_controller'
require 'rbbt/rest/knowledge_base'

require 'rbbt/statistics/rank_product'


module Sinatra
  module RbbtRESTEntity
    def self.registered(base)
      base.module_eval do
        helpers EntityRESTHelpers


        get /\/entity.*/ do
          @cache_type = :asynchronous if @cache_type.nil?
          pass
        end

        #{{{ Finder

        get '/find' do
          raise "No finder defined" unless settings.respond_to? :finder and not settings.finder.nil?
          halt 200 if params[:term].nil? or params[:term].empty?
          term = params[:term]
          if request.xhr?
            sorted_results = finder_find(term)
            content_type "application/json" 
            halt 200, sorted_results.to_json
          else
            url = find_entity_url(term)
            redirect to(url)
          end
        end

        post '/find' do
          term = consume_parameter :term 
          url = find_entity_url(term)
          redirect to(url)
        end



        #{{{ Entities

        get '/entity/:entity_type/:entity' do
          entity_type = consume_parameter :entity_type
          entity = consume_parameter :entity

          entity = Entity::REST.restore_element(entity)

          entity_type = Entity::REST.restore_element(entity_type)

          entity = setup_entity(entity_type, entity, @clean_params)

          @entity = entity

          entity_render(entity, @clean_params)
        end

        get '/entity_action/:entity_type/:action/:entity' do
          entity_type = consume_parameter :entity_type
          entity = consume_parameter :entity
          action = consume_parameter :action

          entity = Entity::REST.restore_element(entity)

          entity_type = Entity::REST.restore_element(entity_type)

          entity = setup_entity(entity_type, entity, @clean_params)

          @entity = entity

          entity_action_render(entity, action, @clean_params)
        end

        #{{{ Entity lists

        get '/entity_list/:entity_type/new/' do
          entity_type = consume_parameter :entity_type

          entity_type = Entity::REST.restore_element(entity_type)

          mod = Entity.formats[entity_type.split(":").first]
          list = mod.setup([])

          entity_list_action_render(list, 'new', "New #{mod} list", @clean_params.merge(:entity_type => entity_type))
        end
 
        get '/entity_list/:entity_type/edit/:list_id' do
          entity_type = consume_parameter :entity_type
          list_id = consume_parameter :list_id

          entity_type = Entity::REST.restore_element(entity_type)
          list_id = Entity::REST.restore_element(list_id)

          list = Entity::List.load_list(entity_type.split(":").first, list_id, user)

          entity_list_action_render(list, 'edit', list_id, @clean_params)
        end
               
        get '/entity_list/:entity_type/:list_id' do
          entity_type = consume_parameter :entity_type
          list_id = consume_parameter :list_id

          entity_type = Entity::REST.restore_element(entity_type)
          list_id = Entity::REST.restore_element(list_id)

          list = Entity::List.load_list(entity_type.split(":").first, list_id, user)

          case @format
          when :raw, :literal
            content_type "text/tab-separated-values"
            user_file = Entity::List.list_file(entity_type.split(":").first, list_id, user)
            send_file user_file if File.exist? user_file

            global_file = Entity::List.list_file(entity_type.split(":").first, list_id, nil)
            send_file global_file if File.exist? global_file

            raise "List file not found: #{ list_id }"
          when :json
            content_type "application/json"
            halt 200, list_json(list)
          when :info
            content_type "application/json"
            halt 200, list.info.to_json
          when :list
            content_type "text/plain"
            halt 200, list * "\n"
          when :name
            name = list.name
            if name.respond_to? :list_link
              a = name.list_link :length, list_id.sub(/ \(format:.*?\)|$/, " (format: Name)"), :ensembl => false
              redirect to(a.match(/href=(["'])(.*?)\1/)[2])
            else
              content_type "text/plain"
              halt 200, name * "\n"
            end
          when :ensembl
            ensembl = list.ensembl
            a = ensembl.list_link :length, list_id.sub(/ \(format:.*?\)|$/, " (format: Ensembl)")
            redirect to(a.match(/href=(["'])(.*?)\1/)[2])
          else
            entity_list_render(list, list_id)
          end
        end

        get '/entity_list_action/:entity_type/:action/:list_id' do
          entity_type = consume_parameter :entity_type
          list_id = consume_parameter :list_id
          action = consume_parameter :action

          entity_type = Entity::REST.restore_element(entity_type)
          list_id = Entity::REST.restore_element(list_id)
          list = Entity::List.load_list(entity_type.split(":").first, list_id, user)

          entity_list_action_render(list, action, list_id, @clean_params)
        end

        post '/entity_list/:entity_type/:list_id' do
          list_id = consume_parameter :list_id

          list_id = list_id.gsub("'", '"')

          entity_type = consume_parameter :entity_type
          entity_type = Entity::REST.restore_element(entity_type)

          type, format = entity_type.split(":")

          entities = consume_parameter :entities
          entity_file = consume_parameter :entities__param_file

          entities = fix_input(:array, entities, entity_file)

          annotations = consume_parameter :annotations
          annotations = JSON.parse(annotations)
          
          annotations[:format] = format if format

          annotations[:annotation_types] ||= [type]

          mod = Kernel.const_get(type)
          list = mod.setup(entities.reject{|e| e.empty?}, annotations)

          Entity::List.save_list(type, list_id, list, user)

          redirect to(Entity::REST.entity_list_url(list_id, type))
        end

        #{{{ List Management
        
        get '/entity_list/intersect/:entity_type/:list_id' do
          entity_type = consume_parameter :entity_type
          list_id = consume_parameter :list_id
          other_list_id = consume_parameter :other_list_id

          entity_type = Entity::REST.restore_element(entity_type)
          type = entity_type.split(":").first

          list_id = Entity::REST.restore_element(list_id)
          list = Entity::List.load_list(type, list_id, user)

          other_list_id = Entity::REST.restore_element(other_list_id)
          other_list = Entity::List.load_list(type, other_list_id, user)

          new_list = list.subset(other_list)
          new_list_id = [list_id, other_list_id] * " ^ "
          new_list_id = [Misc.digest(list_id), Misc.digest(other_list_id)] * " ^ " if new_list_id.length > 200

          Entity::List.save_list(type, new_list_id, new_list, user) 

          redirect to(Entity::REST.entity_list_url(new_list_id, type))
        end
 
        get '/entity_list/remove/:entity_type/:list_id' do
          entity_type = consume_parameter :entity_type
          list_id = consume_parameter :list_id
          other_list_id = consume_parameter :other_list_id

          entity_type = Entity::REST.restore_element(entity_type)
          type = entity_type.split(":").first

          list_id = Entity::REST.restore_element(list_id)
          list = Entity::List.load_list(type, list_id, user)

          other_list_id = Entity::REST.restore_element(other_list_id)
          other_list = Entity::List.load_list(type, other_list_id, user)

          new_list = list.remove(other_list)
          new_list_id = [list_id, other_list_id] * " - "
          new_list_id = [Misc.digest(list_id), Misc.digest(other_list_id)] * " ~ " if new_list_id.length > 200

          Entity::List.save_list(type, new_list_id, new_list, user) 

          redirect to(Entity::REST.entity_list_url(new_list_id, type))
        end
 
        get '/entity_list/add/:entity_type/:list_id' do
          entity_type = consume_parameter :entity_type
          list_id = consume_parameter :list_id
          other_list_id = consume_parameter :other_list_id

          entity_type = Entity::REST.restore_element(entity_type)
          type = entity_type.split(":").first

          list_id = Entity::REST.restore_element(list_id)
          list = Entity::List.load_list(type, list_id, user)

          other_list_id = Entity::REST.restore_element(other_list_id)
          other_list = Entity::List.load_list(type, other_list_id, user)

          new_list = list.concat(other_list)
          new_list_id = [list_id, other_list_id] * " PLUS "
          new_list_id = [Misc.digest(list_id), Misc.digest(other_list_id)] * " PLUS " if new_list_id.length > 200

          Entity::List.save_list(type, new_list_id, new_list, user) 

          redirect to(Entity::REST.entity_list_url(new_list_id, type))
        end

        #{{{ Entity maps
   
        get '/entity_map/:entity_type/:column/:map_id' do
          entity_type = consume_parameter :entity_type
          map_id = consume_parameter :map_id
          column = consume_parameter :column

          entity_type = Entity::REST.restore_element(entity_type)
          column = Entity::REST.restore_element(column)
          map_id = Entity::REST.restore_element(map_id)

          map = Entity::Map.load_map(entity_type.split(":").first, column, map_id, user)

          case @format
          when :name
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, user)
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, nil) unless File.exist? file
            new = TSV.open(file).change_key "Associated Gene Name"
            new_id = map_id << " [Names]"
            Entity::Map.save_map(entity_type, column, new_id, new, user)
            redirect to(Entity::REST.entity_map_url(new_id, entity_type, column))
          when :ensembl
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, user)
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, nil) unless File.exist? file
            new = TSV.open(file).change_key "Ensembl Gene ID"
            new_id = map_id << " [Ensembl]"
            Entity::Map.save_map(entity_type, column, new_id, new, user)
            redirect to(Entity::REST.entity_map_url(new_id, entity_type, column))
          when :pvalue_score
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, user)
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, nil) unless File.exist? file
            tsv =  TSV.open(file)
            tsv.process tsv.fields.first do |value|
              value = value.flatten.first if Array === value
              - Math.log(value.to_f.abs) * (value.to_f >= 0 ? 1 : -1)
            end
            tsv.fields = [tsv.fields.first + " score"]
            tsv.type = :single
            tsv.cast = :to_f
            new_id = map_id << " [Pvalue score]"
            column = 'Pvalue Score'
            Entity::Map.save_map(entity_type, column, new_id, tsv, user)
            redirect to(Entity::REST.entity_map_url(new_id, entity_type, column))
          when :ranks
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, user)
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, nil) unless File.exist? file
            tsv =  TSV.open(file, :cast => :to_f)
            new = tsv.ranks_for(tsv.fields.first)
            new_id = map_id << " [Ranks]"
            column = 'Ranks'
            Entity::Map.save_map(entity_type, column, new_id, new, user)
            redirect to(Entity::REST.entity_map_url(new_id, entity_type, column))
          when :invert_ranks
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, user)
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, nil) unless File.exist? file
            tsv =  TSV.open(file)
            size = tsv.size
            tsv.process "Rank" do |v|
              if Array === v
                [(size - v.first.to_i).to_s]
              else
                (size - v.to_i).to_s
              end
            end
            new_id = map_id.dup
            column = 'Ranks'
            Entity::Map.save_map(entity_type, column, new_id, tsv, user)
            redirect to(Entity::REST.entity_map_url(new_id, entity_type, column))
          when :raw, :literal
            content_type "text/tab-separated-values"
            user_file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, user)
            send_file user_file if File.exist? user_file

            global_file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, nil)
            send_file global_file if File.exist? global_file

            raise "Map file not found: #{ map_id }"
          when :json
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, user)
            file = Entity::Map.map_file(entity_type.split(":").first, column, map_id, nil) unless File.exist? file

            content_type "application/json"
            tsv = TSV.open(file)
            halt 200, tsv.to_json
          else
            map = Entity::Map.load_map(entity_type.split(":").first, column, map_id, user)
            raise "Map not found: #{ map_id }" if map.nil?
            entity_map_render(map_id, entity_type.split(":").first, column)
          end
        end

        get '/entity_map_action/:entity_type/:column/:action/:map_id' do
          action = consume_parameter :action

          entity_type = Entity::REST.restore_element(consume_parameter :entity_type)
          column = Entity::REST.restore_element(consume_parameter :column)
          map_id = Entity::REST.restore_element(consume_parameter :map_id)

          map = Entity::Map.load_map(entity_type.split(":").first, column, map_id, user)

          entity_map_action_render(map, action, map_id, @clean_params)
        end

 
        get '/entity_map/rename/:entity_type/:column/:map_id' do
          new_id = params[:new_name]

          entity_type = Entity::REST.restore_element(params[:entity_type])
          column = Entity::REST.restore_element(params[:column])
          map_id = Entity::REST.restore_element(params[:map_id])

          base_type = entity_type.split(":").first
          map = Entity::Map.load_map(base_type, column, map_id, user)

          Entity::Map.save_map(entity_type, column, new_id, map, user)

          redirect to(Entity::REST.entity_map_url(new_id, entity_type, column))
        end

        get '/entity_map/rank_products' do
          map1 = consume_parameter :map1
          map2 = consume_parameter :map2

          map1 = Entity::REST.restore_element(map1)
          map2 = Entity::REST.restore_element(map2)

          entity_type = consume_parameter :entity_type
          column = consume_parameter :column
          column2 = consume_parameter :column2
          entity_type = Entity::REST.restore_element(entity_type)
          column = Entity::REST.restore_element(column)

          file1 = Entity::Map.map_file(entity_type.split(":").first, column, map1, user)
          file1 = Entity::Map.map_file(entity_type.split(":").first, column, map1, nil) unless File.exist? file1
          raise "Map not found: #{ map1 }" unless File.exist? file1
          tsv1 =  TSV.open(file1, :cast => :to_f) 

          file2 = Entity::Map.map_file(entity_type.split(":").first, column2, map2, user)
          file2 = Entity::Map.map_file(entity_type.split(":").first, column2, map2, nil) unless File.exist? file2
          raise "Map not found: #{ map2 } - #{ file2 }" unless File.exist? file2
          tsv2 =  TSV.open(file2, :cast => :to_f)

          tsv1 = tsv1.select :key => tsv2.keys
          tsv1.attach tsv2, :fields => tsv2.fields

          new = TSV.setup(tsv1.rank_product(tsv1.fields), :key_field => tsv1.key_field, :fields => ["Log rank-product"], :type => :single, :cast => :to_f)
          new.entity_options = tsv1.entity_options
          new.namespace = tsv1.namespace

          new_id = "Rank products of #{ map1 } ~ #{ map2 }"
          if new_id.length > 200
            new_id = "Rank products of #{ Misc.digest(map1) } ~ #{ Misc.digest(map2) }"
          end

          column = 'Log rank-product'
          Entity::Map.save_map(entity_type, column, new_id, new, user)
          redirect to(Entity::REST.entity_map_url(new_id, entity_type, column))
        end

        #{{{{{{{{{{{{{{
        #{{{ PROPERTIES
        #{{{{{{{{{{{{{{

        get '/entity_property/:property/:entity_type/:entity' do
          entity_type = consume_parameter :entity_type
          entity = consume_parameter :entity
          property = consume_parameter :property
          args = consume_parameter :args

          if args.nil?
            args = []  
          else
            args = begin
                     JSON.parse(args)
                   rescue
                     args
                   end
          end

          case args
          when Hash
            args = [args] 
          when String
            args = args.split(/[,\|]/)
          end

          entity_type = Entity::REST.restore_element(entity_type)

          entity = setup_entity(entity_type, entity, @clean_params)

          begin
            res = entity.send(property,*args)
          rescue
            if entity.respond_to?(:format) and  entity.base_type.respond_to?(:default_format) and entity.format != entity.base_type.default_format
              entity = entity.to(:default)
              Log.warn "Error computing property #{property} for #{entity}. Automatically changing entity format to default"
              retry
            else
              raise $!
            end
          end

          case res
          when String
            content_type "application/json"
            halt 200, '"' + res + '"'
          when Fixnum
            content_type :text
            halt 200, res.to_s
          else
            content_type "application/json"
            halt 200, res.to_json
          end
        end

        get '/entity_list_property/:property/:entity_type/:list_id' do
          entity_type = consume_parameter :entity_type
          list_id = consume_parameter :list_id
          property = consume_parameter :property

          args = consume_parameter :args

          if args.nil?
            args = []  
          else
            args = begin
                     JSON.parse(args)
                   rescue
                     args
                   end
          end

          case args
          when Hash
            args = [args] 
          when String
            args = args.split(/[,\|]/)
          end


          entity_type = Entity::REST.restore_element(entity_type)
          list_id = Entity::REST.restore_element(list_id)

          list = Entity::List.load_list(entity_type.split(":").first, list_id, user)

          content_type "application/json"
          halt 200, list.send(property, *args).to_json
        end

        post '/entity_list_property/:property/:entity_type' do
          entity_type = consume_parameter :entity_type
          property = consume_parameter :property
          list = consume_parameter :list
          info = consume_parameter :info
          args = consume_parameter :args

          info = (info.nil? or info.empty?) ? {} : JSON.parse(info)
          entity_type = Entity::REST.restore_element(entity_type)
          list = Misc.prepare_entity(list.split(/[,|]/), entity_type, info)
          list.extend AnnotatedArray

          args = (args.nil? or args.empty?) ? nil : begin JSON.parse(args) rescue args end
          case args
          when Hash
            args = [args] 
          when String
            args = args.split(/[,\|]/)
          end

          begin
            res = list.send(property,*args)
          rescue
            Log.exception $!
            if list.respond_to?(:format) and list.base_type.respond_to?(:default_format) and list.format != list.base_type.default_format
              list = list.to(:default)
              Log.warn "Error computing property #{property} for list. Automatically changing list format to default"
              retry
            else
              raise $!
            end
          end

          case res
          when String
            content_type "application/json"
            halt 200, '"' + res + '"'
          when Fixnum
            content_type :text
            halt 200, res.to_s
          else
            content_type "application/json"
            halt 200, res.to_json
          end
        end



        #{{{{{{{{{{{{{{
        #{{{ FAVOURITES
        #{{{{{{{{{{{{{{


        #{{{ Favourite entities

        post '/add_favourite_entity/:entity_type/:entity' do
          entity_type = consume_parameter :entity_type
          entity = consume_parameter :entity

          entity_type = Entity::REST.restore_element(entity_type)

          entity = setup_entity(entity_type, entity, @clean_params)

          add_favourite_entity(entity)

          halt 200
        end

        post '/remove_favourite_entity/:entity_type/:entity' do
          entity_type = consume_parameter :entity_type
          entity = consume_parameter :entity

          entity_type = Entity::REST.restore_element(entity_type)

          entity = setup_entity(entity_type, entity, @clean_params)

          remove_favourite_entity(entity)

          halt 200
        end


        get '/favourite_entities' do
          content_type "application/json"

          favs = {}
          favourite_entities.each{|type, list|
            type_favs = {}
            list.each do |entity| 
              next unless entity.respond_to? :link
              info = entity.info
              info.delete :annotation_types
              default = entity.respond_to?(:default) ? entity.default || entity.to_s : entity.to_s
              type_favs[entity] = {:info => info, :link => entity.link, :code => entity, :id => default, :name => (entity.respond_to?(:name) ? entity.name || entity : entity) } 
            end
            favs[type] = type_favs
          }

          favs.to_json
        end
 
        #{{{ Favourite entity lists

        post '/add_favourite_entity_list/:entity_type/:list' do
          entity_type = consume_parameter :entity_type
          list = consume_parameter :list

          list = Entity::REST.restore_element(list)

          entity_type = Entity::REST.restore_element(entity_type).split(":").first

          add_favourite_entity_list(entity_type, list)

          halt 200
        end

        post '/remove_favourite_entity_list/:entity_type/:list' do
          entity_type = consume_parameter :entity_type
          list = consume_parameter :list

          list = Entity::REST.restore_element(list)
          entity_type = Entity::REST.restore_element(entity_type).split(":").first

          remove_favourite_entity_list(entity_type, list)

          halt 200
        end


        get '/favourite_entity_lists' do
          content_type "application/json"

          favs = favourite_entity_lists

          favs.to_json
        end

        #{{{ Favourite entity maps
 
        post '/add_favourite_entity_map/:entity_type/:column/:map' do
          entity_type = consume_parameter :entity_type
          column = consume_parameter :column
          map = consume_parameter :map

          map = Entity::REST.restore_element(map)

          entity_type = Entity::REST.restore_element(entity_type).split(":").first
          column = Entity::REST.restore_element(column)

          add_favourite_entity_map(entity_type, column, map)

          halt 200
        end

        post '/remove_favourite_entity_map/:entity_type/:column/:map' do
          entity_type = consume_parameter :entity_type
          column = consume_parameter :column
          map = consume_parameter :map

          map = Entity::REST.restore_element(map)

          entity_type = Entity::REST.restore_element(entity_type).split(":").first
          column = Entity::REST.restore_element(column)

          remove_favourite_entity_map(entity_type, column, map)

          halt 200
        end


        get '/favourite_entity_maps' do
          content_type "application/json"

          favs = favourite_entity_maps

          favs.to_json
        end

 
      end
    end
  end
end

