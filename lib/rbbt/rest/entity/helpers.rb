
module EntityRESTHelpers

  def list(list, list_id = nil)
    partial_render('entity_partials/entity_list', :list => list, :list_id => list_id)
  end

  def action_parameters_id
    case
    when (params[:entity] and params[:action])
      ["action_params", params[:entity], params[:action]] * "__"
    else
      ["action_params", (rand * 1000).to_i] * "__"
    end
  end

  def action_parameters(values = nil, &block)
    o = Object.new
    o.extend AnnotatedModule
    o.instance_eval &block

    values = @clean_params.dup if values.nil?

    inputs = o.inputs
    input_types = o.input_types
    input_defaults = o.input_defaults
    input_options = o.input_options

    hidden_inputs = []
    inputs.each do |input|
      values[input] = values.delete input.to_s unless values.include? input
      input_value = values[input]
      input_default = input_defaults[input]
      input_option = input_options[input]
      hide = consume_parameter :hide, input_option || {}

      hidden_inputs << input if hide
    end

    locals = {}
    info = {:hide_inputs => hidden_inputs, :inputs => inputs, :input_defaults => input_defaults, :input_options => input_options, :input_types => input_types, :values => values}
    locals[:id] = action_parameters_id
    locals[:action] = @ajax_url
    locals[:klass] = 'action_parameters'
    locals[:info] = info

    partial_render('partials/form', locals)
  end
end
