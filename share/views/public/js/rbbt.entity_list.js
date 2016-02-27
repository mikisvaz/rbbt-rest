
var EntityArray = function(array){
  this.entities = array

  this.get = function(){ 
    var result = m.deferred();

    var codes = []
    for (i in this.entities){
      codes.push(this.entities[i].code)
    }
    type = this.entities[0].type
    format = this.entities[0].format
    info = this.entities[0].info
    result.resolve({entities: codes, entity_type: type, info: info})

    return(result.promise)
  }

  this.get_entities = function(func){
    var result = m.deferred();

    result.resolve(this.entities)

    return(result.promise)
  }


  this.property = function(name, args){
    var result = m.deferred();
    var promises = []

    for (i in this.entities){
      var entity = this.entities[i];
      promises.push(entity.property(name, args))
    }

    m.sync(promises).then(result.resolve)

    return(result.promise)
  }

  this.codes = function(){
  }

  this.children = function(knowledgebase, database){
    var db_key = [database, knowledgebase].join("@")
    return rbbt.knowledge_base.list_children(db_key, this)
  }

  this.parents = function(knowledgebase, database){
    var db_key = [database, knowledgebase].join("@")
    return rbbt.knowledge_base.list_parents(db_key, this)
  }

  this.subset = function(knowledgebase, database){
    var db_key = [database, knowledgebase].join("@")
    return rbbt.knowledge_base.list_subset(db_key, this)
  }
}

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
    if (undefined === this.entities && ! this.loading){
      var url = this.url()
      url = add_parameter(url, '_format', 'json')
      list = this
      this.loading = m.request({url: url, method: 'GET'}).then(this.entities).then(function(x){ list.loading = undefined; return x})
      return this.loading
    }else{
      var deferred = m.deferred()
      if (this.loading)
        this.loading.then(function(x){ deferred.resolve(x)})
      else
        deferred.resolve(this.entities)
      return deferred.promise
    }
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

  this.children = function(knowledgebase, database){
    var db_key = [database, knowledgebase].join("@")
    return rbbt.knowledge_base.list_children(db_key, this)
  }

 this.parents = function(knowledgebase, database){
   var db_key = [database, knowledgebase].join("@")
   return rbbt.knowledge_base.list_parents(db_key, this)
 }

 this.subset = function(knowledgebase, database){
   var db_key = [database, knowledgebase].join("@")
   return rbbt.knowledge_base.list_subset(db_key, this)
 }
}

//{{{ FAVOURITES
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
