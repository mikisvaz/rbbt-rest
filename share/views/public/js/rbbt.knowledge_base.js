var KB = rbbt.knowledge_base = {}

//KB.children = function(database, entity){
// var id = undefined
// if (typeof entity == 'string'){ id = entity}else{id = entity.id}
// var url = '/knowledge_base/user/' + database + '/children/' + id
// url = add_parameter(url, '_format', 'json')
// return m.request({url: url, method: "GET", type: Entity})
//}
//
//KB.parents = function(database, entity){
// var url = '/knowledge_base/user/' + database + '/parents/' + entity.id
// url = add_parameter(url, '_format', 'json')
// return m.request({url: url, method: "GET", type: Entity})
//}

rbbt.step_path = function(path, func){
  if (undefined === path){
    if (typeof step_path == 'string')
      return step_path
    if (rbbt._step_path)
      return rbbt._step_path
    else{
      if (document.step_path)
        return document.step_path
      else
        return undefined
    }
  }else{
    old = rbbt._step_path
    rbbt._step_path = path
  }

  if (undefined === func)
    return
  else{
    func()
    rbbt._step_path = old
  }
}

KB.parse_db = function(database_code){
   var kb = 'user'
   var database

   if (database_code.indexOf(':') > 0){
     var parts = database_code.split(":")
     kb = parts[0]
     database = parts[1]
   }else{
     database = database_code
   }

   if (kb == 'step'){
     var path
     if (typeof step_path != 'undefined') path = step_path
     if (undefined === path) path = rbbt.step_path()
     cookies = {step_path: path}
   }else{
     cookies = undefined
   }

   return [kb, database, cookies]
}

KB.database_info = function(database_code){
  var parts = rbbt.knowledge_base.parse_db(database_code)
  var kb,database,params
  kb = parts[0]; database = parts[1], cookies = parts[2]

  var url = '/knowledge_base/' + kb + '/' + database + '/info' 

  url = add_parameter(url, '_format', 'json')

  params = {url: url, method: "GET", cookies: cookies}

 return rbbt.insist_request(params)
}

KB.list_parents = function(database, list){
 return list.get().then(function(list_info){
   var url = '/knowledge_base/user/' + database + '/collection_parents' 

   var collection = {}
   collection[list.type] = list_info.entities
   
   var data = {}
   data.collection = collection
   data._format = 'tsv_json'
   
   return rbbt.post(url, data)
 })
}

KB.list_children = function(database, list){
 return list.get().then(function(list_info){
   var url = '/knowledge_base/user/' + database + '/collection_children' 

   var collection = {}
   collection[list_info.entity_type] = list_info.entities

   var data = {}
   data.collection = JSON.stringify(collection)
   data._format = 'tsv_json'
   
   return rbbt.post(url, data)
 })
}

KB.list_subset = function(database, list, target){
 return list.get().then(function(list_info){
   var url = '/knowledge_base/user/' + database + '/subset' 

   var data = {}
   var source = list_info.entities.join(",")
   data._format = 'tsv_json'
   data.source = source
   if (target) data.target = target.join(",")

   return rbbt.post(url, data)
 })
}

Entity.prototype.children = function(database){
 return KB.children(database, this)
}

Entity.prototype.parents = function(database){
 return KB.parents(database, this)
}


