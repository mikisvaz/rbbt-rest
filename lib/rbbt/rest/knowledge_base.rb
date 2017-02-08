require 'rbbt'
require 'rbbt/workflow'
require 'sinatra/base'

require 'rbbt/knowledge_base'
require 'rbbt/rest/knowledge_base/query'
require 'rbbt/rest/knowledge_base/helpers'
require 'rbbt/rest/knowledge_base/locate'
require 'rbbt/rest/knowledge_base/render'
require "sinatra/multi_route"

module Sinatra
  module RbbtRESTKnowledgeBase
    def self.registered(base)
      base.module_eval do
        register Sinatra::MultiRoute

        include RbbtRESTHelpers
        include KnowledgeBaseRESTHelpers

        get '/knowledge_base/:name/:database/children/:entity' do 
          name = consume_parameter :name
          database = consume_parameter :database
          entity = consume_parameter :entity

          kb = get_knowledge_base name
          matches = kb.children(database, entity)
          case @format
          when :tsv
            content_type "text/tab-separated-values"
            halt 200, matches.tsv.to_s
          when :html
            template_render('knowledge_base_partials/matches', {:matches => matches}, "Children: #{ [name, database, entity] }")
          when :json
            content_type :json
            halt 200, matches.target.to_json
          else
            content_type :text
            halt 200, matches.target * "\n"
          end
        end

        get '/knowledge_base/:name/:database/parents/:entity' do 
          name = consume_parameter :name
          database = consume_parameter :database
          entity = consume_parameter :entity

          kb = get_knowledge_base name
          matches = kb.parents(database, entity)
          case @format
          when :tsv
            content_type "text/tab-separated-values"
            halt 200, matches.tsv.to_s
          when :html
            template_render('knowledge_base_partials/matches', {:matches => matches}, "Parents: #{ [name, database, entity] }")
          when :json
            content_type :json
            halt 200, matches.source.to_json
          else
            content_type :text
            halt 200, matches.source * "\n"
          end
        end

        get '/knowledge_base/:name/:database/neighbours/:entity' do 
          name = consume_parameter :name
          database = consume_parameter :database
          entity = consume_parameter :entity

          kb = get_knowledge_base name
          neighbours = kb.neighbours(database, entity)
          case @format
          when :tsv
            content_type "text/tab-separated-values"
            halt 200, neighbours.values.collect{|m| m.tsv.to_s } * "\n\n"
          when :html
            template_render('knowledge_base_partials/matches', {:matches => neighbours}, "Neighbours: #{ [name, database, entity] }")
          when :json
            content_type :json
            neighs = {}
            neighs[:parents] = neighbours[:parents].source if neighbours[:parents]
            neighs[:children] = neighbours[:children].target
            halt 200, neighs.to_json
          else
            content_type :text
            neighs = []
            neighs.concat neighbours[:parents].source if neighbours[:parents]
            neighs.concat neighbours[:children].target
            halt 200, neighs * "\n"
          end
        end

        #get '/knowledge_base/:name/:database/subset' do 
        #  name = consume_parameter :name
        #  database = consume_parameter :database
        #  source = consume_parameter :source
        #  target = consume_parameter :target

        #  source = source == "all" ? :all : source.split(@array_separator) if source
        #  target = target == "all" ? :all : target.split(@array_separator) if target
        #  entities = { :source => source, :target => target }

        #  kb = get_knowledge_base name
        #  subset = kb.subset(database, entities)
        #  case @format
        #  when :tsv
        #    content_type "text/tab-separated-values"
        #    halt 200, subset.tsv.to_s
        #  when :html
        #    template_render('knowledge_base_partials/subset', {:subset => subset}, "Subset: #{ [name, database] }")
        #  when :json
        #    content_type :json
        #    halt 200, subset.source.to_json
        #  else
        #    content_type :text
        #    halt 200, subset.source * "\n"
        #  end
        #end

        route :get, :post, '/knowledge_base/:name/:database/subset' do 
          name = consume_parameter :name
          database = consume_parameter :database
          source = consume_parameter :source
          target = consume_parameter :target

          target = source if target.nil?

          source = source == "all" ? :all : source.split(@array_separator) if source
          target = target == "all" ? :all : target.split(@array_separator) if target

          entities = { :source => source, :target => target }

          kb = get_knowledge_base name
          subset = kb.subset(database, entities)
          case @format
          when :tsv
            content_type "text/tab-separated-values"
            halt 200, subset.tsv.to_s
          when :tsv_json
            content_type :json
            halt 200, subset.tsv.to_json
          when :html
            template_render('knowledge_base_partials/subset', {:subset => subset}, "Subset: #{ [name, database] }")
          when :json
            content_type :json
            halt 200, subset.source.to_json
          else
            content_type :text
            halt 200, subset.source * "\n"
          end
        end


        #{{{ Collection

        post '/knowledge_base/:name/:database/collection_children' do 
          name = consume_parameter :name
          database = consume_parameter :database
          collection = consume_parameter :collection 
          raise ParameterException, "No collection specified" if collection.nil?
          collection = JSON.parse(collection)

          kb = get_knowledge_base name
          matches = collection.keys.inject({}){|acc,type|
            entities = collection[type]
            entities.each do |entity|
              _matches = kb.children(database, entity)
              type = _matches.target_type
              next unless _matches and _matches.any?
              if (acc[type])
                acc[type].concat(_matches)
              else
                acc[type] = _matches
              end
              acc
            end
            acc
          }
          case @format
          when :tsv
            content_type "text/tab-separated-values"
            matches = matches.sort_by{|k,list| list.length }.last.last
            halt 200, matches.tsv.to_s
          when :tsv_json
            content_type :json
            halt 200, {}.to_json if matches.empty?
            matches = matches.sort_by{|k,list| list.length }.last.last
            halt 200, matches.tsv.to_json
          when :html
            template_render('knowledge_base_partials/matches', {:matches => matches}, "Collection Children: #{ [name, database] }")
          when :json
            content_type :json
            _matches = {}
            matches.each{|type,list|
              _matches[type] = list.target
            }
            halt 200, _matches.to_json
          else
            content_type :text
            matches = matches.sort_by{|k,list| list.length }.last.last
            halt 200, matches.target * "\n"
          end
        end

        post '/knowledge_base/:name/:database/collection_parents' do 
          name = consume_parameter :name
          database = consume_parameter :database
          collection = consume_parameter :collection 
          raise ParameterException, "No collection specified" if collection.nil?
          collection = JSON.parse(collection)

          kb = get_knowledge_base name
          matches = collection.keys.inject({}){|acc,type|
            entities = collection[type]
            entities.each do |entity|
              _matches = kb.parents(database, entity)
              type = _matches.target_type
              next unless _matches and _matches.any?
              if acc[type]
                acc[type].concat(_matches)
              else
                acc[type] = _matches
              end
              acc
            end
            acc
          }
          case @format
          when :tsv
            content_type "text/tab-separated-values"
            matches = matches.sort_by{|k,list| list.length }.last.last
            halt 200, matches.tsv.to_s
          when :tsv_json
            content_type :json
            halt 200, {}.to_json if matches.empty?
            matches = matches.sort_by{|k,list| list.length }.last.last
            halt 200, matches.tsv.to_json
          when :html
            template_render('knowledge_base_partials/matches', {:matches => matches}, "Collection Parents: #{ [name, database] }")
          when :json
            content_type :json
            _matches = {}
            matches.each{|type,list|
              _matches[type] = list.target
            }
            halt 200, _matches.to_json
          else
            content_type :text
            matches = matches.sort_by{|k,list| list.length }.last.last
            halt 200, matches.target * "\n"
          end
        end

        post '/knowledge_base/:name/:database/collection_neighbours' do 
          name = consume_parameter :name
          database = consume_parameter :database
          collection = consume_parameter :collection 
          raise ParameterException, "No collection specified" if collection.nil?
          collection = JSON.parse(collection)

          kb = get_knowledge_base name
          matches = collection.keys.inject({}){|acc,type|
            entities = collection[type]
            entities.each do |entity|
              _matches_h = kb.neighbours(database, entity)
              _matches_h.each do |key, _matches|
                if _matches  and _matches.any?
                  target_type = _matches.target_entity_type

                  if acc[target_type].nil?
                    acc[target_type] = _matches
                  else
                    acc[target_type].concat _matches
                  end
                else
                  acc
                end
              end
            end
            acc
          }

          @format ||= :json
          case @format
          when :tsv
            content_type "text/tab-separated-values"
            matches = matches.sort_by{|k,list| list.length }.last.last
            halt 200, matches.tsv.to_s
          when :html
            template_render('knowledge_base_partials/matches', {:matches => matches}, "Collection Parents: #{ [name, database] }")
          when :json
            content_type :json
            _matches = {}
            matches.each{|type,list|
              _matches[type] = list.target.uniq.sort
            }
            halt 200, _matches.to_json
          else
            content_type :text
            matches = matches.sort_by{|k,list| list.length }.last.last
            halt 200, matches.target * "\n"
          end
        end

        #{{{ Info

        get '/knowledge_base/:name/:database/info' do 
          name = consume_parameter :name
          database = consume_parameter :database

          kb = get_knowledge_base name

          source = kb.source(database)
          target = kb.target(database)
          source_type = kb.source_type(database)
          target_type = kb.target_type(database)
          fields = kb.fields(database)
          source_entity_options = kb.entity_options_for source_type, database
          target_entity_options = kb.entity_options_for target_type, database
          undirected = kb.undirected(database) == 'undirected'

          info = {
            :source => source,
            :target => target,
            :source_type => source_type,
            :target_type => target_type,
            :source_entity_options => source_entity_options,
            :target_entity_options => target_entity_options,
            :fields => fields,
            :undirected => undirected,
          }

          halt 200, info.to_json
        end

        get '/knowledge_base/info/:name/:database/:pair' do 
          name = consume_parameter :name
          database = consume_parameter :database
          pair = consume_parameter :pair

          kb = get_knowledge_base name
          index = kb.get_index(database)

          AssociationItem.setup(pair, kb, database, false)
          template_render('knowledge_base_partials/association', {:pair => pair, :kb => kb, :index => index, :database => database}, "Association: #{ pair } #{[name, database] * ":"}", :cache_type => :async)
        end

        #{{{ Children

        get '/knowledge_base/:name/:database/entity_children/:entity' do
          name = consume_parameter :name
          database = consume_parameter :database
          entity = consume_parameter :entity

          kb = get_knowledge_base name
          found = kb.identify database, entity
          raise ParameterException, "Entity #{entity} was not found" unless found

          list = kb.children(database, found).target_entity

          case @format
          when :json
            content_type "application/json"
            halt 200, prepare_entities_for_json(list).to_json
          when :html
          end
        end

        # List children
        post '/knowledge_base/:name/:database/entity_list_children/' do
          name = consume_parameter :name
          database = consume_parameter :database
          entities = consume_parameter :entities

          raise ParameterException, "No 'entities' provided" if entities.nil?

          entities = entities.split("|")

          kb = get_knowledge_base name

          children = {}
          entities.each do |entity|
            found = kb.identify database, entity
            next if found.nil?
            children[entity] = kb.children(database, found).target_entity
          end
          case @format
          when :json
            content_type "application/json"
            halt 200, prepare_entities_for_json(children).to_json
          when :html
          end
        end

        # Collection children
        post '/knowledge_base/:name/:database/entity_collection_children' do
          name = consume_parameter :name
          database = consume_parameter :database
          entities = consume_parameter :entities

          raise ParameterException, "No 'entities' provided" if entities.nil?

          entities = JSON.parse(entities)

          kb = get_knowledge_base name

          entities.each do |type,list|
            list.each do |entity|
              found = kb.identify database, entity
              next if found.nil?
              targets = kb.children(database, found).target_entity
              next if targets.nil? or targets.empty?
              target_type = kb.target database
              children[target_type] ||= []
              children[target_type].concat targets
            end
          end

          case @format
          when :json
            content_type "application/json"
            halt 200, prepare_entities_for_json(children).to_json
          when :html
          end
        end

        #{{{ Neighbours

        get '/knowledge_base/:name/:database/entity_neighbours/:entity' do
          name = consume_parameter :name
          database = consume_parameter :database
          entity = consume_parameter :entity

          kb = get_knowledge_base name
          found = kb.identify database, entity
          raise ParameterException, "Entity #{entity} was not found" unless found

          list = kb.neighbours(database, found).values.select{|list| list and list.any?}.first
          list = list.target_entity if list.respond_to? :target_entity
          list ||= []

          case @format
          when :json
            content_type "application/json"
            halt 200, prepare_entities_for_json(list).to_json
          when :html
          end
        end

        post '/knowledge_base/:name/:database/entity_list_neighbours/' do
          name = consume_parameter :name
          database = consume_parameter :database
          entities = consume_parameter :entities

          raise ParameterException, "No 'entities' provided" if entities.nil?

          entities = entities.split("|")

          kb = get_knowledge_base name

          children = {}
          entities.each do |entity|
            found = kb.identify database, entity
            next if found.nil?
            matches = kb.neighbours(database, found).values.select{|list| list and list.any?}.first
            next if matches.nil? or matches.empty?
            children[entity] = matches.target_entity
          end
          case @format
          when :json
            content_type "application/json"
            halt 200, prepare_entities_for_json(children).to_json
          when :html
          end
        end

        post '/knowledge_base/:name/:database/entity_collection_neighbours' do
          name = consume_parameter :name
          database = consume_parameter :database
          entities = consume_parameter :entities

          raise ParameterException, "No 'entities' provided" if entities.nil?

          entities = JSON.parse(entities)

          kb = get_knowledge_base name

          neighbours = {}
          entities.each do |type,list|
            list.each do |entity|

              found = kb.identify_source database, entity
              if found.nil?
                reverse = true
                found = kb.identify_target database, entity
              else
                reverse = false
              end
              next if found.nil?

              matches = kb.neighbours(database, found)[reverse ? :parents : :children]
              next if matches.nil? or matches.empty?
              targets = matches.target

              entity_type = reverse ? kb.source_type(database) : kb.target_type(database)
              neighbours[entity_type] ||= []
              neighbours[entity_type].concat targets
            end
          end

          neighbours.each{|type, list| list.uniq!}

          case @format
          when :json
            content_type "application/json"
            halt 200, prepare_entities_for_json(neighbours).to_json
          when :html
          end
        end

        get '/kb/:name/:database/children/:entity' do
          name = consume_parameter :name
          database = consume_parameter :database
          entity = consume_parameter :entity

          kb = get_knowledge_base name
          found = kb.identify database, entity
          raise ParameterException, "Entity #{entity} was not found" unless found

          list = kb.children(database, found).target_entity

          content_type "application/json"
          halt 200, serialize_entities(list).to_json
        end

        get '/kb/:name/:database/parents/:entity' do
          name = consume_parameter :name
          database = consume_parameter :database
          entity = consume_parameter :entity

          kb = get_knowledge_base name
          found = kb.identify database, entity
          raise ParameterException, "Entity #{entity} was not found" unless found

          list = kb.parents(database, found).target_entity

          content_type "application/json"
          halt 200, serialize_entities(list).to_json
        end

      end
    end
  end
end
