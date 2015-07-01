rbbt.exception = {}

rbbt.exception.null = function(variable, text){
  if (variable == null) throw(text)
}

rbbt.exception.report = function(err){
  rbbt.modal.controller().error(err, "Application Error")
}

rbbt.try = function(func){
  var f = function(){
    try {
      return func.apply(this, arguments)
    }catch(err){
      rbbt.exception.report(err)
    }
  }
  return f
}

