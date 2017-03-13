rbbt.plots.aes = {}

rbbt.plots.aes.map_aesthetic = function(aes, mapper, map_obj){
  switch(mapper){
    case false:
    case undefined:
    case null:
    case 'direct':
      return aes;
    case 'gradient':
      if (map_obj){
        if (typeof aes == 'object'){
          aes = aes.map(function(value){ return map_obj[value] })
        }else{
          aes = map_obj[aes]
        }
      }
      return get_gradient(aes, '#EABD5D', '#40324F')
    case 'sign-gradient':
      if (map_obj){
        if (typeof aes == 'object')
          aes = aes.map(function(value){ return map_obj[value] })
        else
          aes = map_obj[aes]
      }
      return get_sign_gradient(aes, '#EABD5D', 'grey', '#40324F')
    case 'map':
      if (typeof aes == 'object')
        return aes.map(function(value){ if (value !== undefined && value != null ) value = value.toString(); return map_obj[value] })
     else
        return map_obj[aes]
    case 'function':
      var res = []
      if (typeof map_obj == 'string') eval("map_obj = " + map_obj)
      if (typeof aes == 'object')
        for (i in aes) res.push(map_obj(aes[i]))
      else
        res = map_obj(aes)
      return res
    case 'list_function':
      return map_obj(aes)
  }
}

rbbt.plots.aes.get_properties = function(list, rules, type, namespace){
  if (undefined !== list.type) type = list.type
  if (undefined === rules) rules == []
  if (undefined === list.properties) list.properties = {}

  if (undefined !== list.info){
    info = list.info
  }else{
    info = {}
  }

  if (list.namespace && undefined === namespace){
    namespace = list.namespace
  }

  if (undefined !== namespace && undefined === list.organism){
    info.organism = namespace
    info.namespace = namespace
  }

  var promises = []
  forArray(rules, function(rule){
    var name = rule.name
    var extract = rule.extract
    if (typeof extract == 'string'){ 
      eval('extract='+extract)
    }
    
    if (rule.entity_type && rule.entity_type != type && rule.entity_type != list.format) return 

    if (rule.info){
      var property = rule.property
      var deferred = m.deferred()
      var entry = rule.info
      if (undefined === name) name = entry

      var value = info[entry]
      if (undefined === value && entry == 'type') value = type
      if (undefined === value && entry == 'code') value = list.codes

      deferred.resolve(value)
      promise = deferred.promise
      if (extract){ 
        promise = promise.then(function(res){ 
          if (typeof res == 'object')
            return res.map(function(elem){ return extract.call(null, elem)}) 
          else
            return extract.call(null, res) 
        }) 
      }
    }
    if (rule.subset){
      var deferred = m.deferred()
      var inclusion = list.codes.map(function(code){ if (rule.subset.indexOf(code) < 0){ return "false"} else { return "true" } })
      deferred.resolve(inclusion)
      promise = deferred.promise
    }

    if (rule.value){
      var property = rule.property
      var deferred = m.deferred()
      deferred.resolve(rule.value)
      promise = deferred.promise
    }

    if (rule.property){
      var property = rule.property
      var args = rule.args
      if (undefined === name) name = property

      var deferred = m.deferred()
      var tmp_promise = rbbt.entity_array.property(list.codes, type, info, property, args)

      if (extract){ tmp_promise = tmp_promise.then(function(res){ return res.map(extract)}) }

      tmp_promise.then(deferred.resolve, function(){ deferred.resolve(undefined)})

      promise = deferred.promise
    }

    if (rule.workflow){
      var workflow = rule.workflow
      var task = rule.task
      var args = rule.args
      if (undefined === name) name = task
      promise = rbbt.job(workflow, task, args, true)
      if (extract){ promise = promise.then(function(res){ return list.codes.map(function(code){return extract.call(null, res, code)}) } )}
    }

    if (rule.parents || rule.children){
      var kb_type 
      var database
      if (rule.parents){
        kb_type = 'parent'
        var database = rule.parents
        if (undefined === name) name = database

        promise = rbbt.entity_array.parents(list.codes, type, database)
      }else{
        kb_type = 'children'
        var database = rule.children
        if (undefined === name) name = database

        promise = rbbt.entity_array.children(list.codes, type, database)
      }

      if (rule.field){
        promise = m.sync([promise,rbbt.knowledge_base.database_info(database)]).then(function(res){
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
            var source,target
            if (rule.parents){ 
              source = values[1]
              target = values[0]
            }else{
              source = values[0]
              target = values[1]
            }
            if (matches[source] === undefined) matches[source] = {}
            matches[source][target] = values.slice(2) 
          })
          return matches
        })
      }

      if (extract){
        promise = promise.then(function(matches){
          return list.codes.map(function(e){ 
            return extract.call(null, matches, e)
          })
        })
      }
      else{
        promise = promise.then(function(matches){
          return list.codes.map(function(e){ return matches[e] })
        })
      }
    }

    promises.push(promise.then(function(res){ if (undefined !== res) list.properties[name] = res}))
  })

  return m.sync(promises)
}

rbbt.plots.aes.set_aes = function(list, aes_rules, type){
  if (undefined !== list.type) type = list.type
  if (undefined === list.aes) list.aes = {}
  forArray(aes_rules, function(rule){

    if (rule.entity_type && rule.entity_type != type) return 


    var name = rule.name
    var aes = rule.aes
    var mapper = rule.mapper
    var mapper_obj = rule.mapper_obj
    var property = list.properties[name]

    if (rule.value){
      list.aes[aes] = rule.value
      return 
    }

    if (undefined === property && undefined !== info && info[name]) property = info[name]
    if (undefined === property && name == 'type') property = type
    if (undefined === property && name == 'code') property = list.codes.slice()
    if (undefined === property) return

    var aes_values = rbbt.plots.aes.map_aesthetic(property, mapper, mapper_obj)

    if (undefined === list.aes[aes]){
      list.aes[aes] = aes_values
    }else{
      for(i in aes_values){
        var v = aes_values[i]
        if (undefined !== v){
          list.aes[aes][i] = v
        }
      }
    }
  })
}
