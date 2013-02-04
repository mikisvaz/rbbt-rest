require 'rbbt/ner/finder'

module EntityRESTHelpers
  def finder_find(term)
    return [] unless settings.respond_to? :finder and not settings.finder.nil?
    results = settings.finder.find(term)

    results.uniq.collect{|r| 
      info = r.info
      format_string = [info[:namespace], info[:format]].compact * ":"

      info[:code] = r

      if not format_string.empty?
        info[:value] = r + " [#{format_string}]" 
      else
        info[:value] = r
      end

      score = info.delete :score

      if Array === score
        info[:score] = score[0]
        info[:best] = score[1]
      end

      info 
    }.sort_by{|i| i[:score] || 0}.reverse
  end
end
