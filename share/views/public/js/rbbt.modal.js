
ModalComponent = function(element){
  var component = {}

  component.vm = {
    url: undefined,
    element: element,
    init: function(){ 
      this.visible = m.prop(false)
      this.content = m.prop("")
      this.title = m.prop("")
    }
  }

  component.controller = function(){
    var ctrl = component.controller
    ctrl.vm = component.vm;
    ctrl.vm.init();

    ctrl._set = function(content, title){
      this.vm.content(content)
      if (undefined !== title)
        this.vm.title(title)
      else
        this.vm.title("")
      this.vm.visible(true)
    }

    ctrl.show = function(content, title){
      this._set(content, title)
      $(this.vm.element).addClass('active')
      ctrl.vm.url = undefined
      m.redraw()
    }

    ctrl.error = function(content, title){
      this._set(content, title)
      $(this.vm.element).addClass('active')
      $(this.vm.element).addClass('error')
      m.redraw()
    }

    ctrl.show_url = function(url, title){
      if (typeof url == 'string') params = {url: url, method: 'GET',deserialize: function(v){return v}}
      else params = url

      this.vm.visible(true)
      this.vm.title("loading")
      this.vm.content(m('.ui.loading.basic.segment'))
      $(this.vm.element).addClass('loading')
      $(this.vm.element).addClass('active')
      m.redraw()
      ctrl.vm.url = url
      return rbbt.insist_request(params).then(function(content){
        $(ctrl.vm.element).removeClass('loading')
        ctrl.show(content, title)
        ctrl.vm.url = url
      })
    }

    ctrl.close = function(){
      ctrl.vm.visible(false)
      ctrl.vm.url = undefined
      $(ctrl.vm.element).removeClass('error')
      $(ctrl.vm.element).removeClass('active')
      m.redraw()
    }

    ctrl.link = function(){
      ctrl.close()
      window.location = ctrl.vm.url
    }

    return ctrl
  }

  component.view = function(ctrl){
    if (ctrl.vm.visible()){
      var title
      if ('object' == typeof ctrl.vm.title()) title = ctrl.vm.title();
      else title = m.trust(ctrl.vm.title());

      var content
      if ('object' == typeof ctrl.vm.content()) content = ctrl.vm.content();
      else content = m.trust(ctrl.vm.content());


      var header = [title, close_button];
      var close_button = rbbt.mview.ibutton({onclick: ctrl.close, class:'small close', style: 'margin-top: -4px'}, m('i.icon.close'))
      if (ctrl.vm.url){
        var link_button = rbbt.mview.ibutton({onclick: ctrl.link, class:'small link', style: 'margin-top: -4px'}, m('a', {href: ctrl.vm.url},[ m('i.icon.external')]))
        header = [title, close_button, link_button];
      }else{
        header = [title, close_button];
      }

      var modal_content = [
        m('.header', header),
        m('.content', {config: function(e1,isInit,ctx){ update_rbbt() }}, content)
      ];
      return modal_content;
    }else{
      return "";
    }
  }


  return component;
}

if (document.getElementById('modal')){
  rbbt.modal = new ModalComponent(document.getElementById('modal'))

  m.mount(document.getElementById('modal'), rbbt.modal)
}
