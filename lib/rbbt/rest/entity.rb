require 'rbbt'
require 'rbbt/workflow'
require 'sinatra/base'
require 'json'

require 'rbbt/rest/entity/locate'
require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/misc'

require 'rbbt/rest/entity/render'

class EntityREST < Sinatra::Base
  helpers RbbtRESTHelpers
  helpers EntityRESTHelpers

  before do
    process_common_parameters
  end

  get '/entity/:entity_type/:entity' do
    entity_type = consume_parameter :entity_type
    entity = consume_parameter :entity

    entity = setup_entity(entity_type, entity, params)

    entity_render(entity)
  end

  get '/entity_action/:entity_type/:action/:entity' do
    entity_type = consume_parameter :entity_type
    entity = consume_parameter :entity
    action = consume_parameter :action

    entity = setup_entity(entity_type, entity, params)

    entity_action_render(entity, action, params)
  end

  get '/entity_list/:entity_type/:list_name' do
    entity_type = consume_parameter :entity_type
    list_name = consume_parameter :list_name

    list = Entity::REST.load_list(entity_type, list_name)

    entity_list_render(list)
  end

  get '/entity_list_action/:entity_type/:action/:list_name' do
    entity_type = consume_parameter :entity_type
    list_name = consume_parameter :list_name
    action = consume_parameter :action

    list = Entity::REST.load_list(entity_type, list_name)

    entity_list_action_render(list, action)
  end






end
 
