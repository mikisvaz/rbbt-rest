require 'rbbt/rest/common/misc'

module WorkflowRESTHelpers


  def input_label(id, description, default = nil)
    text = description
    text += " (Default: " << default.to_s << ")" unless default.nil?
    html_tag('label', text, :id => 'label_for__' << id, :for => id)
  end

  def file_or_text_area(id, name, value)
    html_tag("input", nil, :type => "file", :id => id +  "__" + "param_file", :name => name.to_s + "__" + "param_file") + 
    html_tag("span", "or use the text area bellow", :class => "file_or_text_area") + 
    html_tag("textarea", value || "" , :name => name, :id => id )
  end

  def form_input(name, type, default, current, description, id)

    case type
    when :boolean
      current = param2boolean(current)
      default = param2boolean(default)

      check_true = current.nil? ? default : current
      check_true = false if check_true.nil?
      check_false = ! check_true
      
      false_id = id + '__' << 'false'
      true_id = id + '__' << 'true'

      input_label(false_id, description, default) +
      input_label(false_id, true, nil) +
      html_tag("input", nil, :type => :radio, :checked => check_true, :name => name, :value => "true", :id => true_id) +
      input_label(false_id, false, nil) +
      html_tag("input", nil, :type => :radio, :checked => check_false, :name => name, :value => "false", :id => false_id) 

    when :string, :float, :integer
      value = current.nil? ? default : current

      input_label(id, description, default) +
      html_tag("input", nil, :name => name, :value => value, :id => id)

    when :tsv, :array, :text
      value = current.nil? ? default : current
      value = value * "\n" if Array === value

      input_label(id, description, default) +
      file_or_text_area(id, name, value)

    else
      "<span> Unsupported input #{name} #{type} </span>"
    end
  end
end
