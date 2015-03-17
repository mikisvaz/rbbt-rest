rbbt.entity = {}

var Entity = function(data){
 this.id = data.id
 this.code = data.code

 if (data.name !== undefined)
  this.name = data.name
 else
  this.name = data.code

 this.type = data.type
 this.format = data.format
 this.info = data.info
 if (this.format === undefined && this.info !== undefined) this.format = this.info['format']

 this.full_type = function(){
  var full_type
  if (this.format){ full_type = this.type + ":" + this.format }
  else { full_type = this.type }
  return full_type
 }

 this.link_info = function(){
  var link_info = this.info
  delete link_info['format']
  return link_info
 }
 
 this.url = function(){
  var url = "/entity/" + this.full_type() + "/" + this.code
  url = add_parameters(url, this.link_info())
  return url
 }
}

var FavouriteEntities = function(by_type){
 for (type in by_type){
  this[type] = by_type[type]
 }
}

FavouriteEntities.deserialize = function(data){
  data = JSON.parse(data)
  favourite_entities = {}
  for (type in data){
   var type_data = data[type]
   favourite_entities[type] = {}
   for (code in type_data){
    var info = type_data[code]
    info.code = code
    info.type = type
    favourite_entities[type][code] = new Entity(info)
   }
  }
  return favourite_entities
} 

FavouriteEntities.get = function(){
  return m.request({method: 'GET', url: '/favourite_entities', type: FavouriteEntities, deserialize: FavouriteEntities.deserialize})
}

