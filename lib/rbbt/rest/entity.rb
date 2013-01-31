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
require 'rbbt/rest/entity/favourites'


class EntityREST < Sinatra::Base
  helpers RbbtRESTHelpers
  helpers EntityRESTHelpers

  register Sinatra::RbbtAuth

  set :cache_dir, Rbbt.var.cache.find unless settings.respond_to? :cache_dir and settings.cache_dir != nil
  set :file_dir, Rbbt.var.cache.files.find unless settings.respond_to? :file_dir and settings.file_dir != nil

  attr_accessor :ajax, :layout, :format, :size, :update, :cache_type, :_

  before do
    process_common_parameters

    @cache_type = :asynchronous if @cache_type.nil?
  end

  get '/entity/:entity_type/:entity' do
    entity_type = consume_parameter :entity_type
    entity = consume_parameter :entity

    entity_type = CGI.unescape(entity_type)

    entity = setup_entity(entity_type, entity, @clean_params)

    @entity = entity

    entity_render(entity)
  end

  get '/entity_action/:entity_type/:action/:entity' do
    entity_type = consume_parameter :entity_type
    entity = consume_parameter :entity
    action = consume_parameter :action

    entity_type = CGI.unescape(entity_type)

    entity = setup_entity(entity_type, entity, @clean_params)

    entity_action_render(entity, action, @clean_params)
  end

  get '/entity_list/:entity_type/:list_id' do
    entity_type = consume_parameter :entity_type
    list_id = consume_parameter :list_id

    entity_type = CGI.unescape(entity_type)
    list_id = CGI.unescape(list_id)

    list = Entity::List.load_list(entity_type.split(":").first, list_id)

    entity_list_render(list, list_id)
  end

  get '/entity_list_action/:entity_type/:action/:list_id' do
    entity_type = consume_parameter :entity_type
    list_id = consume_parameter :list_id
    action = consume_parameter :action

    entity_type = CGI.unescape(entity_type)
    list_id = CGI.unescape(list_id)

    list = Entity::List.load_list(entity_type.split(":").first, list_id)

    entity_list_action_render(list, action, list_id, @clean_params)
  end

  post '/add_favourite/:entity_type/:entity' do
    entity_type = consume_parameter :entity_type
    entity = consume_parameter :entity

    entity_type = CGI.unescape(entity_type)

    entity = setup_entity(entity_type, entity, @clean_params)

    add_favourite(entity)

    halt 200
  end
end
