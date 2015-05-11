rbbt.modal = {}
rbbt.modal.element = document.getElementById('modal')

rbbt.modal.vm = (function(){
  var vm = {}
  vm.init = function(){
    vm.visible = m.prop(false)
    vm.content = m.prop("")
    vm.title = m.prop("")
  }

  return vm
}())

rbbt.modal.controller = function(){
  var controller = rbbt.modal.controller
  var vm = rbbt.modal.vm
  vm.init()

  controller.show = function(content, title){
    vm.content(content)
    if (undefined !== title)
      vm.title(title)
    vm.visible(true)
    $(rbbt.modal.element).addClass('active')
    m.redraw()
  }

  controller.show_url = function(url, title){
    if (typeof url == 'string') params = {url: url, method: 'GET',deserialize: function(v){return v}}
    else params = url
    return rbbt.insist_request(params).then(function(content){
      console.log(content)
      controller.show(content, title)
    })
  }

  controller.close = function(){
    vm.visible(false)
    $(rbbt.modal.element).removeClass('active')
    m.redraw()
  }

  return
}

rbbt.modal.view = function(controller){
  if (rbbt.modal.vm.visible()){
    var header = [m.trust(rbbt.modal.vm.title()), rbbt.mview.ibutton({}, m('i.icon.close',{onclick: rbbt.modal.controller.close}))]
    var modal_content = [m('.header', header), m('.content', m.trust(rbbt.modal.vm.content()))]
    return modal_content
  }else{
    return ""
  }
}

if (rbbt.modal.element) m.module(rbbt.modal.element, rbbt.modal)
