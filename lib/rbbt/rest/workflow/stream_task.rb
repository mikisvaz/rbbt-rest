class StreamWorkflowTask
  def initialize(app)
    @app = app
  end

  def read_normal_inputs(io, boundary, stream_input)
    content = ""
    content_start = false
    variable = nil
    filename = nil
    inputs = {}

    while line = io.gets
      line.chomp!

      if line == "--" + boundary
        if variable
          inputs[variable] = content
        end
        content_start = false
        content = ""
      elsif line =~ /^Content.* name="([^\s;"]*)"/
        variable = $1
        filename = line.match(/filename="([^"]+)"/)[1] if line =~ /filename/
        content = ""
      elsif line.empty?
        content_start = true
        break if variable == stream_input
      else
        content << line if content_start
      end
    end
    
    [inputs, filename]
  end

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

  EOL = "\r\n"
  def read_chunk(sin, rest = "")
    parts = []
    c = sin.read(1024)
    #c = sin.gets
    raise "Early connection close" if c.nil?
    c = rest << c unless rest.empty?
    c = c[2..-1] if c[0..1] == EOL
    index = c.index EOL
    while index
      part = c[0..index-1]
      parts << part
      c = c[index+2..-1]
      index = c.index EOL
    end
    rest = c
    [parts, rest]
  end

  def copy_chunked_stream(sin, sout, boundary)

    rest = ""
    done = false
    content = false

    while not done
      parts, rest = read_chunk(sin, rest)
      while parts.any?
        part = parts.shift
        if content
          part.split("\n").each do |line|
            sout.puts line
            if line.include? boundary
              done = true
              break
            end
          end
          content = false
        else
          content = true
        end
      end
    end

    sout.write rest
    sout.close
  end

  def merge_chunks(sin, sout)

    rest = ""
    done = false
    content = true

    while not done
      chunk_size_str = ""
      while chunk_size_str.strip.empty?
        chunk_size_str = sin.gets
        raise "Error reading chunks" if chunk_size_str.nil?
      end
      size = chunk_size_str.strip.to_i(16)
      break if size == 0
      chunk = sin.read(size)
      bound = sin.read(2)
      raise "Size does not match" if false and chunk.length != size
      sout.write chunk
    end

    sout.write rest
    sout.close
  end

  def copy_until_boundary(sin, sout, boundary)
    while line = sin.gets
      break if line.include? boundary
      sout.write line
    end
  end


  def call(env)
    if env["REQUEST_METHOD"] == "POST" and env["rack.hijack"] and env["CONTENT_TYPE"] and env["CONTENT_TYPE"].include? "Rbbt_Param_Stream" and env["HTTP_TRANSFER_ENCODING"] == 'chunked'
      Log.high "Hijacking post data"
      inputs = {}
      content_type = env["CONTENT_TYPE"]
      boundary = content_type.match(/boundary=([^\s;]*)/)[1]
      stream_input = content_type.match(/stream=([^\s;]*)/)[1]
      post_stream_chunked = env["rack.hijack"].call

      job_url = nil
      begin
        post_stream = Misc.open_pipe do |sin|
          merge_chunks(post_stream_chunked, sin)
        end

        inputs, filename = read_normal_inputs(post_stream, boundary, stream_input)

        input_stream_out, input_stream_in = Misc.pipe
        Misc.add_stream_filename(input_stream_out, filename) if filename
        inputs[stream_input] = input_stream_out

        workflow, task = parse_uri(env)
        name = inputs.delete "jobname"
        job = workflow.job(task, name, inputs)
        Log.high "Run job #{job.path} with inputs #{Misc.fingerprint(inputs)}"

        job_url = File.join("/", workflow.to_s, task, job.name)

        task = task.to_sym
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
        Log.info "Streaming task with execution_type: #{ execution_type }"

        case execution_type
        when "exec", nil
          job.exec(:stream)
        when "sync", "synchronous", "async", "asynchronous"
          if job.done?
            done_consumer = Thread.new do
              while c = post_stream.read(1024)
              end
            end
          else
            job.run(:stream)
          end
        else
          raise "Unknown execution_type: #{execution_type}"
        end

        t_in = Thread.new do 
          begin
            copy_until_boundary(post_stream, input_stream_in, boundary)
            input_stream_in.close
            post_stream.close_read
          rescue
            Log.exception $!
          end
        end unless job.done?

        job_output = TSV.get_stream job
        t_out = Thread.new do 
          begin
            post_stream_chunked.write "HTTP/1.1 200\r\n"
            post_stream_chunked.write "RBBT-STREAMING-JOB-URL: #{ job_url }\r\n"
            post_stream_chunked.write "\r\n"
            while c = job_output.read(1024)
              post_stream_chunked.write c
            end
            job_output.join if job_output.respond_to? :join
            post_stream_chunked.close_write
            done_consumer.join if done_consumer
          rescue
            Log.exception $!
            job.abort
          end
        end

      end

      [200, {}, nil]
    else
      Log.high "NOT Hijacking post data"
      @app.call(env)
    end
  end

  #def call_old(env)
  #  if env["REQUEST_METHOD"] == "POST" and env["rack.hijack"] and env["CONTENT_TYPE"] and env["CONTENT_TYPE"].include? "Rbbt_Param_Stream" and env["HTTP_TRANSFER_ENCODING"] == 'chunked'
  #    Log.high "Hijacking post data"
  #    inputs = {}
  #    content_type = env["CONTENT_TYPE"]
  #    boundary = content_type.match(/boundary=([^\s;]*)/)[1]
  #    stream_input = content_type.match(/stream=([^\s;]*)/)[1]
  #    post_stream = env["rack.hijack"].call
  #    job_url = nil
  #    begin
  #      inputs, filename = read_normal_inputs(post_stream, boundary, stream_input)

  #      input_stream_out, input_stream_in = Misc.pipe
  #      Misc.add_stream_filename(input_stream_out, filename) if filename
  #      inputs[stream_input] = input_stream_out

  #      workflow, task = parse_uri(env)
  #      name = inputs.delete "jobname"
  #      job = workflow.job(task, name, inputs)
  #      Log.high "Run job #{job.path} with inputs #{Misc.fingerprint(inputs)}"

  #      job_url = File.join("/", workflow.to_s, task, job.name)

  #      task = task.to_sym
  #      execution_type = case
  #                       when workflow.exec_exports.include?(task)
  #                         "exec"
  #                       when workflow.synchronous_exports.include?(task)
  #                         "synchronous"
  #                       when workflow.asynchronous_exports.include?(task)
  #                         "asynchronous"
  #                       else
  #                         raise "No known export type for #{ workflow } #{ task }. Accesses denied"
  #                       end 

  #      execution_type = "exec" if inputs["_cache_type"] == 'exec'
  #      Log.info "Streaming task with execution_type: #{ execution_type }"

  #      case execution_type
  #      when "exec", nil
  #        job.exec(:stream)
  #      when "sync", "synchronous", "async", "asynchronous"
  #        if job.done?
  #          done_consumer = Thread.new do
  #            while c = post_stream.read(1024)
  #            end
  #          end
  #        else
  #          job.run(:stream)
  #        end
  #      else
  #        raise "Unknown execution_type: #{execution_type}"
  #      end

  #      t_in = Thread.new do 
  #        begin
  #          copy_chunked_stream(post_stream, input_stream_in, boundary)
  #        rescue
  #          Log.exception $!
  #        end
  #      end unless job.done?

  #      job_output = TSV.get_stream job
  #      t_out = Thread.new do 
  #        begin
  #          post_stream.write "HTTP/1.1 200\r\n"
  #          post_stream.write "RBBT-STREAMING-JOB-URL: #{ job_url }\r\n"
  #          post_stream.write "\r\n"
  #          while c = job_output.read(1024)
  #            post_stream.write c
  #          end
  #          job_output.join if job_output.respond_to? :join
  #          post_stream.close_write
  #          done_consumer.join if done_consumer
  #        rescue
  #          Log.exception $!
  #          job.abort
  #        end
  #      end

  #    end
  #    [200, {}, nil]
  #  else
  #    Log.high "NOT Hijacking post data"
  #    @app.call(env)
  #  end
  #end
end

