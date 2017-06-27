rbbt.plots.mithril = function(graph_model, container_obj, produce_obj){
  var obj_by_type = {}
  forHash(graph_model.entities, function(type, info){
    var codes = info.codes
    var objs = []
    for(i in codes){
      var code = codes[i]
      var obj = produce_obj(code, i, info.aes)
      objs.push(obj)
    }
    obj_by_type[type] = objs
  })

  var container = m('.mitrhil', {config: function(){ update_dom() }}, container_obj(graph_model, obj_by_type))

  return container
}
