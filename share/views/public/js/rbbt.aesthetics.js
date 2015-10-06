rbbt.aesthetics = {LS_key: "rbbt.aesthetics"}

var aes_module = rbbt.aesthetics 

aes_module.load = function(){
  this.aesthetics = rbbt.LS.load(this.LS_key)
  if (undefined === this.aesthetics)
    this.aesthetics = []
}.bind(aes_module)

aes_module.store = function(){
 rbbt.LS.store(this.LS_key, this.aesthetics)
}.bind(aes_module)

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
      return get_sign_gradient(aes, 'green', 'white', 'red')
    case 'map':
      return aes.map(function(value){ map_obj[value] })
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

    var args = rule.args
    var extract = rule.extract

    var promise

    if (rule.property){
      promise = list.property(rule.property, args)

      if (undefined === extract){
        promises.push(promise.then(result[aes], rbbt.exception.report))
      }else{
        promises.push(promise.then(function(v){return v.map(extract)}).then(result[aes], rbbt.exception.report))
      }
    }

    if (rule.workflow){
      promise = rbbt.job(rule.workflow, rule.task, args,true)
      if (undefined === extract){
        promises.push(promise.then(result[aes], rbbt.exception.report))
      }else{
        promises.push(m.sync([list.get(), promise]).then(function(res){
          list_info = res[0]
          data = res[1]
          return list_info.entities.map(function(e){ return extract.call(null, data, e) })
        }).then(result[aes], rbbt.exception.report))
      }
    }

    if (rule.knowledge_base){
      if (rule.parents)
        promise = rbbt.knowledge_base.list_parents([rule.parents, rule.knowledge_base].join("@"), list)
      if (rule.children)
        promise = rbbt.knowledge_base.list_children([rule.children, rule.knowledge_base].join("@"), list)
      
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

      if (undefined === extract){
        promises.push(m.sync([list.get(), promise]).then(function(res){
          list_info = res[0]
          data = res[1]
          return list_info.entities.map(function(e){ return data[e] })
        }).then(result[aes]))
      }else{
        promises.push(m.sync([list.get(), promise]).then(function(res){
          list_info = res[0]
          data = res[1]
          return list_info.entities.map(function(e){ return extract.call(null, data, e) })
        }).then(result[aes]))
      }
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

aes_module.add = function(rule){
  aes_module.aesthetics.push(rule)
  aes_module.aesthetics = unique(aes_module.aesthetics)
  aes_module.store()
}

aes_module.apply = function(){
}

//aes_module.add = function(selector, aes, value){
//  var mod = this
//  if (typeof selector == 'function'){ 
//    return selector.then(function(_selector){
//      mod.aesthetics.push({selector: _selector, aes: aes, value: value})
//    })
//  }else{
//    this.aesthetics.push({selector: selector, aes: aes, value: value})
//  }
//}
//
//aes_module.clear_aesthetic = function(aes){
//  var data_key = 'data-aes-' + aesthetic.aes
//
//  $('[' + data_key + ']').attr(data_key, 'none')
//}
//
//aes_module.apply_aesthetic = function(aesthetic){
//
// if (typeof aesthetic.selector == "string"){
//  targets = $(aesthetic.selector)
// }else{
//  var items = aesthetic.selector
//  if (typeof items[0] == 'object') items = $.map(items, function(i){return i.id})
//  targets = $('.entity').filter(function(index){ 
//   var id = $(this).attr('data-entity-id')
//   return items.indexOf(id) >= 0
//  })
// }
//
// var data_key = 'data-aes-' + aesthetic.aes
// targets.attr(data_key, aesthetic.value)
//}
//
//aes_module.apply = function(aesthetic){
// if (undefined === aesthetic)
//  aes_module.aesthetics.map(aes_module.apply_aesthetic)
// else
//  aes_module.apply_aesthetic(aesthetic)
//}
//

aes_module.load()
