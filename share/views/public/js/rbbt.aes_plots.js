rbbt.plots.aes = {}

rbbt.plots.aes.get_properties = function(list, rules){
  if (undefined === rules) rules == []
  if (undefined === list.properties) list.properties = {}
  var promises = []
  forArray(rules, function(rule){
    var name = rule.name
    var extract = rule.extract
    
    if (rule.entity_type && rule.entity_type != list.type) return 

    if (rule.info){
      var property = rule.property
      var deferred = m.deferred()
      var entry = rule.info
      if (undefined === name) name = entry

      var value = list.info[entry]
      if (undefined === value && entry == 'type') value = list.type
      if (undefined === value && entry == 'code') value = list.codes

      deferred.resolve(value)
      promise = deferred.promise
    }

    if (rule.value){
      var property = rule.property
      var deferred = m.deferred()
      deferred.resolve(rule.value)
      promise = deferred.promise
    }

    if (rule.property){
      var property = rule.property
      var args = rule.args
      if (undefined === name) name = property
      promise = rbbt.entity_array.property(list.codes, list.type, list.info, property, args)
      if (extract){ promise = promise.then(function(res){ return res.map(extract)}) }
    }

    if (rule.workflow){
      var workflow = rule.workflow
      var task = rule.task
      var args = rule.args
      if (undefined === name) name = task
      promise = rbbt.job(workflow, task, args, true)
      if (extract){ promise = promise.then(function(res){ return list.codes.map(function(code){return extract.call(null, res, code)}) } )}
    }

    if (rule.parents || rule.children){
      var kb_type 
      var database
      if (rule.parents){
        kb_type = 'parent'
        var database = rule.parents
        if (undefined === name) name = database

        promise = rbbt.entity_array.parents(list.codes, list.type, database)
      }else{
        kb_type = 'children'
        var database = rule.children
        if (undefined === name) name = database

        promise = rbbt.entity_array.children(list.codes, list.type, database)
      }

      if (rule.field){
        promise = m.sync([promise,rbbt.knowledge_base.database_info(database)]).then(function(res){
          var data = res[0]
          var db_info = res[1]
          var fields = db_info.fields
          var field_pos = fields.indexOf(rule.field)

          if (field_pos < 0){
            var msg = "Field not found: " + rule.field + ". Options: " + fields.join(", ")
            throw new Error(msg)
          }

          var matches = {}
          forHash(data, function(key, values){
            var source = values[0]
            var target = values[1]
            if (matches[source] === undefined) matches[source] = {}
            matches[source][target] = values[field_pos+2]
          })
          return matches
        })
      }else{
        promise = promise.then(function(data){
          var matches = {}
          forHash(data, function(key, values){
            var source = values[0]
            var target = values[1]
            if (matches[source] === undefined) matches[source] = {}
            matches[source][target] = values.slice(2) 
          })
          return matches
        })
      }

      if (extract){
        promise = promise.then(function(matches){
          return list.codes.map(function(e){ 
            return extract.call(null, matches, e)
          })
        })
      }
      else{
        promise = promise.then(function(matches){
          return list.codes.map(function(e){ return matches[e] })
        })
      }
    }

    promises.push(promise.then(function(res){list.properties[name] = res}))
  })

  return m.sync(promises)
}

rbbt.plots.aes.set_aes = function(list, aes_rules){
  if (undefined === list.aes) list.aes = {}
  forArray(aes_rules, function(rule){

    if (rule.entity_type && rule.entity_type != list.type) return 


    var name = rule.name
    var aes = rule.aes
    var mapper = rule.mapper
    var mapper_obj = rule.mapper_obj
    var property = list.properties[name]

    if (rule.value){
      list.aes[aes] = rule.value
      return 
    }

    if (undefined === property && list.info[name]) property = list.info[name]
    if (undefined === property && name == 'type') property = list.type
    if (undefined === property && name == 'code') property = list.codes
    if (undefined === property) return

    list.aes[aes] = aes_module.map_aesthetic(property, mapper, mapper_obj)
  })
}

rbbt.plots.aes.update_aes = function(graph_model){
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
  return m.sync(data_promises)
}

//{{{ SUBSET
rbbt.plots.aes.subset = function(db,source,target){
  var promise = rbbt.entity_array.subset(db,source,target)
  var db_info = KB.database_info(db)
  return m.sync([promise,db_info]).then(function(d){
    var associations = d[0]
    var info = d[1]
    var fields = ['source', 'target'].concat(info.fields)

    var edges = {}
    edges.codes = []
    edges.database = db
    edges.source_type = info.source
    edges.target_type = info.target
    edges.source_info = info.source_entity_options
    edges.target_info = info.target_entity_options
    edges.info = {}
    edges.info.database = db
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

    edges.aes['source'] = edges.info['source']
    edges.aes['target'] = edges.info['target']
    edges.aes['database'] = db

    return edges
  })
}

//{{{ CONSOLIDATION

rbbt.plots.aes.consolidate_list = function(list){
  var nodes = []

  var codes = list.codes
  var info = list.info
  var aes = list.aes
  var properties = list.properties

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

rbbt.plots.aes.consolidate_associations = function(list, database){
  var edges = []
  forHash(list,function(code, values){
    var edge = {}
    var source_code = values[0]
    var target_code = values[1]

    edge.source = source_code
    edge.target = target_code
    edge.database = database

    edges.push(edge)
  })

  return edges
}

rbbt.plots.aes.consolidate_associations = function(list){
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

rbbt.plots.aes.consolidate = function(graph_model){
  var model = {}

  var nodes = []

  forHash(graph_model.entities, function(type, list){
    var list_nodes = rbbt.plots.aes.consolidate_list(list)
    for (i in list_nodes) nodes.push(list_nodes[i])
  })

  var edges = []
  forHash(graph_model.associations, function(database, list){
    var list_edges = rbbt.plots.aes.consolidate_associations(list,database)
    for (i in list_edges) edges.push(list_edges[i])
  })

  model.nodes = nodes
  model.edges = edges

  return model
}

//}}} CONSOLIDATION


rbbt.plots.aes.build_d3 = function(graph_model){

  var model = rbbt.plots.aes.consolidate(graph_model)

  var node_index = {}
  for (i=0; i< model.nodes.length; i++) node_index[model.nodes[i].code] = i

  for (i=0; i< model.edges.length; i++){
    var edge = model.edges[i]
    edge.source = node_index[edge.source]
    edge.target = node_index[edge.target]
  }

  model.links = model.edges
  model.edges = undefined
  model.node_index = node_index

  return model
}

rbbt.plots.aes.build_cytoscape = function(graph_model){
  var model = rbbt.plots.aes.consolidate(graph_model)

  var dataSchema = {nodes: [], edges:[]}

  var node_vars = {}
  for (i in model.nodes){
    for (p in model.nodes[i]){
      if (undefined !== model.nodes[i][p])
        node_vars[p] = typeof model.nodes[i][p]
    }
  }
  for (p in node_vars){
    dataSchema.nodes.push({name: p, type: node_vars[p]})
  }

  node_vars = {}
  for (i in model.edges){
    for (p in model.edges[i]){
      if (undefined !== model.edges[i][p])
        node_vars[p] = typeof model.edges[i][p]
    }
  }
  for (p in node_vars){
    dataSchema.edges.push({name: p, type: node_vars[p]})
  }

  var cy_model = {}
  cy_model.dataSchema = dataSchema
  cy_model.data = model

  return cy_model
}

rbbt.plots.aes.build_cytoscapejs = function(graph_model){
  var model = rbbt.plots.aes.consolidate(graph_model)

  var nodes = []
  forArray(model.nodes, function(node){
    nodes.push({data: node})
  })

  console.log(model.edges)
  var edges = []
  forArray(model.edges, function(edge){
    edges.push({data: edge})
  })

  var cy_model = {}
  cy_model.elements = {nodes: nodes, edges: edges}

  console.log(cy_model)
  return cy_model
}

