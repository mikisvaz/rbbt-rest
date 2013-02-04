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
require 'rbbt/rest/entity/rest'
require 'rbbt/rest/entity/favourites'
require 'rbbt/rest/entity/finder'

require 'rbbt/rest/entity/entity_card'
require 'rbbt/rest/entity/list_container'
require 'rbbt/rest/entity/action_controller'


module Sinatra
  module RbbtRESTEntity
    def self.registered(base)
      base.module_eval do
        helpers EntityRESTHelpers

        set :favourites_dir, Rbbt.var.find.sinatra.favourites
        set :favourite_lists_dir, Rbbt.var.find.sinatra.favourite_lists
        set :finder, nil

        get /^\/entity.*/ do
          @cache_type = :asynchronous if @cache_type.nil?
          pass
        end

        get '/entity/:entity_type/:entity' do
          entity_type = consume_parameter :entity_type
          entity = consume_parameter :entity

          entity_type = Entity::REST.restore_element(entity_type)

          entity = setup_entity(entity_type, entity, @clean_params)

          @entity = entity

          entity_render(entity)
        end

        get '/entity_action/:entity_type/:action/:entity' do
          entity_type = consume_parameter :entity_type
          entity = consume_parameter :entity
          action = consume_parameter :action

          entity_type = Entity::REST.restore_element(entity_type)

          entity = setup_entity(entity_type, entity, @clean_params)

          entity_action_render(entity, action, @clean_params)
        end

        get '/entity_list/:entity_type/:list_id' do
          entity_type = consume_parameter :entity_type
          list_id = consume_parameter :list_id

          entity_type = Entity::REST.restore_element(entity_type)
          list_id = Entity::REST.restore_element(list_id)

          list = Entity::List.load_list(entity_type.split(":").first, list_id)

          entity_list_render(list, list_id)
        end

        get '/entity_list_action/:entity_type/:action/:list_id' do
          entity_type = consume_parameter :entity_type
          list_id = consume_parameter :list_id
          action = consume_parameter :action

          entity_type = Entity::REST.restore_element(entity_type)
          list_id = Entity::REST.restore_element(list_id)

          list = Entity::List.load_list(entity_type.split(":").first, list_id)

          entity_list_action_render(list, action, list_id, @clean_params)
        end

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
              info = entity.info
              info.delete :annotation_types
              type_favs[entity] = {:info => info, :link => entity.link} 
            end
            favs[type] = type_favs
          }

          favs.to_json
        end
 
        #{{{ Favourite entity lists

        post '/add_favourite_entity_list/:entity_type/:list' do
          entity_type = consume_parameter :entity_type
          list = consume_parameter :list

          entity_type = Entity::REST.restore_element(entity_type).split(":").first

          add_favourite_entity_list(entity_type, list)

          halt 200
        end

        post '/remove_favourite_entity_list/:entity_type/:list' do
          entity_type = consume_parameter :entity_type
          list = consume_parameter :list

          entity_type = Entity::REST.restore_element(entity_type).split(":").first

          remove_favourite_entity_list(entity_type, list)

          halt 200
        end


        get '/favourite_entity_lists' do
          content_type "application/json"

          favs = favourite_entity_lists

          favs.to_json
        end

        #{{{ Finder


        get '/find' do
          halt 200 if params[:term].nil? or params[:term].empty?

          term = params[:term]
          sorted_results = finder_find(term)

          raise "No finder defined" unless settings.respond_to? :finder and not settings.finder.nil?
          if request.xhr?
            content_type "application/json" 
            halt 200, sorted_results.to_json
          else
            i = sorted_results.first
            raise "Term not recognized: #{ term }" if i.nil?
            redirect to(Entity::REST.entity_url(i[:code], i[:format], i[:namespace]))
          end
        end

        post '/find' do
          term = consume_parameter :term 
          if term =~ /(.*) \[(.*)\]$/
            term = $1
            namespace, format = $2.split(":")
            format, namespace = namespace, nil if format.nil?

            redirect to(Entity::REST.entity_url(term, format, :format => namespace))
          else
            sorted_results = finder_find(term)
            i = sorted_results.first
            halt 404, "Term not recognized: #{ term }" if i.nil?
            redirect to(Entity::REST.entity_url(i[:code], i[:format], :format => i[:namespace]))
          end
        end

      end
    end
  end
end

