require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/resources'
require 'rbbt/rest/common/users'
require 'ruby-prof'

require 'sinatra/base'
require 'json'

module Sinatra
  module RbbtRESTMain
    def add_sass_load_path(path)
      Sass::Engine::DEFAULT_OPTIONS[:load_paths].unshift path
    end

    def self.registered(base)
      base.module_eval do
        helpers RbbtRESTHelpers
        register Sinatra::RbbtAuth

        set :cache_dir, Rbbt.var.sinatra.cache.find unless settings.respond_to? :cache_dir and settings.cache_dir != nil
        set :file_dir, Rbbt.var.sinatra.files.find unless settings.respond_to? :file_dir and settings.file_dir != nil

        set :public_folder, Rbbt.share.views.public.find 

        attr_accessor :ajax, :layout, :format, :size, :update, :cache_type, :_, :profile

        set :haml, { :ugly => true }
        if production?
          set :haml, { :ugly => true }
          set :clean_trace, true
          set :static_cache_control , [:public, {:max_age => 360000}]
        end

        before do
          Log.debug("IP #{request.ip}: " << request.path_info << ". Params: " << params.inspect)
          process_common_parameters

          if profile
            RubyProf.start 
          end
        end

        after do

          if profile
            result = RubyProf.stop
            printer = RubyProf::MultiPrinter.new(result)
            dir = TmpFile.tmp_file
            FileUtils.mkdir_p dir unless File.exists? dir
            printer.print(:path => dir, :profile => 'profile')
            Log.info("Profile saved at #{ dir }")
          end

          request
        end

        add_sass_load_path Rbbt.views.compass.find

        get '/files/:filename' do
          cache_control :public, :max_age => 360000 if production?
          file = File.join(settings.file_dir, params[:filename])
          send_file file
        end

        get %r{/js/(.*)(.js)?} do
          name = consume_parameter(:captures).first

          script_file = locate_javascript(name)

          cache_control :public, :max_age => 360000 if production?
          send_file script_file
        end

        get '/stylesheets/:name.css' do
          name = consume_parameter :name

          file = locate_sass(name)

          content_type 'text/css', :charset => 'utf-8'
          cache_control :public, :max_age => 360000 if production?

          @cache_type = production? ? :synchronous : :none
          cache('css', :_template_file => file, :_send_file => true) do
            Log.debug("Rendering stylesheets")
            renderer = Sass::Engine.new(Open.read(file), :filename => file, 
                                        :style => production? ? :compressed : nil, 
                                        :debug_info => production? ? false : false)
            renderer.render
          end
        end

        get '/' do
          template_render('main', params)
        end

      end
    end
  end
end

