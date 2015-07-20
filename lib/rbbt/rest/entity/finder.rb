require 'rbbt/ner/finder'

module EntityRESTHelpers
  def finder_find(term)
    return [] unless settings.respond_to? :finder and not settings.finder.nil? and not settings.finder.instances.empty?
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

      info[:format] ||= info[:type]

      info 
    }.sort_by{|i| i[:score] || 0}.reverse
  end

  def find_entity_url(term)
    if term =~ /(.*) \[(.*)\]$/
      term = $1
      namespace, format = $2.split(":")
      format, namespace = namespace, nil if format.nil?

      Entity::REST.entity_url(term, format, :organism => namespace)
    else
      sorted_results = finder_find(term)
      organism = sorted_results.select{|r| r[:type] == 'organism' }.first
      sorted_results = sorted_results.reject{|r| r[:type] == 'organism' }
      i = sorted_results.first
      halt 404, "Term not recognized: #{ term }" if i.nil?
      organism_code = i[:namespace]
      organism_code = organism[:code] unless organism.nil? or organism[:code].nil?
      Entity::REST.entity_url(i[:code], i[:format], :organism => organism_code)
    end
  end
end
