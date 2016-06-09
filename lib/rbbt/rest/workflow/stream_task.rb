class StreamWorkflowTask
  include WorkflowRESTHelpers
  include RbbtRESTHelpers

  def initialize(app)
    @app = app
  end

  EOL = "\r\n"

  def parse_uri(env)
    uri = env["REQUEST_URI"]
    _n, workflow, task = uri.split("/")
    workflow = begin
                 Kernel.const_get(workflow)
               rescue
                 raise "Could not accept task for workflow: #{ workflow }"
               end
    [workflow, task]
  end

  def read_normal_inputs(io, boundary, stream_input)
    inputs = {}

    input_name = nil
    variable_chunk = nil
    filename = nil

    while line = io.gets
      line.chomp!

      chunk_start = line == "--" + boundary

      if chunk_start
        if input_name
          inputs[input_name] = variable_chunk
        end
        content_start = false
      elsif content_start  
        if variable_chunk.empty?
          variable_chunk << line
        else
          variable_chunk << "\n" << line
        end
      elsif line =~ /^Content.* name="([^\s;"]*)"/
        input_name = $1
        filename = line.match(/filename="([^"]+)"/)[1] if line =~ /filename/
      elsif line.empty?
        variable_chunk = ""
        break if input_name == stream_input
        content_start = true
      end
    end
    
    [inputs, filename]
  end

  def copy_until_boundary(sin, sout, boundary)
    last_line = nil
    while line = sin.gets
      break if line.include? boundary
      sout.write last_line
      last_line = line
    end
    sout.write last_line.strip unless last_line == EOL
  end

  def get_inputs(content_type, stream)
    boundary = content_type.match(/boundary=([^\s;]*)/)[1]
    stream_input = content_type.match(/stream=([^\s;]*)/)[1]
    inputs, filename = read_normal_inputs(stream, boundary, stream_input)

    IndiferentHash.setup(inputs)

    [inputs, stream_input, filename, stream, boundary]
  end

  def run_job(workflow, task, inputs, stream_input, stream, boundary, filename = nil)
    name = inputs.delete "jobname"

    task_parameters = prepare_job_inputs(workflow, task, inputs)

    Misc.add_stream_filename(stream, filename) if filename

    clean_stream = Misc.open_pipe do |sin|
      copy_until_boundary(stream, sin, boundary)
    end

    task_parameters[stream_input] = clean_stream

    task = task.to_sym

    job = workflow.job(task, name, task_parameters)

    execution_type = case
                     when workflow.exec_exports.include?(task)
                       "exec"
                     when workflow.synchronous_exports.include?(task)
                       "synchronous"
                     when workflow.asynchronous_exports.include?(task)
                       "asynchronous"
                     else
                       raise "No known export type for #{ workflow } #{ task }. Accesses denied"
                     end 

    execution_type = "exec" if inputs["_cache_type"] == 'exec'

    begin
      case execution_type
      when "exec", nil
        job.exec(:stream)
      when "sync", "synchronous", "async", "asynchronous"
        if job.done? or job.started?
          done_consumer = Thread.new do
            Misc.consume_stream(stream, false)
          end
          job.join unless job.done?
        else
          job.run(:stream)
        end
      else
        raise "Unknown execution_type: #{execution_type}"
      end

    rescue Aborted, Interrupt
      job.abort
      stream.write "HTTP/1.1 500\r\n"
      stream.close_write
    rescue Exception
      job.exception $!
      stream.write "HTTP/1.1 500\r\n"
      stream.close_write
    end

    job
  end

  def _merge_chunks(sin, sout)

    begin
      while true
        chunk_size_str = ""
        stop = false
        while chunk_size_str.strip.empty? 
          chunk_size_str = sin.gets
          raise "Empty chunk size" if chunk_size_str.nil? or chunk_size_str.strip.empty?
          chunk_size_str = "" if chunk_size_str.nil?
        end
        break if stop
        size = chunk_size_str.strip.to_i(16)
        break if size == 0 
        chunk = sin.read(size)
        bound = sin.read(2)
        raise "bound not right: #{ bound }" if bound != EOL
        raise "Size does not match: #{[chunk.length, size] * " != "}" if chunk.length != size
        sout.write chunk
      end
    rescue Aborted
      raise $!
    rescue Exception
      Log.exception $!
      raise $!
    ensure
      if sin.respond_to? :close_read
        sin.close_read 
      else
        sin.close unless sin.closed?
      end
      if sin.respond_to? :threads
        sin.threads.each do |th| th.raise Aborted end
      end

    end
  end

  def merge_chunks(sin, sout, buffer)
    if buffer.nil?
      _merge_chunks(sin, sout)
    else
      ssin = Misc.open_pipe do |s|
        begin
          s <<  buffer
          while c = sin.readpartial(Misc::BLOCK_SIZE)
            s << c
          end
        rescue Aborted, IOError
        rescue Exception
        ensure
          sin.close_read
          s.close
        end
      end
      _merge_chunks(ssin, sout)
    end
  end

  def do_stream(env)
    uri = env["REQUEST_URI"]

    post = env["REQUEST_METHOD"]
    return false unless post == "POST"

    hijack = !!env["rack.hijack"]
    return false unless hijack

    content_type = env["CONTENT_TYPE"] 
    return false unless content_type and content_type.include? "Rbbt_Param_Stream"

    encoding = env["HTTP_TRANSFER_ENCODING"] 
    return false unless encoding == "chunked"

    true
  end

  def call(env)

    if do_stream(env)
      begin

        client = env["rack.hijack"]
        buffer = client.instance_variable_get('@buffer')
        tcp_io = client.call
        Log.low "Hijacking post data #{tcp_io}"

        content_type = env["CONTENT_TYPE"]

        tcp_merged_io = Misc.open_pipe do |sin| merge_chunks(tcp_io, sin, buffer) end

        inputs, stream_input, filename, stream, boundary = get_inputs(content_type, tcp_merged_io)

        workflow, task = parse_uri(env)

        job = run_job(workflow, task, inputs, stream_input, stream, boundary, filename)

        job_url = File.join("/", workflow.to_s, task, job.name)

        out_stream = TSV.get_stream job

        begin
          Log.low "Write response #{tcp_io} "
          tcp_io.write "HTTP/1.1 200\r\n"
          tcp_io.write "Connection: close\r\n"
          tcp_io.write "RBBT-STREAMING-JOB-URL: #{ job_url }\r\n"
          tcp_io.write "\r\n"
          Log.low "Comsuming response #{tcp_io}"
          Misc.consume_stream(out_stream, false, tcp_io)
          Log.low "Comsumed response #{tcp_io}"
        rescue Exception
          Log.exception $!
        end if out_stream

        tcp_io.close unless tcp_io.closed?
        Log.low "Closed io #{tcp_io}"

        [-1, {}, []]
      rescue
        Log.exception $!
        io.write "HTTP/1.1 515\r\n"
        io.write "Connection: close\r\n"
        io.write "\r\n"
        io.close_write
        raise $!
      end
    else
      Log.low "NOT Hijacking post data"

      @app.call(env)
    end
  end

end

