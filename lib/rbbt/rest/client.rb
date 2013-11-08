require 'rest_client'
require 'json'
require 'rbbt/workflow'
require 'rbbt/workflow/step'
require 'rbbt/util/misc'

class WorkflowRESTClient

  def self.fix_hash(hash, fix_values = false)
    fixed = {}
    hash.each do |key, value|
      fixed[key.to_sym] = case
                          when Hash === value 
                            fix_hash(value)  
                          when (fix_values and String === value)
                            value.to_sym
                          else
                            value
                          end
    end
    fixed
  end

  def self.get_raw(url, params = {})
    Log.debug("RestClient get_raw #{}: #{ url } - #{params.inspect}")
    params = params.merge({ :_format => 'raw' })
    RestClient.get(url, :params => params)
  end
 
  def self.post_jobname(url, params = {})
    Log.debug("RestClient post_jobname #{}: #{ url } - #{params.inspect}")
    params = params.merge({ :_format => 'jobname' })
    RestClient.post(url, params)
  end
  
  def self.get_json(url, params = {})
    Log.debug("RestClient get_json #{}: #{ url } - #{params.inspect}")
    params = params.merge({ :_format => 'json' })
    begin
      res = RestClient.get(url, :params => params)
    rescue => e
      raise JSON.parse(e.response)["message"]
    end
    begin
      JSON.parse(res)
    rescue
      res
    end
  end
  
  def self.post_json(url, params = {})
    if url =~ /_cache_type=:exec/
      JSON.parse(Open.open(url, :nocache => true))
    else
      params = params.merge({ :_format => 'json' })
      res = RestClient.post(url, params)
      begin
        JSON.parse(res)
      rescue
        res
      end
    end
  end

  class RemoteStep < Step

    attr_accessor :url, :base_url, :task, :name, :inputs, :result_type, :result_description

    def name
      (Array === @url ? @url.first : @url).split("/").last
    end

    def task_name
      (Array === @url ? @url.first : @url).split("/")[-2]
    end

    def info
      info = WorkflowRESTClient.get_json(File.join(url, 'info'))
      info = WorkflowRESTClient.fix_hash(info)
      info[:status] = info[:status].to_sym if String === info[:status]
      info
    end
    
    def done?
      status.to_s == 'done'
    end

    def fork
      @name = WorkflowRESTClient.post_jobname(File.join(base_url, task.to_s), inputs.merge(:jobname => @name, :_cache_type => :asynchronous))
      @url = File.join(base_url, task.to_s, @name)
      self
    end

    def initialize(base_url, task = nil, name = nil, inputs = nil, result_type = nil, result_description = nil, exec = false)
      if task.nil?
        @url = base_url
      else
        @base_url, @task, @name, @inputs, @result_type, @result_description = base_url, task, name, inputs, result_type, result_description
        if exec
          @url = [File.join(base_url, task.to_s), inputs]
        else
          self.fork 
        end
      end
    end

    def _exec(noload = false)
      if Array === @url
        url, params = @url
      else
        url, params = @url, {:_cache_type => :synchronous}
      end

      params[:jobname] = @name if @name

      if noload and %w(boolean string tsv).include? result_type
        WorkflowRESTClient.get_raw(url, params) 
      else
        case result_type
        when :string
          WorkflowRESTClient.get_raw(url, params) 
        when :boolean
          WorkflowRESTClient.get_raw(url, params) == "true"
        when :tsv
          TSV.open(StringIO.new(WorkflowRESTClient.get_raw(url, params)))
        when :annotations
          Annotated.load_tsv(TSV.open(StringIO.new(WorkflowRESTClient.get_raw(url, params))))
        else
          WorkflowRESTClient.get_json(url, params)
        end
      end
    end

    def exec
      res = _exec
      prepare_result(res, result_type)
    end

    def run(noload = false)
      if noload
        _exec(noload)
      else
        exec
      end
    end

    def load
      exec
    end

    def join
      exec
      self
    end

    def status
      info[:status]
    end

    def clean
      WorkflowRESTClient.get_raw(url, :_update => :clean)
      self
    end

    def files
      WorkflowRESTClient.get_json(File.join(url, 'files'))
    end

    def file(file)
      WorkflowRESTClient.get_json(File.join(url, 'file', file))
    end
  end

  attr_accessor :url, :name, :exec_exports, :asynchronous_exports, :synchronous_exports

  def initialize(url, name)
    Log.debug("Loading remote workflow #{ name }: #{ url }")
    @url, @name = url, name
    init_remote_tasks
  end
  
  def to_s
    name
  end

  def workflow_description
    WorkflowRESTClient.get_raw(File.join(url, 'description'))
  end

  def task_info(task)
    @task_info ||= {}
    @task_info[task]
    
    if @task_info[task].nil?
      task_info = WorkflowRESTClient.get_json(File.join(url, task.to_s, 'info'))
      task_info = WorkflowRESTClient.fix_hash(task_info)

      task_info[:result_type] = task_info[:result_type].to_sym
      task_info[:export] = task_info[:export].to_sym
      task_info[:input_types] = WorkflowRESTClient.fix_hash(task_info[:input_types], true)
      task_info[:inputs] = task_info[:inputs].collect{|input| input.to_sym }

      @task_info[task] = task_info
    end
    @task_info[task]
  end

  def exported_tasks
    (@asynchronous_exports  + @synchronous_exports + @exec_exports).compact.flatten
  end

  def tasks
    @tasks ||= Hash.new do |hash,task_name| 
      info = task_info(task_name)
      task = Task.setup info do |*args|
        raise "This is a remote task" 
      end
      task.name = task_name.to_sym
      hash[task_name] = task
    end
  end

  def load_tasks
    exported_tasks.each{|name| tasks[name]}
    nil
  end

  def task_dependencies
    @task_dependencies ||= Hash.new do |hash,task| 
      hash[task] = if exported_tasks.include? task
        WorkflowRESTClient.get_json(File.join(url, task.to_s, 'dependencies'))
      else
        []
      end
    end
  end

  def rec_dependencies(taskname)
    if task_dependencies.include? taskname
      deps = task_dependencies[taskname].select{|dep| String === dep or Symbol === dep}
      deps.concat deps.collect{|dep| rec_dependencies(dep)}.compact.flatten
      deps.uniq
    else
      []
    end
  end

  def rec_inputs(taskname)
    [taskname].concat(rec_dependencies(taskname)).inject([]){|acc, tn| acc.concat tasks[tn.to_sym].inputs}
  end

  def rec_input_defaults(taskname)
    [taskname].concat(rec_dependencies(taskname)).inject({}){|acc, tn| acc.merge tasks[tn.to_sym].input_defaults}
  end

  def rec_input_types(taskname)
    [taskname].concat(rec_dependencies(taskname)).inject({}){|acc, tn| acc.merge tasks[tn.to_sym].input_types}
  end

  def rec_input_descriptions(taskname)
    [taskname].concat(rec_dependencies(taskname)).inject({}){|acc, tn| acc.merge tasks[tn.to_sym].input_descriptions}
  end

  def rec_input_options(taskname)
    [taskname].concat(rec_dependencies(taskname)).inject({}){|acc, tn| acc.merge tasks[tn.to_sym].input_options}
  end

  def init_remote_tasks
    task_exports = WorkflowRESTClient.get_json(url)
    @asynchronous_exports = task_exports["asynchronous"].collect{|task| task.to_sym }
    @synchronous_exports = task_exports["synchronous"].collect{|task| task.to_sym }
    @exec_exports = task_exports["exec"].collect{|task| task.to_sym }
  end

  def job(task, name, inputs)
    task_info = task_info(task)
    RemoteStep.new(url, task, name, inputs, task_info[:result_type], task_info[:result_description], @exec_exports.include?(task))
  end

  def load_id(id)
    task, name = id.split("/")
    step = RemoteStep.new File.join(url, id)
    step.result_type = task_info(task)[:result_type]
    step.result_description = task_info(task)[:result_description]
    step
  end

  def doc(task = nil)

    if task.nil?
      puts self.to_s 
      puts "=" * self.to_s.length
      puts

      puts "## TASKS"
      puts
      tasks.each do |name,task|
        puts "  * #{ name }:"
        puts "    " << task.description if task.description and not task.description.empty?
        puts
      end
    else

      if Task === task
        task_name = task.name
      else
        task_name = task
        task = self.tasks[task_name]
      end
      dependencies = self.rec_dependencies(task_name).collect{|dep_name| self.tasks[dep_name.to_sym]}

      task.doc(dependencies)
    end
  end
end
