
rbbt.Job = function(workflow, task, inputs){
  this.workflow = workflow
  this.task = task
  this.inputs = inputs

  this.jobname = m.prop()
  this.jobURL = function(){ return '/' + workflow + '/' + task + '/' + this.jobname() }
  this.result = m.prop()
  this.info = m.prop()

  this.dependencies = function(){
    var deferred = m.deferred()

    this.get_info().then(function(info){
      var dependencies = info.dependencies

      if (dependencies === undefined || dependencies.length == 0){
        deferred.resolve([])
      }else{
        var deps = [];
        forArray(dependencies, function(elem){
          var path = elem[2];
          var dep = rbbt.path_job(path)
          deps.push(dep)
        })
        deferred.resolve(deps)
      }

    }.bind(this))

    return deferred.promise
  }

  this.files = function(){
    var url = this.jobURL() + '/files?_format=json';

    var params = {
      url: url, 
      method: 'GET', 
      serialize: function(data) {return data},
      deserialize: function(data){return JSON.parse(data)}
    }

    return rbbt.insist_request(params)
  }

  this.file = function(file){
    return(this.jobURL() + '/file/' + file);
  }

  this.exec = function(json){
    var deferred = m.deferred()
    
    var url = '/' + workflow + '/' + task

    var data = new FormData()
    data.append("_cache_type", 'exec')

    if (json)
      data.append("_format", 'json')
    else
      data.append("_format", 'raw')

    for (i in inputs){
      data.append(i, inputs[i])
    }

    var params = {
      url: url, 
      method: 'POST', 
      serialize: function(data) {return data},
      data: data,
      deserialize: function(value) {return value},
    }

    if (json)
      params.deserialize = function(data){return JSON.parse(data)}


    return rbbt.insist_request(params, deferred).then(this.result)
  }.bind(this)
  
  this.issue = function(){
    var deferred = m.deferred()
    
    if (this.jobname() !== undefined){
      deferred.resolve(this.jobname())
      return deferred.promise
    }

    var url = '/' + workflow + '/' + task

    var data = new FormData()
    data.append("_format", 'jobname')
    data.append("_cache_type", 'async')
    for (i in inputs){
      data.append(i, inputs[i])
    }

    var params = {
      url: url, 
      method: 'POST', 
      serialize: function(data) {return data},
      data: data,
      deserialize: function(value) {return value},
    }

    return rbbt.insist_request(params).then(this.jobname).then(deferred.resolve, deferred.reject)
  }.bind(this)

  this.load = function(json){
    var deferred = m.deferred()

    if (this.result() !== undefined){
      deferred.resolve(this.result())
      return deferred.promise
    }

    if (json)
      var url = add_parameter(this.jobURL(), '_format','json')
    else
      var url = add_parameter(this.jobURL(), '_format','raw')

    var data = new FormData()
    data.append("_format", 'raw')

    var params = {
      url: url, 
      method: 'GET', 
      serialize: function(data) {return data},
      deserialize: function(value) {return value},
    }

    if (json)
      params.deserialize = function(data){return JSON.parse(data)}

    return rbbt.insist_request(params, deferred).then(this.result)
  }.bind(this)

  this.get_info = function(){
    var deferred = m.deferred()

    if (this.info() !== undefined && (this.info().status == 'done' || this.info().status == 'error' || this.info().status == 'aborted')){
      deferred.resolve(this.info())
      return deferred.promise
    }

    var url = add_parameter(this.jobURL() + '/info', '_format','json')

    var params = {
      url: url, 
      method: 'GET', 
      serialize: function(data) {return data},
      //deserialize: function(value) {return value},
    }

    return rbbt.insist_request(params, deferred).then(this.info)
  }.bind(this)

  this.join = function(deferred, timeout){
    if (undefined === deferred) deferred = m.deferred()
    if (undefined === timeout) timeout = 1000
    if (timeout > 5000) timeout = 5000

    this.get_info().then(function(info){
      var status = info.status
      switch(status){
        case "done":
        case "error":
        case "aborted":
          deferred.resolve(info)
          break;
        default:
          setTimeout(function(){this.join(deferred, timeout*1.5)}.bind(this), timeout)
      }
    }.bind(this))

    return deferred.promise
  }.bind(this)

  this.run = function(json){
    var deferred = m.deferred()

    this.issue().then(function(){
      this.join().then(function(){ this.load(json).then(deferred.resolve, deferred.reject) }.bind(this))
    }.bind(this))

    return deferred.promise
  }.bind(this)

  this.produce = function(){
    var deferred = m.deferred()

    this.issue().then(function(){
      this.join().then(deferred.resolve, deferred.reject)
    }.bind(this))

    return deferred.promise
  }.bind(this)

  this.success = function(callback){
    return this.run()
  }.bind(this)

  this.error = function(callback){
    return this.run().then(null, callback)
  }.bind(this)

}

rbbt.job = function(workflow, task, inputs,json){
  var job = new rbbt.Job(workflow, task, inputs)
  return job.run(json)
}

rbbt_job = function(workflow, task, inputs, json, complete){
  if (undefined === complete && typeof json === 'function'){
    complete = json 
    json = undefined
  }
  rbbt.job(workflow, task, inputs, json).then(complete)
}

rbbt.path_job = function(path){
  var parts = path.split("/")

  var workflow = parts[parts.length-3];
  var task = parts[parts.length-2];
  var name = parts[parts.length-1];

  var dep = new rbbt.Job(workflow, task, {});
  dep.jobname(name);

  return(dep);
}
