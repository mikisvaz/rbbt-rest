
var KB = rbbt.knowledge_base = {}

KB.children = function(database, entity){
 var url = '/kb/user/' + database + '/children/' + entity.id
 url = add_parameter(url, '_format', 'json')
 return m.request({url: url, method: "GET", type: Entity})
}

KB.parents = function(database, entity){
 var url = '/kb/user/' + database + '/parents/' + entity.id
 url = add_parameter(url, '_format', 'json')
 return m.request({url: url, method: "GET", type: Entity})
}

Entity.prototype.children = function(database){
 return KB.children(database, this)
}

Entity.prototype.parents = function(database){
 return KB.parents(database, this)
}


