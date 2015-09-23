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
      rbbt.log("Wrap")
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

    var edges = []
    forHash(associations, function(key,value){
      var source = value[0]
      var target = value[1]
      var source_index = indices[source]
      var target_index = indices[target]
      edges.push({source: source_index, target: target_index, id: key})
    })

    return edges
}

//{{{ BASIC RULES


rbbt.plots.basic_rules = function(study){
  var rules = []
  rules.push({aes:'label', property: 'link', extract: m.trust})
  rules.push({aes:'description', property: 'long_name'})
  rules.push({aes:'highlight', property: 'significant_in_study', args:study})
  rules.push({aes:'order', property: 'damage_bias_in_study', args:study})
  rules.push({aes:'color_class', workflow: 'GEO', task: 'differential', args:{threshold: 0.05, dataset: 'GSE13507', to_gene: true, main:"/Primary/", contrast: "/ontrol/"}, extract: function(result, entity){
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
  rules.push({aes:'color', workflow: 'GEO', task: 'differential', mapper: 'sign-gradient', args:{threshold: 0.05, dataset: 'GSE13507', to_gene: true, main:"/Primary/", contrast: "/ontrol/"}, extract: function(result, entity){
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

rbbt.plots.tile_obj = function(aes){
  var class_names = ""

  if (aes.color_class){
    class_names = class_names + ' ' + aes.color_class
    aes.color_class = undefined
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
  var tile = rbbt.plots.tile_obj(aes)

  var location = {x: aes.x, y: aes.y}
  if (undefined === location.x) location.x = Math.random() * 1000
  if (undefined === location.y) location.y = Math.random() * 1000
  location.width = aes.width
  location.height = aes.height 
  location.requiredExtensions="http://www.w3.org/1999/xhtml"
  location.class="node"

  return m('foreignObject', location, m('body[xmlns="http://www.w3.org/1999/xhtml"]',tile))
}

rbbt.plots.d3js_graph = function(graph, object){
  var xsize = 300, ysize = 200
  var width = 1200
      height = 800

  var color = d3.scale.category20();

  var svg = d3.select(object)
      .attr("width", "100%")
      .attr("height", height)

  var force = d3.layout.force()
      .charge(-20*xsize)
      .linkDistance(3*xsize)
      .size([width, height])
      .nodes(graph.nodes)
      .links(graph.links)

  force.start()
  force.on("tick", function() {
    link.attr("x1", function(d) { return d.source.x + xsize/2; })
        .attr("y1", function(d) { return d.source.y + ysize/2; })
        .attr("x2", function(d) { return d.target.x + xsize/2; })
        .attr("y2", function(d) { return d.target.y + ysize/2; });

    node.attr("x", function(d) { return d.x; })
        .attr("y", function(d) { return d.y; });
  })

  var link = svg.selectAll(".link")
      .data(graph.links)
    .enter().append("line")
      .attr("class", "link")
      .style("stroke-width", function(d) { return Math.sqrt(d.value); });

  var node = svg.selectAll(".node")
      .data(graph.nodes)
    .enter().append("foreignObject").attr('width',xsize).attr('height',ysize).call(force.drag)
      .attr("class", "node")
      .html(function(d) { return mrender(rbbt.plots.tile_obj(d)) });

  rbbt.log("force:warmup")
  for(i=0; i<100; i++) force.tick()

  rbbt.log("force:panZoom")
  svgPanZoom(object)
}

rbbt.mrender = function(mobj){
  return render(mobj)
}
