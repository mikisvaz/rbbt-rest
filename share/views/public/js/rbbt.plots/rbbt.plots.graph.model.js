rbbt.graph_model = function(){
  var obj = {}

  obj.entities = {}
  obj.associations = {}
  obj.rules = []
  obj.aes_rules = []
  obj.edge_rules = []
  obj.edge_aes_rules = []

  var prot = {}
  
  prot._collect_values = function(values, codes){
    var res = [];
    forArray(codes, function(code){
      if (typeof values === 'function'){
        res.push(values(code))
      }else{
        res.push(values[code])
      }
    })
    return res
  }

  //{{{ Add elements
  
  prot.set_entities = function(codes, type, info){
    if (undefined === type) type = "Entity"
    if (undefined === info) info = {}

    this.entities[type] = {codes: codes, info: info, properties: {}, aes: {}}
  }

  prot.set_associations = function(codes, db, info){
    if (undefined === db) db = "network"
    if (undefined === info) info = {}

    var list = {codes: codes, info: info}
    this.associations[db] = rbbt.plots.aes.complete_source_target(list)
  }

  //{{{ Add rules
  
  prot.add_rule = function(rule){
    this.rules.push(rule)
  }

  prot.add_aes_rule = function(rule){
    this.aes_rules.push(rule)
  }

  prot.add_edge_rule = function(rule){
    this.edge_rules.push(rule)
  }

  prot.add_edge_aes_rule = function(rule){
    this.edge_aes_rules.push(rule)
  }

  //{{{ Add info

  prot.add_property = function(values, name, type){
    if (undefined === type) type = "Entity"
    if (undefined === this.entities[type].properties) this.entities[type].properties = {}

    this.entities[type].properties[name] = this._collect_values(values, this.entities[type].codes)
  }

  prot.add_aes = function(values, name, type){
    if (undefined === type) type = "Entity"
    if (undefined === this.entities[type].aes) this.entities[type].aes = {}

    this.entities[type].aes[name] = this._collect_values(values, this.entities[type].codes)
  }

  prot.add_edge_property = function(values, name, db){
    if (undefined === db) db = "network"
    if (undefined === this.associations[db].properties) this.associations[db].properties = {}

    this.associations[db].properties[name] = this._collect_values(values, this.associations[db].codes)
  }

  prot.add_edge_aes = function(values, name, db){
    if (undefined === db) db = "network"
    if (undefined === this.associations[db].aes) this.associations[db].aes = {}

    this.associations[db].aes[name] = this._collect_values(values, this.associations[db].codes)
  }

  obj.__proto__ = prot

  return obj
}

