require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/misc'

require 'rbbt/rest/workflow/render'
require 'rbbt/rest/workflow/forms'
require 'rbbt/rest/workflow/jobs'

require 'sinatra/base'
require 'json'

class RbbtREST < Sinatra::Base
  before do
    @ajax = request.xhr?

    @layout = consume_parameter(:_layout)
    @layout = false if @layout.nil? and     @ajax
    @layout = true  if @layout.nil? and not @ajax

    @format = consume_parameter(:_format)
    @format = :html if @format.nil?
    @format = @format.to_sym if String === @format


    @size = consume_parameter(:_size)
    @size = @size.to_sym if String === @size

    @update = consume_parameter(:_update)
    @update = @update.to_sym if String === @update

    @cache_type = consume_parameter(:_cache_type)
    @cache_type = @cache_type.to_sym if String === @cache_type

    @_ = consume_parameter(:_)
  end
end

