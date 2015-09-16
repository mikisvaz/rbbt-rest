
var EntityList = function(data){
 this.id = data.id
 this.name = data.id
 this.type = data.type

 this.full_type = function(){
  return this.type
 }

 this.url = function(){
  var url = "/entity_list/" + this.full_type() + "/" + clean_element(this.id)
  return url
 }

 this.get = function(){ 
  var url = this.url()
  url = add_parameter(url, '_format', 'json')
  return m.request({url: url, method: 'GET'})
 }

 this.get_entities = function(func){
   var result = m.deferred();

   this.get().then(function(list_data){
     var item_values = []
     forArray(list_data.entities, function(entity_code){
       item_values.push(new Entity({code: entity_code, info: list_data.info}))
     })
     result.resolve(item_values)
   })

   return(result.promise)
 }

 this.property = function(name, args){
  var url = "/entity_list_property/" + name + "/" + this.full_type() + "/" + clean_element(this.id)
  if (undefined !== args) 
    if ('string' === typeof args)
      url = add_parameter(url, "args", args)
    else
      url = add_parameter(url, "args", JSON.stringify(args))
  return rbbt.insist_request({url: url})
 }

}

var FavouriteLists = function(by_type){
 for (type in by_type){
  this[type] = by_type[type]
 }
}

FavouriteLists.get = function(){
  return m.request({method: 'GET', url: '/favourite_entity_lists', type: FavouriteLists, deserialize: FavouriteLists.deserialize})
}

FavouriteLists.deserialize = function(data){
  data = JSON.parse(data)
  favourite_lists = {}

  forHash(data, function(type, type_data){
    favourite_lists[type] = {}
    forArray(type_data, function(id){
      var info = {}
      info.id = id
      info.type = type
      favourite_lists[type][id] = new EntityList(info)
    })
  })
  return favourite_lists
} 
