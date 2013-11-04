require 'rbbt'
require 'sinatra/base'

module Sinatra
  module RbbtRESTFileServer
    
    def self.registered(base)
      base.module_eval do

        get '/resource/:resource/get_directory' do
          directory, resource, create = params.values_at :directory, :resource, :create

          create = true unless create.nil? or create.empty? or %w(no false).include? create.downcase

          raise "The Rbbt resource may not be used since it has access to seccurity sensible files" if resource == "Rbbt"

          resource = Kernel.const_get(resource)

          path = resource.root[directory]

          raise "For security reasons the file path must not leave the resource root directory" unless Misc.path_relative_to(resource.root, path)

          Log.debug("Serving resource: #{[resource, directory, path, path.find] * " | "}")

          raise "Directory does not exist" unless path.exists? or create
          raise "Directory does not exist and can not create it" unless path.exists? or path.produce.exists?

          stream(:binmode => true) do |out|

            io = Misc.in_dir path.find do
              CMD.cmd("tar cfz - '.'", :pipe => true)
            end

            while not io.closed? and block = io.read(4096) 
              out << block
            end
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

          raise "File does not exist" unless path.exists? or create
          raise "File does not exist and can not create it" unless path.exists? or path.produce.exists?

          send_file path.find, :filename => path
        end

      end
    end
  end
end
