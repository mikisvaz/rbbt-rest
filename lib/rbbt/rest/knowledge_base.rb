require 'rbbt'
require 'rbbt/workflow'
require 'sinatra/base'

require 'rbbt/knowledge_base'
require 'rbbt/rest/knowledge_base/helpers'

module Sinatra
  module RbbtRESTKnowledgeBase
    def self.registered(base)
      base.module_eval do
        helpers KnowledgeBaseRESTHelpers

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

        # Neighbours

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

          kb = get_kb name

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

          kb = get_kb name

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

        #{{{ OLD

        get '/knowledge_base/entity/:name/:database/:entity' do
          name = consume_parameter :name

          database = consume_parameter :database
          entity = consume_parameter :entity

          kb = get_kb name
          found = kb.identify database, entity
          raise ParameterException, "Entity #{entity} was not found" unless found

          list = kb.neighbours(database, found).values.select{|l| l.any?}.first.target_entity

          case @format
          when :json
            content_type "application/json"
            halt 200, list_json(list || [])
          when :html
            template_render('entity_partials/entity_list', :list => list)
          end
        end

        get '/knowledge_base/entities/:name/:database' do
          name = consume_parameter :name
          database = consume_parameter :database
          entities = consume_parameter(:entities).split("|")

          kb = get_kb name

          entity_neighbours = {}
          entities.each do |entity|
            found = kb.identify database, entity
            next unless found
            list = kb.neighbours(database, found).values.select{|l| l.any?}.first.target_entity
            entity_neighbours[entity] = list
          end

          case @format
          when :json
            content_type "application/json"
            hash = {}
            entity_neighbours.each do |entity, list|
              hash[entity] = list_hash(list)
            end
            halt 200, hash.to_json
          when :html
            template_render('entity_partials/entity_list', :list => list)
          end
        end

        get '/knowledge_base/entity/:name/:entity' do
          name = consume_parameter :name
          database = consume_parameter :database
          entity = consume_parameter :entity

          kb = get_kb name

          lists = {}
          kb.all_databases.collect do |database|
            found = kb.identify database, entity
            next unless found
            matches = kb.neighbours(database, found).values.select{|l| l.any?}.first
            next if matches.nil?
            lists[database] = matches.target_entity
          end

          case @format
          when :json
            content_type "application/json"
            halt 200, lists.each{|database,entities| lists[database] = list_hash(entities || []) }.to_json
          when :html
            template_render('knowledge_base_partials/knowledge_base_matches', :matches => lists, :knowledge_base => kb)
          end
        end

        #{{{ Hash 
        
        post '/knowledge_base/associations' do
          knowledge_base = consume_parameter :knowledge_base
          knowledge_base = get_knowledge_base(knowledge_base)

          namespace = consume_parameter :namespace

          databases = consume_parameter(:databases) || consume_parameter(:database)
          databases = databases.nil? ? knowledge_base.all_databases : databases.split("|")

          entities = consume_parameter :entities
          entities = JSON.parse(entities)

          subset = {}
          databases.each do |database|
            subset[database] = knowledge_base.subset(database, entities)
          end

          case @format
          when :json
            content_type "application/json"
            halt 200, subset.each{|database,entities| subset[database] = list_hash(entities || []) }.to_json
          when :html
            template_render('entity_partials/associations', :matches => matches, :entities => entities)
          end
        end

        post '/knowledge_base/neighbours' do
          knowledge_base = consume_parameter :knowledge_base
          knowledge_base = get_knowledge_base(knowledge_base)

          namespace = consume_parameter :namespace

          database = consume_parameter(:database)

          entities = consume_parameter :entities
          entities = JSON.parse(entities)

          all_neighbours = {}
          entities.collect{|source_type,list|
            list.each do |entity|

              target_type = knowledge_base.target_type(database)
              source_type = knowledge_base.source_type(database)

              neighbours = knowledge_base.neighbours(database, entity)

              children = neighbours[:children] 
              if children.any?
                all_neighbours[target_type] ||= []
                all_neighbours[target_type].concat children.target
              end

              parents = neighbours[:parents]
              if parents and parents.any?
                all_neighbours[source_type] ||= []
                all_neighbours[source_type].concat parents.target
              end
            end
          }

          case @format
          when :json
            content_type "application/json"
            halt 200, [].to_json if all_neighbours.empty?
            entities = {}
            all_neighbours.each do |type,list|
              entities[type] = list
            end

            halt 200, all_neighbours.to_json
          when :html
            template_render('entity_partials/neighbours', :matches => matches, :neighbours => all_neighbours)
          end
        end
      end
    end
  end
end
