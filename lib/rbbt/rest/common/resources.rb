require 'sass'

module RbbtRESTHelpers
  def self.add_sass_load_path(path)
    Sass::Engine::DEFAULT_OPTIONS[:load_paths] << path
  end

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

  def serve_js(compress = true)
    res = recorded_js_files.collect{|file|
      file += '.js' unless file =~ /.js$/
        "<script src='#{ file }' type='text/javascript'></script>"
      html_tag('script', " ", :src => file, :type => 'text/javascript')
    } * "\n"

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
 
