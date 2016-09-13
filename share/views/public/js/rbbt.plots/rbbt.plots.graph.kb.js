
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

  edges.source_type = info.source_type
  edges.target_type = info.target_type
  edges.source_format = info.source
  edges.target_format = info.target
  if (undefined === edges.source_type || null === edges.source_type) edges.source_type = edges.source_format
  if (undefined === edges.target_type || null === edges.target_type) edges.target_type = edges.target_format

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

rbbt.plots.graph.filter_associations = function(associations,func){
  var good = [];
  var good_codes = [];
  var codes = associations.codes
  var source = associations.source
  var target = associations.target
  var length = codes.length
  var info = associations.info
  var aes = associations.aes

  var fields = Object.keys(info)
  var aes_fields = Object.keys(aes)

  aes_fields = remove_from_array(aes_fields, 'database')
  fields = remove_from_array(fields, 'database')
  fields = remove_from_array(fields, 'undirected')

  for (i = 0; i < length; i++){
    var a_info = {};
    for (f in fields){
      var field = fields[f];
      a_info[field] = info[field][i];
    }

    if (func(a_info)){
      good.push(i);
      good_codes.push(codes[i]);
    }
  }

  var good_info = {}
  for (f in fields){
    var field = fields[f];
    good_info[field] = []
    for (p = 0; p < good.length; p++){
      var i = good[p];
      good_info[field].push(info[field][i])
    }
  }
  var good_aes = {}
  for (f in aes_fields){
    var field = aes_fields[f];
    good_aes[field] = []
    for (p = 0; p < good.length; p++){
      var i = good[p];
      good_aes[field].push(aes[field][i])
    }
  }

  associations.codes = good_codes
  associations.info = good_info
  associations.aes = good_aes
  return associations
}
