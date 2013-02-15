
require 'rbbt/rest/common/users'

module RbbtRESTHelpers

  MEMORY_CACHE = {}

  def old_cache(path, check)
    return false if check.nil? or check.empty?
    return false if not File.exists? path
    check = [check] unless Array === check
    return check.select{|file| not File.exists?(file) or File.mtime(file) > File.mtime(path)}.any?
  end

  def cache(name, params = {}, &block)
    return yield if name.nil? or cache_type.nil? or cache_type == :none

    send_file = consume_parameter(:_send_file, params)

    check = [params[:_template_file]].compact
    check += consume_parameter(:_cache_check, params) || []
    check.flatten!
    
    name += "_" << Misc.hash2md5(params) if params.any?

    path = File.join(settings.cache_dir, name)
    task = Task.setup(:name => "Sinatra cache", :result_type => :string, &block)

    step = Step.new(path, task, nil, nil, self)

    self.instance_variable_set("@step", step)

    if @fragment
      fragment_file = step.file(@fragment)
      if File.exists?(fragment_file)
        send_file fragment_file
      else
        if File.exists?(fragment_file + '.error') 
          halt 500, html_tag(:span, File.read(fragment_file + '.error'), :class => "message") + 
            html_tag(:ul, File.read(fragment_file + '.backtrace').split("\n").collect{|l| html_tag(:li, l)} * "\n", :class => "backtrace") 
        else
          halt 202, "Fragment not completed"
        end
      end
    end


    if old_cache(path, check) or update == :reload
      begin
        pid = step.info[:pid]
        step.abort if pid and Misc.pid_exists? pid
        step.pid = nil
      rescue Exception
        Log.medium $!.message
      end
      step.clean 
    end

    step.fork unless step.started?

    step.join if cache_type == :synchronous or cache_type == :sync

    if update == :reload
      url = request.url
      url = remove_GET_param(url, :_update)
      url = remove_GET_param(url, :_)
      redirect to(url)
    end

    begin
      case step.status
      when :error
        error_for step, false
      when :done
        if send_file
          send_file step.path
        else
          step.load
        end
      else
        wait_on step, false
      end
    rescue Retry
      retry
    end
  end
end

