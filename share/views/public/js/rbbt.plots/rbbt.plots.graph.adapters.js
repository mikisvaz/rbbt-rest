rbbt.plots.graph.build_d3 = function(graph_model){

  var model = rbbt.plots.graph.consolidate(graph_model)

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

rbbt.plots.graph.build_cytoscape = function(graph_model){
  var model = rbbt.plots.graph.consolidate(graph_model)

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

rbbt.plots.graph.build_cytoscapejs = function(graph_model){
  var model = rbbt.plots.graph.consolidate(graph_model)

  var nodes = []
  forArray(model.nodes, function(node){
    var clean = clean_hash(node)
    if (undefined === clean.id) clean.id = clean.code
    nodes.push({data: clean})
  })

  var edges = []
  forArray(model.edges, function(edge){
    var clean = clean_hash(edge)
    if (undefined === clean.id) clean.id = clean.code
    clean.id = clean.code + "@" +  clean.database
    edges.push({data: clean})
  })

  var cy_model = {}
  cy_model.elements = {nodes: nodes, edges: edges}

  return cy_model
}

rbbt.plots.graph.view_cytoscapejs = function(graph_model, elem, style, layout, extra){

  var default_style = [ // the stylesheet for the graph
  // Default values
  {
    selector: 'node',
    style: { 'background-color': 'blue', 'label': 'data(id)' }
  },
  {
    selector: 'edge',
    style: { 'width': 1, 'line-color': 'grey', 'target-arrow-color': '#ccc', 'target-arrow-shape': 'triangle' }
  },
  {
    selector: 'node[label]',
    style: {'label': 'data(label)' }
  },
  {
    selector: 'node[color]',
    style: { 'background-color': 'data(color)' }
  },
  {
    selector: 'node[shape]',
    style: { 'shape': 'data(shape)' }
  },

  {
    selector: 'edge',
    style: { 'curve-style': 'bezier'}
  },
  {
    selector: 'edge[color]',
    style: { 'line-color': 'data(color)',
             'target-arrow-color': 'data(color)'}
  },
  {
    selector: 'edge[opacity]',
    style: { 'opacity': 'data(opacity)'}
  },
  {
    selector: 'edge[width]',
    style: { 'width': 'data(width)'}
  },
  //{
  //  selector: 'edge[target-arrow-shape]',
  //  style: { 'target-arrow-shape': 'data(target-arrow-shape)'}
  //},
  //{
  //  selector: 'edge[target-arrow-color]',
  //  style: { 'target-arrow-color': 'data(target-arrow-color)'}
  //}

  ]

  var default_layout = {
              name: 'cose',
              idealEdgeLength: 100,
              nodeOverlap: 20,
              refresh: 20,
              fit: true,
              padding: 30,
              randomize: false,
              componentSpacing: 100,
              nodeRepulsion: 400000,
              edgeElasticity: 100,
              nestingFactor: 5,
              gravity: 80,
              numIter: 1000,
              initialTemp: 200,
              coolingFactor: 0.95,
              minTemp: 1.0
            }

  if (undefined === style) style = default_style
  if (undefined === layout) layout = default_layout

  var deferred = m.deferred()

  rbbt.plots.graph.update(graph_model).then(function(updated_model){
    var cy_model = rbbt.plots.graph.build_cytoscapejs(updated_model)

    require_js(['/plugins/cytoscapejs/cytoscape.js'], function(){
      var cy_params = {
        container: elem,
        elements: cy_model.elements,
        style: style,
        layout: layout,
      }

      if (undefined !== extra) forHash(extra, function(k,v){ cy_params[k,v] })

      var cy = cytoscape(cy_params)

      cy.layout(layout)

      cy.one('layoutstop', function(){
        deferred.resolve(this)
      })
    })
  }, rbbt.exception.report)

  return deferred.promise
}

rbbt.plots.graph.view_cytoscape = function(graph_model, elem, style, layout, extra){
  rbbt.plots.graph.update(graph_model).then(function(updated_model){
    var dataset = rbbt.plots.graph.build_cytoscape(updated_model)

    require_js(['/js/cytoscape/js/src/AC_OETags.js', '/js/cytoscape/js/src/cytoscapeweb.js', '/js/cytoscape'], function(){
      var win = elem.find('.window')
      if (win.length == 0){
        win = $('<div>').addClass('window').css('height', '500px')
        elem.append(win)
      }
      if (undefined === win.attr('id')) win.attr('id', 'cytoscape_' + Math.ceil(Math.random() * 100000))
      var tool = $(elem).cytoscape_tool({
        knowledge_base: 'user',
        namespace: 'Hsa/feb2014',
        entities: dataset.nodes,
        network: dataset,
        aesthetics: {},

        node_click: function(event){
          var target = event.target;

          for (var i in target.data){
            var variable_name = i;
            var variable_value = target.data[i];
          }

          for (var i in target.data) {
            var variable_name = i;
            var variable_value = target.data[i];
          }

          var url = target.data.url;

          if (url)
            rbbt.modal.controller.show_url(url)
          return(false)
        },

        edge_click: function(event){
          var target = event.target;
          for (var i in target.data){
            var variable_name = i;
            var variable_value = target.data[i];
          }

          var pair = [target.data.source, target.data.target].join("~")
          tool.cytoscape_tool('show_info', "user", target.data.database, pair);

          return(false)
        }

      });

      require_js('/js/controls/context_menu', function(){
        cytoscape_context_menu(tool)
      })

      require_js('/js/controls/placement', function(){
        cytoscape_placement(tool)
      })

      require_js('/js/controls/save', function(){
        cytoscape_save(tool)
      })
      tool.cytoscape_tool('draw');
    })
  })
}

rbbt.plots.graph.update_cytoscape = function(graph_model, elem){
  rbbt.plots.graph.update(graph_model).then(function(updated_model){
    var dataset = rbbt.plots.graph.build_cytoscape(updated_model)
    $(elem).cytoscape_tool({
      entities: dataset.nodes,
      network: dataset
    })
    $(elem).cytoscape_tool('update_network')
  })
}

rbbt.plots.graph.view_d3js_graph = function(graph_model, elem, node_obj){
  rbbt.plots.graph.update(graph_model).then(function(updated_model){
    var dataset = rbbt.plots.graph.build_d3(updated_model)

    if (undefined === node_obj){
      node_obj = function(node){
        var g = node.append('g').attr('class', function(d){ if(undefined === d.shape) d.shape = 'circle'; return "node " + d.shape})
        d3.selectAll('.node.circle').append('circle').attr('fill',function(d){return d.color}).attr('r', 20)
        d3.selectAll('.node.rect').append('rect').attr('fill',function(d){return d.color}).attr('width', 40).attr('height', 40).attr('x', -20).attr('y', -20)
        g.append('text').attr('x',-20).attr('y',-20).text(function(d){if(undefined === d.label) d.label = d.code; return d.label}).fill('black')
        return g
      }
    }

    rbbt.plots.d3js_graph(dataset, elem, node_obj)

  })
}

rbbt.plots.graph.view_mithril = function(graph_model, elem, container_obj, produce_obj){
  return rbbt.plots.graph.update(graph_model).then(function(updated_model){
    var obj = $(elem)[0]
    var component = {view: rbbt.curry(rbbt.plots.mithril, graph_model, container_obj, produce_obj)}
    rbbt.mount(obj, component)
  })
}
