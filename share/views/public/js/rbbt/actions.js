$.widget("rbbt.action_controller", {

 options: {
  saved: {},
 },

 _dump: function(){
  localStorage['rbbt.action_controller.saved'] = JSON.stringify(this.options.saved)
  localStorage['rbbt.action_controller.bookmarked'] = JSON.stringify(this.options.bookmarked)
 },

 _load: function(){
  if (undefined === localStorage['rbbt.action_controller.bookmarked']){
   this.options.saved = {};
   this.options.bookmarked = []
   this._dump()
  }else{
   this.options.saved = JSON.parse(localStorage['rbbt.action_controller.saved'])
   this.options.bookmarked = JSON.parse(localStorage['rbbt.action_controller.bookmarked'])
  }
 },

 _untrack: function(url){
  this.options.bookmarked = remove_from_array(this.options.bookmarked, url);
  this._dump();
  this._update_jobs();
 },

 _track: function(){
  var url = this._url();
  if ($.inArray(url, this.options.bookmarked) == -1){
   this.options.bookmarked.push(url);
  }
  this._dump();
  this._update_jobs();
 },

 _update_jobs: function(){
  var job_list = $('#top_menu .user ul.jobs')
  job_list.html("")
  for(i in this.options.bookmarked){
   var url = this.options.bookmarked[i];

   var action = url.split('?')[0].split("/")[3]
   var element = url.split('?')[0].split("/")[4]

   action = unescape(action)
   element = unescape(element)
   var name = [action, element].join(" - ");
   var a = $('<a>').attr('href', url).html(name);
   var li = $('<li>').append(a);

   var icon = $('<i class="general foundicon-minus">')
   var remove = $('<a class=remove_element></a>').append(icon)
   li.prepend(remove)

   job_list.append(li);
  }
  this._update_flag()
 },

 _toogle_track: function(){
  console.log(this.element.find('ul.controls > li.url.bookmarked').length)
  if (this.element.find('ul.controls > li.url.bookmarked').length > 0){
   this._untrack(this._url());
  }else{
   this._track();
  }
 },

 _create: function() {
  var tool = this
  var controller = tool.element

  controller.on('click', '> ul.actions  li', function(e){ tool._activate_action(this); return false})
  controller.on('click', '> ul.controls > li.reload', function(e){ tool._reload_action(this); return false})
  controller.on('click', '> ul.controls > li.parameters', function(e){ tool._display_parameters(this); return false})
  controller.on('click', '> ul.controls > li.pin', function(e){ tool._toggle_pin(this); return false})
  controller.on('click', '> ul.controls > li.url', function(e){ tool._toogle_track(this); return false})
  $('#top_menu li.user ul.jobs').on('click', 'a.remove_element', function(){
   var link = $(this).next('a')
   tool._untrack(link.attr('href'))
  })

  this._load();
  this._update_jobs();
 },

 _update_flag: function(){
  if ($.inArray(this._url(), this.options.bookmarked) != -1){
   $(this.element).find('> ul.controls > li.url').addClass('bookmarked')
  }else{
   $(this.element).find('> ul.controls > li.url').removeClass('bookmarked')
  }
 },

 _activate_action: function(e){
  var action_list_item = $(e)
  var action_list = action_list_item.parent('ul.actions');
  var link = action_list_item.find('> a')

  this._load_action(link);

  var action = link.html()
  if (this.options.saved[action] !== undefined){
   $(this.element).find('> ul.controls > li.pin').addClass('saved')
  }else{
   $(this.element).find('> ul.controls > li.pin').removeClass('saved')
  }

  this._update_flag()

  action_list.addClass('selected');

  return false
 },

 _unpin_parameters: function(){
  var controller = $(this.element)
  var action = controller.find('ul.actions li.active a').first().html()
  this.options.saved[action] = undefined
  controller.find('> ul.controls > li.pin').removeClass('saved')
 },

 _pin_parameters: function(){
  var controller = $(this.element)
  var action = $(this.element).find('ul.actions li.active a').first().html()
  var loader = $(this.element).next('.action_loader').first();
  this.options.saved[action] = loader.attr('form-params')
  controller.find('> ul.controls > li.pin').addClass('saved')
  this._dump()
 },

 _toggle_pin: function(){
  var action = $(this.element).find('ul.actions li.active a').first().html()

  if (this.options.saved[action] != undefined){
   this._unpin_parameters();
  }else{
   this._pin_parameters();
  }
 },

 _loader: function(){
  return $(this.element).next('.action_loader')
 },

 _url: function(){
  var url = this._loader().attr('target-href');
  if (undefined === url){ return url}
  return unescape(remove_parameter(url, '_'))
 },

 _open_url: function(){
  var action_controller = this.element
  var action_div = action_controller.next('.action_loader').first();

  if (this._url() !== undefined){
   window.location = this._url();
  }

  return false
 },


 _reload_action: function(e){
  if(! $(e).hasClass('active')){ return false}
  var action_list_item = $(e);
  var action_list = action_list_item.parent('ul.controls');
  var action_controller = action_list.parent('.action_controller');
  var action_div = action_controller.next('.action_loader').first();

  if (action_div.attr('target-href') != undefined){
   update_embedded(action_div, true)
  }

  return false
 },

 _display_parameters: function(e){
  if(! $(e).hasClass('active')){ return false}
  var link = $(e);
  var action_controller = link.parents('.action_controller').first()
  var action_loader = action_controller.next('.action_loader').first();
  var action_parameters = action_loader.find('.action_parameters').first();
  var action_content = action_parameters.next('.action_content').first();

  action_parameters.toggleClass('active');
  action_content.toggleClass('shifted');

  $.scrollTo(this.element, {axis:'y', offset:{top: -$("#top_menu").height() - 20}})

  return false
 },


 _load_action: function(link){
  var action_list_item = link.parent('li');
  var action_list = action_list_item.parent('ul');
  var action_controller = action_list.parents('.action_controller').first();
  var action_div = action_controller.next('.action_loader');
  var href = link.attr('href')

  var action = link.html()
  var saved = this.options.saved[action]

  if (undefined !== saved){
   href = add_parameters(href, saved)
  }

  setup_action_controls = function(jqXHR, textStatus){
   var action_div = action_controller.next('.action_loader');
   if (jqXHR.status == 202){
    action_controller.removeClass('active');

    var response = $(jqXHR.responseText)
    var stat = response.find('span.status').html()
    var message = response.find('ul.step_messages li:first').html()
    if (undefined === message){
     action_div.html("<span class='loading'>Loading [" + stat + "] ...</span>");
    }else{
     action_div.html("<span class='loading'>Loading [" + stat + ": " + message + "] ...</span>");
    };
   }else{ 
    action_controller.addClass('active'); 
    action_controller.find('ul.controls > li.reload').addClass('active');
   }

   var action_div = action_controller.next('.action_loader').first();
   action_controller.find('ul.controls > li.url').addClass('active');
   if (action_div.find('> .action_card > .action_parameters').length > 0){
    action_controller.find('ul.controls > li.parameters').addClass('active');
    action_controller.find('ul.controls > li.pin').addClass('active');
   }else{
    action_controller.find('ul.controls > li.parameters').removeClass('active');
    action_controller.find('ul.controls > li.pin').removeClass('active');
   }
  }

  if( ! action_div.hasClass('reloading') ) {
   action_div.removeClass('active');
   action_controller.find('ul.controls > li.reload').removeClass('active');
   action_controller.find('ul.controls > li.parameters').removeClass('active');
   action_list.find('li').removeClass('active');
   action_list_item.addClass('active');
   replace_object(action_div, href, true, setup_action_controls);

   return false
  }
 }
})

