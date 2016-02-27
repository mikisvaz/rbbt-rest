rbbt.plots = {}

rbbt.plots.list_plot = function(list, rules, create_obj){
  var component = {}
  component.create_obj = create_obj

  component.vm = {
    list: list,
    rules: rules,

    node_aesthetics: m.prop(),
    update_aesthetics: function(){
      rbbt.log('update-aesthetics')
      //return rbbt.aesthetics.get_list_aesthetics(component.vm.list,component.vm.rules)
      rbbt.aesthetics.get_list_aesthetics(component.vm.list,component.vm.rules)
                 .then(component.vm.node_aesthetics).then(component.vm.update_nodes)
      m.redraw()
    },

    nodes: m.prop(),
    no_layout: m.prop(false),
    update_nodes: function(node_aesthetics){
      rbbt.log('update-nodes')
      var deferred = m.deferred()

      component.vm.list.get().then(function(list_info){
        var aes = list_info.entities.map(function(entity, i){
          var e_aes = {id: entity, index: i}
          forHash(node_aesthetics, function(key, value){
            e_aes[key] = value[i]
          })
          return e_aes
        })
        rbbt.log('update-nodes:done')
        return aes
      }).then(component.vm.nodes).then(component.vm.update_layout).then(deferred.resolve)
      return deferred.promise
    },

    associations: m.prop(),
    graph: function(){
      if (undefined === component.vm.associations() || undefined === component.vm.nodes()) return {links:[],nodes:[]}
      var links = rbbt.plots.association_network(component.vm.nodes(), component.vm.associations())
      var graph = {links: links, nodes: component.vm.nodes()}
      return(graph)
    },
    update_layout: function(nodes){
      rbbt.log('update-layout')

      if (component.vm.no_layout() || undefined === component.vm.associations()){
        var deferred = m.deferred()
        deferred.resolve(nodes)
        return deferred.promise
      }

      rbbt.log('update-layout:force')

      return rbbt.plots.force_layout(component.vm.graph()).then(function(graph){return graph.nodes})
    },

    init: function(){ 
      rbbt.log('init')
      component.vm.update_aesthetics()
    },
  }

  component.controller = function(){
    var ctrl = this
    this.vm = component.vm;
    this.vm.init()
    this.onunload = function() {
      console.log("unloading component");
    }
  }

  component.wrapper = function(objs){
    if (undefined === objs){
      rbbt.log("Loading")
      return m('.ui.basic.segment.plot.loading', "Loading")
    }else{
      rbbt.log("Drawing")
      return m('.ui.basic.segment.plot', objs)
    }
  }

  component.view = function(ctrl){
    rbbt.log('View')
    if (ctrl.vm.nodes()){
      var objs = ctrl.vm.nodes().map(function(aes,i){
        return component.create_obj(aes)
      })
      return component.wrapper(objs)
    }else{
      return component.wrapper()
    }
  }

  return component;
}

//{{{ PLOTS

//{{{ FORCE LAYOUT

rbbt.plots.force_layout = function(graph){
  var deferred = m.deferred()
  m.startComputation()
  rbbt.log("force-start")
  var force = d3.layout.force()
    .charge(-5200)
    .linkDistance(5000)
    .size([10000, 10000])
    .nodes(graph.nodes)
    .links(graph.links)
    .start();

  force.on("end", function() {
    m.endComputation()
    rbbt.log("force-end")
    deferred.resolve(graph)
  })
  return deferred.promise
}

rbbt.plots.association_network = function(nodes, associations){
    var indices = {}
    for (i = 0; i < nodes.length; i++){
      var entity = nodes[i]
      indices[entity.id] = i
    }

    var links = []
    forHash(associations, function(key,value){
      var source = value[0]
      var target = value[1]
      var source_index = indices[source]
      var target_index = indices[target]
      links.push({source: source_index, target: target_index, id: key, values: value})
    })

    return links
}

//{{{ BASIC RULES


rbbt.plots.basic_rules = function(study){
  var rules = []
  rules.push({aes:'label', property: 'link', extract: m.trust})
  rules.push({aes:'description', property: 'long_name'})
  rules.push({aes:'highlight', property: 'significant_in_study', args:study})
  rules.push({aes:'order', property: 'damage_bias_in_study', args:study})
  rules.push({aes:'color_class', workflow: 'GEO', task: 'differential', 
             args:{threshold: 0.05, dataset: 'GSE13507', to_gene: true, main:"/Primary/", contrast: "/ontrol/"},
             extract: function(result, entity){
              if (undefined === result[entity]) return ""
              var pvalue = result[entity][result[entity].length-1]
              if (pvalue > 0 && pvalue < 0.05){
                return "green"
              }else{
                if (pvalue < 0 && pvalue > -0.05){
                  return "red"
                }else{
                  return ""
                }
              }
  }})
  rules.push({aes:'color', workflow: 'GEO', task: 'differential', mapper: 'sign-gradient', 
             args:{threshold: 0.05, dataset: 'GSE13507', to_gene: true, main:"/Primary/", contrast: "/ontrol/"}, 
             extract: function(result, entity){
              if (undefined === result[entity]) return ""
              var pvalue = result[entity][result[entity].length-1]
              return pvalue_score(pvalue)
  }})

  return rules
}

rbbt.plots.svg_wrapper = function(objs){
  if (undefined === objs){
    return m(".ui.basic.segment.loading", "Loading")
  }else{
    var cell_svg = m('image',{"xlink:href": 'https://upload.wikimedia.org/wikipedia/commons/1/1a/Biological_cell.svg',x:0,y:0,height:100, width:100})
    objs.unshift(cell_svg)
    return m("svg[height='800px'][width='100%'][viewPort='0 0 10000 10000'][xmlns:xlink='http://www.w3.org/1999/xlink']",{config: svgPanZoom}, objs)
  }
}

rbbt.plots.card_obj = function(aes){
  var class_names = ""
  var style = jQuery.extend({}, aes);

  if (style.color_class){
    class_names = class_names + ' ' + style.color_class
    style.color_class = undefined
  }

  var title = aes.label
  if (aes.highlight)
    title = [m('i.icon.star',{style:"display:inline;font-size:1em"}), title]

  var content = aes.description

  var header = m('.ui.header', title)
  var colors = m('.ui.segment', {"style":"background-color:" + aes.color})
  aes.color = undefined
  var body = m('.ui.description',[content, colors])

  return m('.tile.ui.segment', {style: aes, class: class_names}, 
    [header, body]
  )
}

rbbt.plots.svg_obj = function(aes){
  aes.width = '300px'
  aes.height = '200px'
  var tile = rbbt.plots.card_obj(aes)

  var location = {x: aes.x, y: aes.y}
  if (undefined === location.x) location.x = Math.random() * 1000
  if (undefined === location.y) location.y = Math.random() * 1000
  location.width = aes.width
  location.height = aes.height 
  location.requiredExtensions="http://www.w3.org/1999/xhtml"
  location.class="node"

  return m('foreignObject', location, m('body[xmlns="http://www.w3.org/1999/xhtml"]',tile))
}

rbbt.plots.d3js_graph = function(graph, object, node_obj){
  var xsize = 40, ysize = 40
  var width = 1000
      height = 500

  var color = d3.scale.category20();

  forArray(graph.nodes, function(node){node.width=40; node.height=40})

  var svg = d3.select(object)
      .attr("width", "100%")
      .attr("height", height)

  var force = cola.d3adaptor()
      .linkDistance(3*xsize)
      .avoidOverlaps(true)
      .size([width, height])
      .nodes(graph.nodes)
      .links(graph.links)
      .start()

  force.on("tick", function() {
    link.attr("x1", function(d) { return d.source.x + 0*xsize/2; })
        .attr("y1", function(d) { return d.source.y + 0*ysize/2; })
        .attr("x2", function(d) { return d.target.x + 0*xsize/2; })
        .attr("y2", function(d) { return d.target.y + 0*ysize/2; });

    node.attr("transform", function(d) { return 'translate('+d.x+','+d.y+')'; })
  })

  var link = svg.selectAll(".link").data(graph.links).enter()
      .append("line").attr("class", "link")
        .style("stroke-width", 5).style('stroke', 'grey')

  var node = svg.selectAll(".node").
      data(graph.nodes).
      enter()

  if (undefined === node_obj){
      node = node.append("foreignObject").html(function(d){ 
            return mrender(rbbt.plots.card_obj(d)) 
        }).attr('width',xsize).attr('height',ysize)
  }else{
      node = node_obj(node)
  }

  node.call(force.drag)


  rbbt.log("force:warmup")
  for(i=0; i<100; i++) force.tick()

  rbbt.log("force:panZoom")
  svgPanZoom(object)
}

//{{{{ GROUP GRAPH


rbbt.plots.make_groups = function(graph, nodes, rbbt_groups){
  var groups = []
  var group_indices = {}
  var node_indices = {}
  var index 
  var used_nodes = []
  var links = graph.links

  index = 0
  forArray(nodes, function(node){
    node_indices[node.id] = index
    index = index + 1
  })

  index = 0
  forHash(rbbt_groups, function(term, info){
    var children = info.items
    group_indices[term] = index
    index = index + 1
  })

  var new_links = []
  forHash(rbbt_groups, function(term, info){
    var children = info.items
    var index = group_indices[term]
    var leaves = new Array
    var subgroups = new Array
    forArray(children, function(subterm){
      if (undefined === group_indices[subterm]){
        var node_index = node_indices[subterm]
        if (used_nodes[node_index]){
          var new_index = nodes.length
          var node = nodes[node_index]
          nodes[new_index] = $.extend({},node)
          leaves.push(new_index)
          forArray(used_nodes[node_index], function(prev_index){
            new_links.push({source: prev_index, target: new_index, type: 'move'})
          })
          used_nodes[new_index] = used_nodes[node_index]
          used_nodes[new_index].push(new_index)
        }else{
          leaves.push(node_index)
          used_nodes[node_index] = [node_index]
        }
      }else{
        subgroups.push(group_indices[subterm])
      }
      forArray(links, function(l){
        var orig_source=l.source
        var orig_target=l.target
        var sources = used_nodes[orig_source]
        var targets = used_nodes[orig_target]
        forArray(sources, function(source){
            forArray(targets, function(target){
                if (leaves.indexOf(source) > 0 && leaves.indexOf(target) > 0){
                    var new_link = merge_hash({},l)
                    new_link.source = source
                    new_link.target = target
                    new_links.push(new_link)
                }
            })
        })
      })
    })
    group_info = {leaves: leaves, groups: subgroups, name: info.name, id: info.id}
    groups[index] = group_info
  })

  graph.groups = groups
  graph.links = new_links

  return graph
}


rbbt.plots.d3js_group_graph = function(graph, object, node_obj){
  var xsize = 300, ysize = 200, pad = 20
  var width = 1200
      height = 800

  forArray(graph.nodes, function(node){ node.height = ysize + 2*pad; node.width=xsize + 2*pad})
  var color = d3.scale.category20();

  console.log(graph)

  var svg = d3.select(object)
      .attr("width", "100%")
      .attr("height", height)

  var force = cola.d3adaptor()
      .linkDistance(3*xsize)
      .avoidOverlaps(true)
      .size([width, height])
      .nodes(graph.nodes)
      .links(graph.links)
      .groups(graph.groups)
      .start(0,0,0)

  rbbt.log("force:warmup")
  for(i=0; i<100; i++) force.tick()
  rbbt.log("force:warmup done")

  var stop = false
  var e 
  if (stop) e = 'end'
  else e = 'tick'

  force.on(e, function() {
    link.attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

    node.attr("x", function(d) { return d.x - (pad+xsize) / 2; })
        .attr("y", function(d) { return d.y - (pad+ysize) / 2; });

    group.attr("x", function (d) { return d.bounds.x - pad/4; })
         .attr("y", function (d) { return d.bounds.y - pad/4; })
         .attr("width", function (d) { return d.bounds.width() - pad/2; })
         .attr("height", function (d) { return d.bounds.height() - pad/2; });
  
    if (stop){
      rbbt.log("force:panZoom")
      svgPanZoom(object, {minZoom: 0, maxZoom: 1000})
    }
  })

  force.on('end', function() {
      d3cola.prepareEdgeRouting(margin / 3);
      link.attr("d", function (d) { return lineFunction(d3cola.routeEdge(d)); });
      if (isIE()) link.each(function (d) { this.parentNode.insertBefore(this, this) });
  })

  var group = svg.selectAll(".group")
      .data(graph.groups)
    .enter().append("rect")
      .attr("rx", 8).attr("ry", 8)
      .attr("class", "group")
      .style("fill", function (d, i) { return color(i); });

  group.append('title').text(function(d){return d.name})
  var link = svg.selectAll(".link").data(graph.links).enter()
      .append("line").attr("class", "link")
        .style("stroke-width", 7)
        .style("stroke", function(l){
          if (l.type && l.type == 'move')
            return 'green'
          else
            return 'gray'
        })
        .style("stroke-dasharray", function(l){
          if (l.type && l.type == 'move')
            return '20,10,5,5,10'
          else
            return undefined
        })

  var node = svg.selectAll(".node").data(graph.nodes).enter()
      .append("foreignObject").attr("class", "node").attr('width',xsize).attr('height',ysize)
      .html(function(d){ 
          if (undefined == node_obj)
              return mrender(rbbt.plots.card_obj(d)) 
          else
              return node_obj(d)
      })
      .call(force.drag)

  //var node = svg.selectAll(".node").data(graph.nodes).enter()
  //    .append("rect").attr("class", "node")
  //    .attr('height', ysize)
  //    .attr('width', xsize)
  //    .attr('fill', 'white')
  //    .call(force.drag)

  if (stop){
    force.stop()
  }else{
    rbbt.log("force:panZoom")
    svgPanZoom(object, {minZoom: 0, maxZoom: 1000})
  }

  rbbt.log("force:done")
}


