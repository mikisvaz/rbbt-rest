require 'rbbt/monitor'

module Sinatra
  module RbbtRESTMonitor
    def self.registered(base)
      base.module_eval do

        get '/locks' do
          lock_info = Rbbt.lock_info
          case @format
          when :json
            halt 200, lock_info.to_json
          else
            template_render('monitor/locks', {:lock_info => lock_info}, nil, :cache_type => :none)
          end
        end

        get '/jobs/:workflow' do
          workflow = params[:workflow]
          job_info = Rbbt.job_info(workflow)
          case @format
          when :json
            halt 200, job_info.to_json
          else
            template_render('monitor/jobs', {:workflow => workflow, :job_info => job_info}, nil, :cache_type => :none)
          end
        end
      end
    end
  end
end
