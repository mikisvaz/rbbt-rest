rbbt.entity = {}
rbbt.entity_array = {}
rbbt.entity_list = {}

rbbt.entity.property = function(code, type, info, name, args){
  if (info.format && ! type.indexOf(":") < 0){
    type = type + ':' + info.format
  }
  var url = "/entity_property/" + name + "/" + type + "/" + code
  url = add_parameters(url, info)
  if (undefined !== args){ 
    var arg_str
    if (typeof args == 'string'){
      arg_str = args
    }else{
      arg_str = JSON.stringify(args)
    }
    url = add_parameter(url, "args", arg_str)
  }
  return rbbt.insist_request({url: url})
}

rbbt.entity_array.property = function(codes, type, info, name, args){
  var promises = []
  forArray(codes, function(code){
    promises.push(rbbt.entity.property(code,type,info,name,args))
  })
  return m.sync(promises)
}

rbbt.entity_array.property = function(codes, type, info, name, args){
  if (info.format && ! type.indexOf(":") < 0){
    type = type + ':' + info.format
  }
  var url = "/entity_list_property/" + name + "/" + type

  var data = {list: codes.join(","), args: args, info: info}
  return rbbt.post(url, data)
}

rbbt.entity_array.parents = function(codes, type, database){
   var url = '/knowledge_base/user/' + database + '/collection_parents' 
   
   var collection = {}
   collection[type] = codes
   
   var data = {}
   data.collection = collection
   data._format = 'tsv_json'
   
   return rbbt.post(url, data)
}

rbbt.entity_array.children = function(codes, type, database){
   var url = '/knowledge_base/user/' + database + '/collection_parents' 
   
   var collection = {}
   collection[type] = codes
   
   var data = {}
   data.collection = collection
   data._format = 'tsv_json'
   
   return rbbt.post(url, data)
}

rbbt.entity_array.subset = function(database, source, target){
   var url = '/knowledge_base/user/' + database + '/subset' 

   var data = {}
   var source = source.join(",")
   data._format = 'tsv_json'
   data.source = source
   if (target) data.target = target.join(",")

   return rbbt.post(url, data)
}
