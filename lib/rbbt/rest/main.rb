require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/resources'
require 'rbbt/rest/common/users'
require 'rbbt/rest/common/misc'
require 'ruby-prof'

require 'sinatra/base'
require 'sinatra/cross_origin'
require "sinatra/multi_route"
require "sinatra/cookies"
require 'sinatra/streaming'
require 'json'

require 'nakayoshi_fork'

module Sinatra
  module RbbtRESTMain

    def self.add_resource_path(path, priority_templates = false)
      Log.medium "Adding resource path: #{Misc.fingerprint path}"
      KnowledgeBaseRESTHelpers.association_resources.unshift path

      if priority_templates
        EntityRESTHelpers.entity_resources.unshift path if defined? EntityRESTHelpers
        RbbtRESTHelpers.template_resources.unshift path 
      else
        EntityRESTHelpers.entity_resources.push path if defined? EntityRESTHelpers
        RbbtRESTHelpers.template_resources.push path 
      end

      RbbtRESTHelpers.add_sass_load_path path.compass if path.compass.exists?

      RbbtRESTHelpers.javascript_resources.unshift path.public.js if path.public.js.exists? 
      RbbtRESTHelpers.css_resources.unshift path.public.css if path.public.css.exists? 
      RbbtRESTHelpers.javascript_resources.unshift path.public.plugins if path.public.plugins.exists? 
      RbbtRESTHelpers.css_resources.unshift path.public.plugins if path.public.plugins.exists? 
      RbbtRESTHelpers.sass_resources.unshift path.compass if path.compass.exists?
    end

    def add_sass_load_path(path)
      path = path.find if Path === path
      Sass::Engine::DEFAULT_OPTIONS[:load_paths].unshift path if File.exists? path
    end

    def self.registered(base)
      base.module_eval do
        register Sinatra::MultiRoute

        helpers RbbtRESTHelpers
        register Sinatra::RbbtAuth
        helpers Sinatra::Cookies
        helpers Sinatra::Streaming

        add_sass_load_path Rbbt.share.views.compass.find(:lib)

        set :public_folder, Rbbt.share.views.public.find 

        set :environment, ENV["RACK_ENV"].to_sym if ENV["RACK_ENV"]

        attr_accessor :ajax, :layout, :format, :size, :update, :cache_type, :_, :profile


        enable :cross_origin
        set :allow_origin, :any
        set :allow_methods, [:get, :post, :options]
        set :allow_credentials, true
        set :max_age, "1728000"
        set :allow_headers, ['URI']

        if production?
          set :clean_trace, true
          set :static_cache_control , [:public, {:max_age => 360_000}]
        else
          set :static_cache_control , [:public, {:max_age => 0}]
        end

        before do
          method = request.request_method
          request.script_name = request.env["HTTP_SCRIPT_NAME"]
          method_color = case method
                         when "GET"
                           :cyan
                         when "POST"
                           :yellow
                         end

          Log.medium{ "#{Log.color method_color, method} #{Log.color(:blue, request.ip)}: " << request.path_info.gsub('/', Log.color(:blue, "/")) << ". Params: " << Log.color(:blue, Misc.fingerprint(params))}
          process_common_parameters

          headers 'Access-Control-Allow-Origin' => '*'

          if profile
            RubyProf.start 
          end
        end

        after do
          method = request.request_method

          method_color = case method
                         when "GET"
                           :cyan
                         when "POST"
                           :green
                         end

          status = response.status.to_s
          case status.to_i
          when 200
            color = :green
          when 202
            color = :yellow
          when 404,500
            color = :red
          else
            color = nil
          end
          Log.medium{ "#{Log.color method_color, method} #{Log.color :blue, request.ip}: " << request.path_info.gsub('/', Log.color(:blue, "/")) << ". Status: " << Log.color(color, status) }

          if profile
            result = RubyProf.stop
            printer = RubyProf::MultiPrinter.new(result)
            dir = TmpFile.tmp_file
            dir = settings.file_dir
            FileUtils.mkdir_p dir unless File.exists? dir
            printer.print(:path => dir, :profile => 'profile')
            Log.info{ "Profile saved at #{ dir }: #{request.env["REQUEST_URI"]}" }
          end

          response.header["URI"] = request.env["REQUEST_URI"]
        end

        add_sass_load_path Rbbt.views.compass.find

        get '/robots.txt' do
          send_file locate_file('public/robots.txt')
        end

        get '/files/:filename' do
          cache_control :public, :max_age => 360000 if production?
          file = settings.file_dir[params[:filename]].find
          send_file file
        end

        get %r{/js-find/(.*)(.js)?} do
          name = consume_parameter(:captures).first

          script_file = locate_javascript(name)

          content_type 'text/javascript', :charset => 'utf-8' if script_file =~ /\.js$/
          cache_control :public, :max_age => 360000 if production?
          send_file script_file
        end

        get %r{/css-find/(.*)(.css)?} do
          name = consume_parameter(:captures).first

          script_file = locate_css(name)

          content_type 'text/css', :charset => 'utf-8' if script_file =~ /\.js$/
          cache_control :public, :max_age => 360000 if production?
          send_file script_file
        end


        get '/stylesheets/*' do
          name = consume_parameter :splat

          file = locate_sass((name*"/").sub(/.css$/,''))

          content_type 'text/css', :charset => 'utf-8'
          cache_control :public, :max_age => 360000 if production?

          cache("css: #{File.basename(file)}", :_template_file => file, :_send_file => true, :cache_type => production? ? :synchronous : :none) do
            Log.debug{ "Rendering stylesheet: #{ file }" }
            render_sass(file)
          end
        end

        get '/' do
          template_render('main', params, 'main', :cache_type => :asynchronous)
        end

        get '/main/*' do |file|
          template = File.join 'main', file
          name = template.gsub(/\//,' - ')
          template_render(template, params, name, :cache_type => :asynchronous)
        end

        get '/help/?:section?' do
          if params[:section]
            section = params[:section]
            template_render('help/' << section, params, section, :cache_type => :asynchronous)
          else
            template_render('help', params, 'help', :cache_type => :asynchronous)
          end
        end

        get '/permalink/:id' do
          content_type "text/html"
          layout_file = locate_template('layout')
          Haml::Engine.new(Open.read(layout_file), :filename => layout_file).render(self) do
            settings.permalink_dir[params[:id]].read
          end
        end

        error TemplateMissing do |e|
          halt 404, e.message
        end

        error RemoteServerError do |e|
          raise e unless @format == :html

          content_type "text"
          halt 503, [e.class.to_s, e.message] * " => " << "\n\n" << (e.backtrace * "\n").gsub('`',"'")
        end

        error Exception do |e|
          raise e unless @format == :html

          content_type "text"
          halt 500, [e.class.to_s, e.message] * " => " << "\n\n" << (e.backtrace * "\n").gsub('`',"'")
        end

        get '/fonts/*' do
          filename = params[:splat].first
          file = File.join(settings.public_folder, 'fonts', filename)
          send_file file
        end

        get '/opt/*' do
          filename = params[:splat].first
          file = locate_file(Path.setup('public/opt')[filename])
          send_file file.find
        end

        get '/images/*' do
          filename = params[:splat].first
          file = locate_file(Path.setup('public/images')[filename])
          send_file file.find
        end

        get '/file/*' do
          filename = params[:splat].first
          file = locate_file(Path.setup('public')[filename])
          send_file file.find
        end

        require 'rbbt/rest/monitor'

        register Sinatra::RbbtRESTMonitor
      end
    end

  end
end

