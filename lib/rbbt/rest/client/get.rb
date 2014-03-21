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

  def self.capture_exception
    begin
      yield
    rescue Exception => e
      raise $! unless e.respond_to? :response
      klass, message = e.response.split " => "
      begin
        klass = Kernel.const_get klass
      rescue
        raise message
      end
      raise klass.new message
    end
  end

  def self.get_raw(url, params = {})
    Log.debug{ "RestClient get_raw: #{ url } - #{Misc.fingerprint params}" }
    params = params.merge({ :_format => 'raw' })
    capture_exception do
      Misc.insist(2, 0.5) do
        RestClient.get(URI.encode(url), :params => params)
      end
    end
  end
 
  def self.post_jobname(url, params = {})
    Log.debug{ "RestClient post_jobname: #{ url } - #{Misc.fingerprint params}" }
    params = params.merge({ :_format => 'jobname' })

    capture_exception do
      RestClient.post(URI.encode(url), params)
    end
  end
  
  def self.get_json(url, params = {})
    Log.debug{ "RestClient get_json: #{ url } - #{Misc.fingerprint params }" }
    params = params.merge({ :_format => 'json' })

    res = capture_exception do
      RestClient.get(URI.encode(url), :params => params)
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

      res = capture_exception do
        RestClient.post(URI.encode(url), params)
      end

      begin
        JSON.parse(res)
      rescue
        res
      end
    end
  end

end
