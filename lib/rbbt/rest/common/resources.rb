require 'sass'
require 'yui/compressor'

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

  def serve_js
    if production? and not @debug_js
      md5 = Misc.digest(recorded_js_files * ",")
      filename = File.join(settings.file_dir, "all_js-#{md5}.js")

      if not File.exists?(filename)
        Log.debug("Regenerating JS Compressed file: #{ filename }")

        text = recorded_js_files.collect{|file| 
          begin
            path = locate_javascript(file)
          rescue
            path = locate_javascript(File.basename(file))
          end

          Open.read(path)
        } * "\n"

        FileUtils.mkdir_p File.dirname(filename) unless File.exists? File.dirname(filename)
        Open.write(filename, YUI::JavaScriptCompressor.new(:munge => false).compress(text))
      end

      res = "<script src='/files/#{File.basename(filename)}' type='text/javascript'></script>"
    else
      res = recorded_js_files.collect{|file|
        file += '.js' unless file =~ /.js$/
          "<script src='#{ file }' type='text/javascript'></script>"
        html_tag('script', " ", :src => file, :type => 'text/javascript')
      } * "\n"

    end

    recorded_js_files.clear

    res
  end

  def serve_css
    res = recorded_css_files.collect{|file|
      file += '.css' unless file =~ /.css$/
      html_tag('link', nil, :rel => 'stylesheet', :type => 'text/css', :href => file)
    } * "\n"

    recorded_css_files.clear

    res
  end

end
 
