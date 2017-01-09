var Entity = function(data){
 this.code = data.code

 if (data.name !== undefined)
  this.name = data.name
 else
  this.name = data.code

 this.type = data.type
 this.format = data.format

 if (undefined === data.info)
   this.info = {}
 else
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

 this.property = function(name, args){
  var url = "/entity_property/" + name + "/" + this.full_type() + "/" + this.code
  url = add_parameters(url, this.link_info())
  if (undefined !== args) url = add_parameter(url, "args", JSON.stringify(args))
  return rbbt.insist_request({url: url})
 }

 this.highlight = function(color){
   var id = this.code
   var links = $('.entity[id=' + id + ']')
   forArray(links, function(link){
     link.prepend($('span').addClass('bullet').addClass(color))
   })
 }

 this.get_elems = function(){
   if (undefined === this.elems && this.elem) this.elems = $([this.elem])
   if (undefined === this.elems) this.elems = $('.entity[data-entity-id=' + this.code +']')
   return this.elems 
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

  forHash(data, function(type, type_data){
    favourite_entities[type] = {}
    forHash(type_data, function(code, info){
      info.code = code
      info.type = type
      favourite_entities[type][code] = new Entity(info)
    })
  })
  return favourite_entities
} 

FavouriteEntities.get = function(){
  return m.request({method: 'GET', url: '/favourite_entities', type: FavouriteEntities, deserialize: FavouriteEntities.deserialize})
}

