require 'sass'
require 'uglifier'

module RbbtRESTHelpers
  def recorded_js_files
    @recorded_js_files ||= []
  end

  def recorded_css_files
    @recorded_css_files ||= []
  end


  def record_js(file)
    recorded_js_files << file
  end

  def record_css(file)
    recorded_css_files << file
  end

  def link_css(file)
    file += '.css' unless file =~ /.css$/
    file << "?_update=reload" if @debug_css
    html_tag('link', nil, :rel => 'stylesheet', :type => 'text/css', :href => file)
  end

  def link_js(file)
    file += '.js' unless file =~ /.js$/
    html_tag('script', " ", :src => file, :type => 'text/javascript')
  end

  def serve_js(compress = true)
    if production? and compress and not @debug_js 
      md5 = Misc.digest(recorded_js_files * ",")
      filename = File.join(settings.file_dir, "all_js-#{md5}.js")

      if not File.exists?(filename)
        Log.debug("Regenerating JS Compressed file: #{ filename }")

        text = recorded_js_files.collect{|file| 
          begin
            path = locate_javascript(file)
          rescue
            path = locate_javascript(file.split("/")[2..-1] * "/")
          end

          Open.read(path)
        } * "\n"

        FileUtils.mkdir_p File.dirname(filename) unless File.exists? File.dirname(filename)
        Open.write(filename, Uglifier.compile(text))
      end

      res = "<script src='/files/#{File.basename(filename)}' type='text/javascript'></script>"
    else
      res = recorded_js_files.collect{|file|
        link_js(file)
      } * "\n"

    end

    recorded_js_files.clear

    res
  end

  def serve_css
    res = recorded_css_files.collect{|file|
      link_css(file)
    } * "\n"

    recorded_css_files.clear

    res
  end

end
 
