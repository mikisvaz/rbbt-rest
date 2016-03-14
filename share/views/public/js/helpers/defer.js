var deferred_execution = [];

function defer(deps, func, step_path){
  if (typeof func == 'string'){
    step_path = func
    func = deps
    deps = undefined;
  }
  if (undefined === func){
    func = deps;
    deps = undefined;
  }
  document.step_path = step_path
  deferred_execution.push([func, deps, step_path]);
}

function start_deferred(){
  var tmp = $.unique(deferred_execution);
  deferred_execution = [];
  $(tmp).each(function(pos,func){
    if (undefined === func[1]){
      rbbt.try(func[0])(func[2])
    }else{
      require_js(func[1], func[0], func[2]);
    }
  })
  return(false)
}


