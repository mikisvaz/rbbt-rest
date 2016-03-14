
rbbt.plots.graph.prepare_associations = function(db, associations, info){
  var fields = ['source', 'target']

  forArray(info.fields, function(f,i){
    if (f == 'source') f = 'Source'
    if (f == 'target') f = 'Target'
    fields.push(f)
  })

  var edges = {}
  edges.codes = []
  edges.database = db
  edges.source_type = info.source
  edges.target_type = info.target
  edges.source_info = info.source_entity_options
  edges.target_info = info.target_entity_options
  edges.info = {}
  edges.info.database = db
  edges.info.undirected = info.undirected
  edges.properties = {}
  edges.aes = {}

  for (i in fields)
    edges.info[fields[i]] = []

  forHash(associations, function(code, values){
    edges.codes.push(code)
    for(i in values){
      var field = fields[i]
      var value = values[i]
      edges.info[field].push(value)
    }
  })

  edges.info['source'] = edges.info['source'].map(function(e){return e.replace(new RegExp('-\\.\\.-', 'g'), '~')})
  edges.info['target'] = edges.info['target'].map(function(e){return e.replace(new RegExp('-\\.\\.-', 'g'), '~')})
  edges.aes['source'] = edges.info['source']
  edges.aes['target'] = edges.info['target']
  edges.aes['database'] = db

  return edges
}
rbbt.plots.graph.subset = function(db,source,target){
  var promise = rbbt.entity_array.subset(db,source,target)
  var db_info = KB.database_info(db)
  return m.sync([promise,db_info]).then(function(d){
    var associations = d[0]
    var info = d[1]
    return rbbt.plots.graph.prepare_associations(db, associations, info)
  })
}

rbbt.plots.graph.children = function(db, source, type){
  var promise = rbbt.entity_array.children(source,type,db)
  var db_info = KB.database_info(db)
  return m.sync([promise,db_info]).then(function(d){
    var associations = d[0]
    var info = d[1]
    return rbbt.plots.graph.prepare_associations(db, associations, info)
  })
}

rbbt.plots.graph.parents = function(db, source, type){
  var promise = rbbt.entity_array.parents(source,type,db)
  var db_info = KB.database_info(db)
  return m.sync([promise,db_info]).then(function(d){
    var associations = d[0]
    var info = d[1]
    return rbbt.plots.graph.prepare_associations(db, associations, info)
  })
}
