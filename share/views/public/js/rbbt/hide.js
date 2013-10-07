$.widget("rbbt.hide_toggle", {
 options: {
 },

 _create: function() {
   var tool = this
   var element = this.element
   if (this.options.title === undefined){  this.options.title = element.attr('hide-title') }
   if (this.options.title === undefined){  this.options.title = "toggle" }

   var button = this.options.button = $('<a>').addClass('hide_toggle').html(this.options.title)

   button.click(function(){ tool.toggle(); update_rbbt(); return false })
   if (this.options.container !== undefined){
     $(this.options.container).first().append(button)
   }
   this.hide()
 },

 _swap: function(){
   this.options.saved = this.element.html()
   this.element.html(this.options.button)
 },

 _restore: function(){
   this.element.html(this.options.saved)
 },


 hide: function(){
   var tool = this;
   this.element.addClass('hidden').removeClass('shown')
   this.options.button.addClass('hidden').removeClass('shown')

   if (this.options.container === undefined){ this._swap(); }
 },

 show: function(){
   if (this.options.container === undefined){ 
     this._restore(); 
   }else{
     $(this.options.container).find('.hide_toggle.shown').trigger('click')
   }
   this.element.addClass('shown').removeClass('hidden')
   this.options.button.addClass('shown').removeClass('hidden')
 },

 toggle: function(){
   if (this.element.hasClass('shown')){
     this.hide();
   }else{
     this.show();
   }
 }

})

$('#top_menu > ul > li.hide').hide_toggle({container: '#top_menu li.container'})

$('.sidebar').hide_toggle({container: '#top_menu li.container', title: 'Side'})
