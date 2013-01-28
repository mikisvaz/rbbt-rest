
module EntityRESTHelpers

  def list(list, list_id = nil)
    partial_render('entity_partials/entity_list', :list => list, :list_id => list_id)
  end

  def action_parameters(values, &block)
    o = Object.new
    o.extend AnnotatedModule
    o.instance_eval &block

    inputs = o.inputs
    input_types = o.input_types
    input_defaults = o.input_defaults
    input_options = o.input_options

    hidden_inputs = []
    inputs.each do |input|
      if values[input].nil? and input_defaults.include? input
        values[input] = input_defaults[input]
      end
      hidden_inputs << input if input_options.include? input and input_options[input].delete :hide
    end

    locals = {}
    info = {:hide_inputs => hidden_inputs, :inputs => inputs, :input_defaults => input_defaults, :input_options => input_options, :input_types => input_types, :values => values}
    locals[:action] = @ajax_url
    locals[:klass] = 'action_parameters'
    locals[:info] = info

    partial_render('partials/form', locals)
  end
end
