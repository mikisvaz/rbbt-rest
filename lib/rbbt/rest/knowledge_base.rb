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

        #{{{ Info
        
        get '/knowledge_base/info/:name/:database/:pair' do 
          name = consume_parameter :name
          database = consume_parameter :database
          pair = consume_parameter :pair

          kb = get_knowledge_base name
          index = kb.get_index(database)

          AssociationItem.setup(pair, kb, database, false)
          template_render('knowledge_base_partials/association', {:pair => pair, :kb => kb, :index => index, :database => database}, "Association: #{ pair }")
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
      end
    end
  end
end
