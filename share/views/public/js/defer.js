var deferred_execution = [];

function defer(deps, func){
  if (undefined === func){
    func = deps;
    deps = undefined;
  }
  if (undefined !== deps){
    deferred_execution.push([deps, func]);
  }else{
    deferred_execution.push(func)
  }
}

function start_deferred(){
  var tmp = $.unique(deferred_execution);
  deferred_execution = [];
  $(tmp).each(function(pos,func){
    if (typeof(func) == 'object'){
      require_js(func[0], func[1]);
    }else{
      rbbt.try(func).call()
    }
  })
  return(false)
}


