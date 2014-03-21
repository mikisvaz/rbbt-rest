class WorkflowRESTClient
  class RemoteStep < Step

    attr_accessor :url, :base_url, :task, :base_name, :inputs, :result_type, :result_description, :is_exec

    def initialize(base_url, task = nil, base_name = nil, inputs = nil, result_type = nil, result_description = nil, is_exec = false)
      @base_url, @task, @base_name, @inputs, @result_type, @result_description, @is_exec = base_url, task, base_name, inputs, result_type, result_description, is_exec
    end

    def name
      return nil if @is_exec
      (Array === @url ? @url.first : @url).split("/").last
    end

    def task_name
      (Array === @url ? @url.first : @url).split("/")[-2]
    end

    def info
      init_job unless url
      info = WorkflowRESTClient.get_json(File.join(url, 'info'))
      info = WorkflowRESTClient.fix_hash(info)
      info[:status] = info[:status].to_sym if String === info[:status]
      info
    end
    
    def status
      info[:status]
    end

    def done?
      status.to_s == 'done'
    end

    def files
      WorkflowRESTClient.get_json(File.join(url, 'files'))
    end

    def file(file)
      WorkflowRESTClient.get_raw(File.join(url, 'file', file))
    end

    #{{{ MANAGEMENT
    
    def init_job(cache_type = :asynchronous)
      @name = WorkflowRESTClient.post_jobname(File.join(base_url, task.to_s), inputs.merge(:jobname => @name, :_cache_type => cache_type))
      @url = File.join(base_url, task.to_s, @name)
      nil
    end

    def load_res(res)
      case result_type
      when :string
        res
      when :boolean
        res == "true"
      when :tsv
        TSV.open(StringIO.new(res))
      when :annotations
        Annotated.load_tsv(TSV.open(StringIO.new(res)))
      else
        JSON.parse res
      end
    end

    def get
      params ||= {}
      params = params.merge(:_format => [:string, :boolean, :tsv, :annotations].include?(result_type) ? :raw : :json )
      begin
        WorkflowRESTClient.get_raw(url, params) 
      rescue => e
        raise e.response
      end
    end

    def load
      params = {}
      load_res get
    end
    
    def exec_job
      res = WorkflowRESTClient.capture_exception do
        RestClient.post(URI.encode(File.join(base_url, task.to_s)), inputs.merge(:_cache_type => :exec, :_format => [:string, :boolean, :tsv, :annotations].include?(result_type) ? :raw : :json))
      end
      loaded = load_res res
      exit
      loaded
    end

    def fork
      init_job(:asynchronous)
    end

    def running?
      ! %w(done error aborted).include? status.to_s
    end

    def path
      url
    end

    def run(noload = false)
      return exec_job if @is_exec
      init_job(:synchronous)
      noload ? @name : self.load
    end

    def exec
      exec_job
    end

    def join
      self.load
      self
    end

    def clean
      WorkflowRESTClient.get_raw(url, :_update => :clean) unless @is_exec
      self
    end
  end
end
