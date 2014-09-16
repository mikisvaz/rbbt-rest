var defferred_execution = [];

function deffer(deps, func){
  if (undefined === func){
    func = deps;
    deps = undefined;
  }
  if (undefined !== deps){
    defferred_execution.push([deps, func]);
  }else{
    defferred_execution.push(func)
  }
}

function start_defferred(){
  $(defferred_execution).each(function(pos,func){
    if (typeof(func) == 'object'){
      require_js(func[0], func[1]);
    }else{
      func.call();
    }
  })
  defferred_execution = [];
}


