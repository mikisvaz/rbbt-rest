require 'rbbt'
require 'sinatra/base'
require 'sinatra/streaming'
                                       

module Sinatra
  module RbbtRESTFileServer
    
    def self.registered(base)
      base.module_eval do
        helpers Sinatra::Streaming

        get '/resource/:resource/get_directory' do
          directory, resource, create = params.values_at :directory, :resource, :create

          create = true unless create.nil? or create.empty? or %w(no false).include? create.downcase

          raise "The Rbbt resource may not be used since it has access to seccurity sensible files" if resource == "Rbbt"

          resource = Kernel.const_get(resource)

          directory = $1 if resource.subdir and directory =~ /^#{resource.subdir}\/?(.*)/

          path = resource.root[directory]

          raise "For security reasons the file path must not leave the resource root directory" unless Misc.path_relative_to(resource.root, path)

          Log.debug("Serving resource: #{[resource, directory, path, path.find] * " | "}")

          raise "Directory does not exist" unless path.exists? or create
          raise "Directory does not exist and can not create it" unless path.exists? or path.produce.exists?

          headers['Content-Encoding'] = 'gzip'
          stream do |out|
            tar = Misc.tarize(path.find)
            begin
              while chunk = tar.read(8192)
                break if out.closed?
                out << chunk
              end
            ensure
              tar.force_close
            end
            out.flush
          end
        end

        get '/resource/:resource/get_file' do
          file, resource, create = params.values_at :file, :resource, :create

          create = true unless create.nil? or create.empty? or %w(no false).include? create.downcase

          raise "The Rbbt resource may not be used since it has access to seccurity sensible files" if resource == "Rbbt"

          resource = Kernel.const_get(resource)

          file = $1 if resource.subdir and file =~ /^#{resource.subdir}\/?(.*)/

          path = resource.root[file]

          raise "For security reasons the file path must not leave the resource root directory" unless Misc.path_relative_to(resource.root, path)

          Log.debug("Resource: #{[resource, file, path, path.find] * " | "}")

          raise "File does not exist and can not create it" unless path.exists?

          directory_url = File.join("/resource", resource.to_s , 'get_directory') << '?' << "create=#{create}" << '&' << "directory=#{file}"
          redirect to(directory_url) if path.directory?

          send_file path.find, :filename => path
        end

      end
    end
  end
end
