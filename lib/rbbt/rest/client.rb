require 'rest_client'
require 'json'
require 'rbbt/workflow'
require 'rbbt/workflow/step'
require 'rbbt/util/misc'

require 'rbbt/rest/client/get'
require 'rbbt/rest/client/adaptor'
require 'rbbt/rest/client/step'

class WorkflowRESTClient 
  include Workflow

  attr_accessor :url, :name, :exec_exports, :asynchronous_exports, :synchronous_exports

  def initialize(url, name)
    Log.debug{ "Loading remote workflow #{ name }: #{ url }" }
    @url, @name = url, name
    init_remote_tasks
  end
  
  def to_s
    name
  end

  def job(task, name, inputs)
    task_info = task_info(task)
    fixed_inputs = {}
    inputs.each do |k,v| 
      fixed_inputs[k] = case v
                        when TSV
                          v.to_s
                        else
                          v
                        end
    end

    RemoteStep.new(url, task, name, fixed_inputs, task_info[:result_type], task_info[:result_description], @exec_exports.include?(task))
  end

  def load_id(id)
    task, name = id.split("/")
    step = RemoteStep.new url, task, nil
    step.name = name
    step.result_type = task_info(task)[:result_type]
    step.result_description = task_info(task)[:result_description]
    step
  end
end
