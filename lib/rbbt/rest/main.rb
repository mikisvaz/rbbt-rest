require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/misc'
require 'rbbt/rest/common/resources'

require 'sinatra/base'
require 'json'
require 'yui/compressor'

class RbbtREST < Sinatra::Base
  helpers RbbtRESTHelpers

  set :cache_dir, Rbbt.var.cache.sinatra.find unless settings.respond_to? :cache_dir and settings.cache_dir != nil
  set :file_dir, Rbbt.var.cache.sinatra.find unless settings.respond_to? :file_dir and settings.file_dir != nil
  set :public_folder, 'share/views/public' 

  attr_accessor :ajax, :layout, :format, :size, :update, :cache_type, :_

  before do
    process_common_parameters
  end

  RbbtRESTHelpers.add_sass_load_path Rbbt.views.compass.find



  get '/files/:filename' do
    cache_control :public, :max_age => 36000 if production?
    file = File.join(settings.file_dir, params[:filename])
    send_file file
  end

  get '/js/:name.js' do
    name = consume_parameter :name

    script_file = RbbtRESTHelpers.locate_javascript(name)

    send_file script_file
  end

  get '/stylesheets/:name.css' do
    name = consume_parameter :name

    file = locate_sass(name)

    content_type 'text/css', :charset => 'utf-8'
    cache_control :public, :max_age => 36000

    cache('css', :_template_file => file) do
      renderer = Sass::Engine.new(Open.read(file), :filename => file)
      css_text = renderer.render
      YUI::CssCompressor.new.compress(css_text)
    end
  end

end

