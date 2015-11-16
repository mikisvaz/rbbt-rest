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

KB.database_info = function(database){
 var url = '/knowledge_base/user/' + database + '/info'
 url = add_parameter(url, '_format', 'json')
 return m.request({url: url, method: "GET"})
}

KB.list_parents = function(database, list){
 return list.get().then(function(list_info){
   var url = '/knowledge_base/user/' + database + '/collection_parents' 

   //url = add_parameter(url, 'collection', JSON.stringify(collection))
   //return m.request({url: url, method: "POST", data:{collection:collection}})
   //url = add_parameter(url, '_format', 'tsv_json')
   //return rbbt.post(url, {collection: collection})
   
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
   collection[list.type] = list_info.entities

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


