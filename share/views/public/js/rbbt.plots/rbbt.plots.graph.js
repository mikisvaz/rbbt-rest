rbbt.plots.graph = {}

rbbt.plots.graph.get_entities = function(graph_model){

  if (undefined !== graph_model.entities) return graph_model

  var entities = {}
  forHash(graph_model.associations, function(database, list){
    var source_type = list.source_type
    var source_entities = {}
    source_entities.codes = unique(list.info.source)
    source_entities.info = list.source_info
    source_entities.type = list.source_type

    var target_type = list.target_type
    var target_entities = {}
    target_entities.codes = unique(list.info.target)
    target_entities.info = list.target_info
    target_entities.type = list.target_type

    if (entities[source_entities.type])
      entities[source_entities.type].codes = unique(entities[source_entities.type].codes.concat(source_entities.codes))
    else
      entities[source_entities.type] = source_entities

    if (entities[target_entities.type])
      entities[target_entities.type].codes = unique(entities[target_entities.type].codes.concat(target_entities.codes))
    else
      entities[target_entities.type] = target_entities
  })

  graph_model.entities = entities

  return graph_model
}

rbbt.plots.graph.update_aes = function(graph_model){
  var data_promises = []
  forHash(graph_model.entities, function(type, list){
    data_promises.push(

      rbbt.plots.aes.get_properties(list, graph_model.rules).
        then(function(){
      rbbt.plots.aes.set_aes(list, graph_model.aes_rules)
        })

    )
  })

  forHash(graph_model.associations, function(db, list){
    data_promises.push(

      rbbt.plots.aes.get_properties(list, graph_model.edge_rules).
        then(function(){
      rbbt.plots.aes.set_aes(list, graph_model.edge_aes_rules)
        })

    )
  })
  return m.sync(data_promises).then(function(){return graph_model})
}

//{{{ CONSOLIDATION

rbbt.plots.graph.consolidate_list = function(list){
  var nodes = []

  var codes = list.codes
  var info = list.info
  var aes = list.aes
  var properties = list.properties

  for (i in codes){
    var node = {}
    node.code = codes[i]
    node.id = codes[i]
    forHash(aes, function(name, values){
      var value
      if (typeof values == 'object') value = values[i]
        else value = values
          node[name]  = value
    })
    nodes.push(node)
  }

  return nodes
}

rbbt.plots.graph.consolidate_associations = function(list){
  var nodes = []

  var codes = list.codes
  var info = list.info
  var aes = list.aes
  var properties = list.properties
  var values = list.properties

  for (i in codes){
    var node = {}
    node.code = codes[i]
    forHash(aes, function(name, values){
      var value
      if (typeof values == 'object') value = values[i]
        else value = values
          node[name]  = value
    })
    nodes.push(node)
  }

  return nodes
}

rbbt.plots.graph.consolidate = function(graph_model){
  var model = {}

  var nodes = []

  forHash(graph_model.entities, function(type, list){
    var list_nodes = rbbt.plots.graph.consolidate_list(list)
    for (i in list_nodes) nodes.push(list_nodes[i])
  })

  var edges = []
  forHash(graph_model.associations, function(database, list){
    var list_edges = rbbt.plots.graph.consolidate_associations(list,database)
    for (i in list_edges) edges.push(list_edges[i])
  })

  model.nodes = nodes
  model.edges = edges

  return model
}

rbbt.plots.graph.update = function(graph_model){
  graph_model = rbbt.plots.graph.get_entities(graph_model)
  return rbbt.plots.graph.update_aes(graph_model)
}
