rbbt.aesthetics = {LS_key: "rbbt.aesthetics"}

var aes_module = rbbt.aesthetics 

aes_module.load = function(){
 this.aesthetics = rbbt.LS.load(this.LS_key)
 if (undefined === this.aesthetics)
  this.aesthetics = []
}

aes_module.store = function(){
 rbbt.LS.store(this.LS_key, this.aesthetics)
}

aes_module.add = function(selector, aes, value){
  var mod = this
  if (typeof selector == 'function'){ 
    return selector.then(function(_selector){
      mod.aesthetics.push({selector: _selector, aes: aes, value: value})
    })
  }else{
    this.aesthetics.push({selector: selector, aes: aes, value: value})
  }
}

aes_module.clear_aesthetic = function(aes){
  var data_key = 'data-aes-' + aesthetic.aes

  $('[' + data_key + ']').attr(data_key, 'none')
}

aes_module.apply_aesthetic = function(aesthetic){

 if (typeof aesthetic.selector == "string"){
  targets = $(aesthetic.selector)
 }else{
  var items = aesthetic.selector
  if (typeof items[0] == 'object') items = $.map(items, function(i){return i.id})
  targets = $('.entity').filter(function(index){ 
   var id = $(this).attr('data-entity-id')
   return items.indexOf(id) >= 0
  })
 }

 var data_key = 'data-aes-' + aesthetic.aes
 targets.attr(data_key, aesthetic.value)
}

aes_module.apply = function(aesthetic){
 if (undefined === aesthetic)
  aes_module.aesthetics.map(aes_module.apply_aesthetic)
 else
  aes_module.apply_aesthetic(aesthetic)
}

aes_module.load()
//aes_module.add(Object.keys(fav_module.entities.types()["Gene"]), 'color', 'red')
//aes_module.store()
//aes_module.apply()
