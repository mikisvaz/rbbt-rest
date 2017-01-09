rbbt.aesthetics = {LS_key: "rbbt.aesthetics"}

var aes_module = rbbt.aesthetics 

aes_module.map_aesthetic = function(aes, mapper, map_obj){
  switch(mapper){
    case false:
    case undefined:
    case null:
    case 'direct':
      return aes;
    case 'gradient':
      return get_gradient(aes, 'green', 'red')
    case 'sign-gradient':
      return get_sign_gradient(aes, 'green', 'grey', 'red')
    case 'map':
      if (typeof aes == 'object')
        return aes.map(function(value){ return map_obj[value] })
      else
        return map_obj[aes]
    case 'function':
      var res = []
      if (typeof aes == 'object')
        for (i in aes) res.push(map_obj(aes[i]))
      else
        res = map_obj(aes)
      return res
    case 'list_function':
      return map_obj(aes)
  }
}

aes_module.get_list_property = function(list, rule, result) {
  promise = list.property(rule.property, rule.args)

  if (undefined === rule.extract){
    return promise.then(result, rbbt.exception.report)
  }else{
    var extract = rule.extract
    return promise.then(function(v){return v.map(extract)}).then(result, rbbt.exception.report)
  }
}

aes_module.get_list_workflow_job = function(list, rule, result) {
  promise = rbbt.job(rule.workflow, rule.task, rule.args,true)

  if (undefined === rule.extract){
    return promise.then(result, rbbt.exception.report)
  }else{
    var extract = rule.extract
    return m.sync([list.get(), promise]).then(function(res){
      list_info = res[0]
      data = res[1]
      return list_info.entities.map(function(e){ return extract.call(null, data, e) })
    }).then(result, rbbt.exception.report)
  }
}

aes_module.get_list_knowledge_base = function(list, rule, result) {
  var db_code
  var promise
  if (rule.parents){
    var db_code = [rule.parents, rule.knowledge_base].join("@")
    promise = rbbt.knowledge_base.list_parents(db_code, list)
  }

  if (rule.children){
    var db_code = [rule.children, rule.knowledge_base].join("@")
    promise = rbbt.knowledge_base.list_children(db_code, list)
  }

  if (rule.field){
    promise = m.sync([promise,rbbt.knowledge_base.database_info(db_code)]).then(function(res){
      var data = res[0]
      var db_info = res[1]
      var fields = db_info.fields
      var field_pos = fields.indexOf(rule.field)

      if (field_pos < 0){
        var msg = "Field not found: " + rule.field + ". Options: " + fields.join(", ")
        throw new Error(msg)
      }

      var matches = {}
      forHash(data, function(key, values){
        var source = values[0]
        var target = values[1]
        if (matches[source] === undefined) matches[source] = {}
        matches[source][target] = values[field_pos+2]
      })
      return matches
    })

  }else{
    promise = promise.then(function(data){
      var matches = {}
      forHash(data, function(key, values){
        var source = values[0]
        var target = values[1]
        if (matches[source] === undefined) matches[source] = {}
        matches[source][target] = values.slice(2) 
      })
      return matches
    })
  }

  if (undefined === rule.extract){
    return m.sync([list.get(), promise]).then(function(res){
      var list_info = res[0]
      var data = res[1]
      return list_info.entities.map(function(e){ return data[e] })
    }).then(result, function(r){rbbt.exception.report(r[1])})
  }
  else{
    var extract = rule.extract
    return m.sync([list.get(), promise]).then(function(res){
      var list_info = res[0]
      var data = res[1]
      return list_info.entities.map(function(e){ 
        return extract.call(null, data, e)
      })
    }).then(result, function(r){rbbt.exception.report(r[1])})
  }
  
}

aes_module.get_list_aesthetics = function(list, rules) {
  var result = {}
  var promises = []
  var deferred = m.deferred()
  var mappers = {}

  if (undefined === rules) rules = this.aesthetics

  forArray(rules, function(rule){
    var aes = rule.aes
    result[aes] = m.prop()
    mappers[aes] = rule.mapper

    var promise

    if (rule.property){
      promises.push(aes_module.get_list_property(list, rule, result[aes]))
    }

    if (rule.workflow){
      promises.push(aes_module.get_list_workflow_job(list, rule, result[aes]))
    }

    if (rule.knowledge_base){
      promises.push(aes_module.get_list_knowledge_base(list, rule, result[aes]))
    }
  })

  var mapped_result = {}

  m.sync(promises).then(function(){
    forHash(result, function(aes, values){
      var mapper = mappers[aes]
      mapped_result[aes] = rbbt.aesthetics.map_aesthetic(values(), mapper)
    })
    return mapped_result
  }).then(function(){ deferred.resolve(mapped_result) }, rbbt.exception.report)

  return deferred.promise
}

//{{{ HELPERS
aes_module.column_aes = function(aes, column){
  var column_aes = {label: column}
  forHash(aes, function(key, values){
    var m
    if (m = key.match(/^column-(.*)/)){
      var clean_key = m[1]
      if (undefined === values)
        column_aes[clean_key] = undefined
      else
        column_aes[clean_key] = values[column]
    }
  })
  return column_aes
}

//{{{ STORE, LOAD, ADD and APPLY

aes_module.store = function(){
  rbbt.LS.store(this.LS_key, this.aesthetics)
}.bind(aes_module)

aes_module.load = function(){
  this.aesthetics = rbbt.LS.load(this.LS_key)
  if (undefined === this.aesthetics)
    this.aesthetics = []
}.bind(aes_module)

aes_module.add = function(rule){
  aes_module.aesthetics.push(rule)
  aes_module.aesthetics = unique(aes_module.aesthetics)
  aes_module.store()
}

aes_module.apply_aes = function(info){ 
  var elems = info.elems;

  if (undefined === elems && info.targets){
    elems = []
    forArray(info.targets, function(target){ elems = $.merge(elems, target.get_elems()) })
    elems = $(elems)
  }

  if (undefined === elems && info.selector){
    elems = $(info.selector)
  }

  if (info.value == 'remove') elems.css(info.aes, '')
  else elems.css(info.aes, info.value)
}

aes_module.apply = function(){ }


aes_module.load()
