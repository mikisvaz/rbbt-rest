rbbt.mview = {}

rbbt.mview.plot = function(content, title, caption){
  var plot 

  if (undefined === title){
    plot = m('figure.ui.segment', m('.header', 'No figure to display'))
  }else{
    if (title == 'loading'){
      plot = m('figure.ui.segment.loading', 'loading figure')
    }else{
      var elems = []
      var img_title = title

      if (! img_title) img_title = 'image'
      else img_title = img_title.replace(': ', ' ')
        
      var img_filename = img_title + '.svg'
      var download_func = function(){
        var blob = new Blob([content], {type: "image/svg+xml;charset=utf-8"});
        return saveAs(blob, img_filename);
      }
      var download = m('.download.ui.labeled.icon.button',{onclick: download_func}, [m('i.icon.download'), "Download"])
      if (title) elems.push(m('.ui.header', title))
      elems.push(m('.content.svg', m.trust(content)))
      if (caption){ 
        elems.push(m('figcaption', m.trust(caption)))
        elems.push(m('hr'))
      }
      if (content) elems.push(download)

      plot = m('figure.ui.segment', elems)
    }

  }

  return plot
}

rbbt.mview.button = function(options,args){
  return m('.ui.button', options, args)
}

rbbt.mview.ibutton = function(options,args){
  return m('.ui.icon.button', options, args)
}

rbbt.mview.select_options = function(options){
  var res = [];
  if (is_array(options)){
    forArray(options, function(option){
      res.push(m('option', {value: option}, option))
    })
  }else{
    forHash(options, function(name, value){
      res.push(m('option', {value: value}, name))
    })
  }
  return res
}

rbbt.mview.select = function(name, options, variable){
  if (variable === undefined){
    return m('select.ui.fluid.dropdown', rbbt.mview.select_options(options))
  }else{
    return m('select.ui.fluid.dropdown', {onchange: m.withAttr("value", variable)}, rbbt.mview.select_options(options))
  }
}

rbbt.mview.dropdown = function(name, options){
 return m('.ui.simple.dropdown.item', [m('i.icon.dropdown'), name, m('.menu', options)])
}

rbbt.mview.input = function(type, value, bind, attrs){
  var input = m('input', {type: type})

  if (value){
    input.attrs[value] = bind.call()
    input.attrs.onchange = m.withAttr(value, bind)
  }

  if (attrs) input.attrs = $.extend({}, input.attrs, attrs)

  return input
}

rbbt.mview.field = function(input, label, change, attrs){
  var field = m('.ui.field')
  if (label){
    var lab = m('label', label)
    if (input.attrs.id) lab.attrs.for = input.attrs.id
    field.children.push(lab)
  }
  if (change){
    input.attrs.onchange = change
  }
  field.children.push(input)

  if (attrs) field.attrs = $.extend({}, field.attrs, attrs)
  return(field)
}

