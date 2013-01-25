require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/misc'

require 'sinatra/base'
require 'json'

class RbbtREST < Sinatra::Base
  helpers RbbtRESTHelpers

  set :cache_dir, Rbbt.var.cache.sinatra.find unless settings.respond_to? :cache_dir and settings.cache_dir != nil

  attr_accessor :ajax, :layout, :format, :size, :update, :cache_type, :_

  before do
    process_common_parameters
  end
end

