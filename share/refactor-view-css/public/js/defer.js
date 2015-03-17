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
  $($.unique(deferred_execution)).each(function(pos,func){
    if (typeof(func) == 'object'){
      require_js(func[0], func[1]);
    }else{
      func.call();
    }
  })
  deferred_execution = [];
}


