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
    Log.debug{ "RestClient get_raw: #{ url } - #{Misc.fingerprint params}" }
    params = params.merge({ :_format => 'raw' })
    Misc.insist(2, 0.5) do
      RestClient.get(URI.encode(url), :params => params)
    end
  end
 
  def self.post_jobname(url, params = {})
    Log.debug{ "RestClient post_jobname: #{ url } - #{Misc.fingerprint params}" }
    params = params.merge({ :_format => 'jobname' })
    RestClient.post(URI.encode(url), params)
  end
  
  def self.get_json(url, params = {})
    Log.debug{ "RestClient get_json: #{ url } - #{Misc.fingerprint params }" }
    params = params.merge({ :_format => 'json' })
    begin
      res = RestClient.get(URI.encode(url), :params => params)
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
      res = RestClient.post(URI.encode(url), params)
      begin
        JSON.parse(res)
      rescue
        res
      end
    end
  end

end
