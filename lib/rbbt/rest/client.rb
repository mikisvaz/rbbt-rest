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
    params = params.merge({ :_format => 'raw' })
    RestClient.get(url, :params => params)
  end
 
  def self.post_jobname(url, params = {})
    params = params.merge({ :_format => 'jobname' })
    RestClient.post(url, params)
  end
  
  def self.get_json(url, params = {})
    params = params.merge({ :_format => 'json' })
    res = RestClient.get(url, :params => params)
    begin
      JSON.parse(res)
    rescue
      res
    end
  end
  
  def self.post_json(url, params = {})
    params = params.merge({ :_format => 'json' })
    res = RestClient.post(url, params)
    begin
      JSON.parse(res)
    rescue
      res
    end
  end

  class RemoteStep < Step

    attr_accessor :url, :base_url, :task, :name, :inputs, :result_type, :result_description

    def name
      @url.split("/").last
    end

    def task_name
      @url.split("/")[-2]
    end

    def info
      info = WorkflowRESTClient.get_json(File.join(url, 'info'))
      info = WorkflowRESTClient.fix_hash(info)
      info[:status] = info[:status].to_sym if String === info[:status]
      info
    end

    def fork
      @name = WorkflowRESTClient.post_jobname(File.join(base_url, task.to_s), inputs.merge(:jobname => @name, :_cache_type => :asynchronous))
      @url = File.join(base_url, task.to_s, @name)
      self
    end

    def initialize(base_url, task = nil, name = nil, inputs = nil, result_type = nil, result_description = nil)
      if task.nil?
        @url = base_url
      else
        @base_url, @task, @name, @inputs, @result_type, @result_description = base_url, task, name, inputs, result_type, result_description
        self.fork
      end
    end

    def _exec
      case result_type
      when :string
        WorkflowRESTClient.get_raw(url, :_cache_type => :synchronous) 
      when :boolean
        WorkflowRESTClient.get_raw(url, :_cache_type => :synchronous) == "true"
      when :tsv
        TSV.open(StringIO.new(WorkflowRESTClient.get_raw(url, :_cache_type => :synchronous)))
      when :annotations
        Annotated.load_tsv(TSV.open(StringIO.new(WorkflowRESTClient.get_raw(url, :_cache_type => :synchronous))))
      else
        WorkflowRESTClient.get_json(url, :_cache_type => :synchronous)
      end
    end

    def exec
      res = _exec
      prepare_result(res, result_type)
    end

    def run
      exec
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

  def init_remote_tasks
    task_exports = WorkflowRESTClient.get_json(url)
    @asynchronous_exports = task_exports["asynchronous"].collect{|task| task.to_sym }
    @synchronous_exports = task_exports["synchronous"].collect{|task| task.to_sym }
    @exec_exports = task_exports["exec"].collect{|task| task.to_sym }
  end

  def job(task, name, inputs)
    task_info = task_info(task)
    RemoteStep.new(url, task, name, inputs, task_info[:result_type], task_info[:result_description])
  end

  def load_id(id)
    task, name = id.split("/")
    step = RemoteStep.new File.join(url, id)
    step.result_type = task_info(task)[:result_type]
    step.result_description = task_info(task)[:result_description]
    step
  end

end

if __FILE__ == $0
  client = WorkflowRESTClient.new("http://darthcaedus:9292/Sequence", "Sequence")

  job = client.job(:genes_at_genomic_positions, "1", :organism => "Hsa", :positions => ["2:198266834:R"]).clean.fork
  puts job.join.load.to_s
  
end

