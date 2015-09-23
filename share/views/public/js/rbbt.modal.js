

ModalComponent = function(element){
  var component = {}

  component.vm = {
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
      m.redraw()
      update_rbbt()
    }

    ctrl.error = function(content, title){
      this._set(content, title)
      $(this.vm.element).addClass('active')
      $(this.vm.element).addClass('error')
      m.redraw()
      update_rbbt()
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
      return rbbt.insist_request(params).then(function(content){
        $(ctrl.vm.element).removeClass('loading')
        ctrl.show(content, title)
      })
    }

    ctrl.close = function(){
      ctrl.vm.visible(false)
      $(ctrl.vm.element).removeClass('error')
      $(ctrl.vm.element).removeClass('active')
      m.redraw()
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


      var header = [title, rbbt.mview.ibutton({onclick: ctrl.close, class:'small close', style: 'margin-top: -4px'}, m('i.icon.close'))];
      var modal_content = [m('.header', header), m('.content', content)];
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
