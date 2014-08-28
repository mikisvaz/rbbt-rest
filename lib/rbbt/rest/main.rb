require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/resources'
require 'rbbt/rest/common/users'
require 'ruby-prof'

require 'sinatra/base'
require 'sinatra/cross_origin'
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

        add_sass_load_path Rbbt.share.views.compass.find(:lib)

        #set :cache_dir, Rbbt.var.sinatra.cache.find unless settings.respond_to? :cache_dir and settings.cache_dir != nil
        #set :file_dir, Rbbt.var.sinatra.files.find unless settings.respond_to? :file_dir and settings.file_dir != nil
        #set :permalink_dir, Rbbt.var.sinatra.permalink.find unless settings.respond_to? :permalink_dir and settings.permalink_dir != nil

        set :public_folder, Rbbt.share.views.public.find 

        set :environment, ENV["RACK_ENV"].to_sym if ENV["RACK_ENV"]

        attr_accessor :ajax, :layout, :format, :size, :update, :cache_type, :_, :profile

        if production?
          set :haml, { :ugly => true }
          set :clean_trace, true
          set :static_cache_control , [:public, {:max_age => 360000}]
        end

        enable :cross_origin
        set :allow_origin, :any
        set :allow_methods, [:get, :post, :options]
        set :allow_credentials, true
        set :max_age, "1728000"
        set :allow_headers, ['URI']

        before do
          method = request.request_method
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

        get '/stylesheets/:name.css' do
          name = consume_parameter :name

          file = locate_sass(name)

          content_type 'text/css', :charset => 'utf-8'
          cache_control :public, :max_age => 360000 if production?

          @cache_type = production? ? :synchronous : :none
          cache('css', :_template_file => file, :_send_file => true) do
            Log.debug{ "Rendering stylesheets" }
            renderer = Sass::Engine.new(Open.read(file), :filename => file, 
                                        :style => production? ? :compressed : nil, 
                                        :debug_info => development? ? true : false)
            renderer.render
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

        error RbbtRESTHelpers::TemplateMissing do |e|
          halt 404, e.message
        end

        error Exception do |e|
          raise e unless @format == :html
          halt 500, [e.class.to_s, e.message] * " => "
        end
        
        require 'rbbt/rest/monitor'
        register Sinatra::RbbtRESTMonitor
      end
    end

  end


  #require 'rack/stream'
  #use Rack::Stream
end

