require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/misc'
require 'rbbt/rest/common/resources'
require 'rbbt/rest/common/users'

require 'sinatra/base'
require 'json'
require 'yui/compressor'

module Sinatra
  module RbbtRESTMain
    def add_sass_load_path(path)
      Sass::Engine::DEFAULT_OPTIONS[:load_paths] << path
    end

    def self.registered(base)
      base.module_eval do
        helpers RbbtRESTHelpers
        register Sinatra::RbbtAuth

        set :cache_dir, Rbbt.var.sinatra.cache.find unless settings.respond_to? :cache_dir and settings.cache_dir != nil
        set :file_dir, Rbbt.var.sinatra.files.find unless settings.respond_to? :file_dir and settings.file_dir != nil

        set :public_folder, 'share/views/public' 

        attr_accessor :ajax, :layout, :format, :size, :update, :cache_type, :_

        before do
          process_common_parameters
        end

        add_sass_load_path Rbbt.views.compass.find

        get '/files/:filename' do
          cache_control :public, :max_age => 36000 if production?
          file = File.join(settings.file_dir, params[:filename])
          send_file file
        end

        get '/js/:name.js' do
          name = consume_parameter :name

          script_file = locate_javascript(name)

          cache_control :public, :max_age => 36000 if production?
          send_file script_file
        end

        get '/stylesheets/:name.css' do
          name = consume_parameter :name

          file = locate_sass(name)

          content_type 'text/css', :charset => 'utf-8'
          cache_control :public, :max_age => 36000 if production?

          @cache_type = production? ? :synchronous : :none
          cache('css', :_template_file => file, :_send_file => true) do
            Log.debug("Rendering stylesheets")
            renderer = Sass::Engine.new(Open.read(file), :filename => file)
            css_text = renderer.render
            YUI::CssCompressor.new.compress(css_text)
          end
        end

        get '/' do
          template_render('main')
        end

      end
    end
  end
end

