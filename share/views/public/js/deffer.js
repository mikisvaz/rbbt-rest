var defferred_execution = [];

function deffer(func){
  defferred_execution.push(func);
}

function start_defferred(){
  $(defferred_execution).each(function(pos,func){
    func.call();
  })
}


