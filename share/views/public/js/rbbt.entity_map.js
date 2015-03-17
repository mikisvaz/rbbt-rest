var EntityMap = function(data){
 this.id = data.id
 this.name = data.id
 this.type = data.type
 this.column = data.column

 this.full_type = function(){
  return this.type
 }

 this.url = function(){
  var url = "/entity_map/" + this.full_type() + "/" + this.column + "/" + this.id
  return url
 }

 this.get = function(){ 
  var url = this.url()
  url = add_parameter(url, '_format', 'json')
  return m.request({url: url, method: 'GET'})
 }
}

var FavouriteMaps = function(by_type){
 for (type in by_type){
  this[type] = by_type[type]
 }
}

FavouriteMaps.get = function(){
  return m.request({method: 'GET', url: '/favourite_entity_maps', type: FavouriteMaps, deserialize: FavouriteMaps.deserialize})
}

FavouriteMaps.deserialize = function(data){
  data = JSON.parse(data)
  favourite_maps = {}
  for (type in data){
   var type_data = data[type]
   favourite_maps[type] = {}
   for (column in type_data){
    var column_data = type_data[column]
    for (i in column_data){
     var info = {}
     id = column_data[i]
     info.id = id
     info.column = column
     info.type = type
     favourite_maps[type][id] = new EntityMap(info)
    }
   }
  }
  return favourite_maps
} 
