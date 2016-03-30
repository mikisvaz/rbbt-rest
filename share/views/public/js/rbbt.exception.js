rbbt.exception = {}

rbbt.exception.null = function(variable, text){
  if (variable == null) throw(text)
}

rbbt.exception.report = function(err){
  console.log(err)
  console.log("Error: " + err)
  var stack = err.stack
  if(undefined === stack) stack = "No stack trace"
  if (rbbt.modal){
    stack = "<ul class='stacktrace'><li>" + stack.replace(/\n/g, '</li><li>') + '<li/></ul>'
    stack = stack.replace(/<li><li\/>/g,'').replace(/<li>(.*?)@(.*?):(\d+:\d+)<\/li>/g, '<li>$2<span style="font-weight:bold">$3</span><br/><em>$1</em></li>')
    rbbt.modal.controller.error(m('.ui.error.message', [m('.header', err), m('.description', m.trust(stack))]), "Application Error")
  }else{
    console.log(stack)
  }
}

rbbt.try = function(func, catch_function){
  var f = function(){
    try {
      return func.apply(this, arguments)
    }catch(err){
      if (catch_function)
        catch_function(err)
      else
        rbbt.exception.report(err)
    }
  }
  return f
}

rbbt.do_try = function(func){
  return rbbt.try(func)()
}

