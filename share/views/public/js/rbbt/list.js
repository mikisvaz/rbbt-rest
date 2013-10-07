function list_entities(type, id){
  var url = "/entity_list" + '/' + type + '/' + id;

  return JSON.parse(get_ajax({url: url, async: false, method: "GET", data: {_format: 'json'}}))['entities']
}

function list_info(type, id){
  var url = "/entity_list" + '/' + type + '/' + id;

  return JSON.parse(get_ajax({url: url, async: false, method: "GET", data: {_format: 'info'}}))
}

function list_array(type, list){
  return "list:" + type + ":" + list;
}

var body = $('body');

body.on('click', 'a.compare_list', function(){
  var type = page_entity_type().split(":")[0];
  var lists = get_favourite_entity_lists()[type];

  if (undefined == lists || lists.length == 0){
    alert("No lists to compare with");
    return false
  }

  var list_id = page_entity_list();

  var type_ul = favourite_list_type_ul(type, lists).addClass("list_comparison")
  var buttons = $('<ul class="list_comparison_buttons">')
  buttons.append('<li><a class="intersect_lists" href="#">Intersect</a></li>')
  buttons.append('<li><a class="remove_list" href="#">Remove</a></li>')
  buttons.append('<li><a class="add_list" href="#">Add</a></li>')
  type_ul.find('li').prepend(buttons)

  $('#modal').modal('show', type_ul);
  return true
})

body.on('click', 'a.intersect_lists', function(){
  var link = $(this);
  var other_list_id = link.parent().parent().parent().find("a.entity_list").attr('title');
  var type = clean_element(page_entity_type());
  var list_id = page_entity_list();
  var params = "other_list_id=" + clean_element(other_list_id)
  var url = "/entity_list/intersect/" + type + "/" + clean_element(list_id) + "?" + params
  window.location= url
})
body.on('click', 'a.remove_list', function(){
  var link = $(this);
  var other_list_id = link.parent().parent().parent().find("a.entity_list").attr('title');
  var type = clean_element(page_entity_type());
  var list_id = page_entity_list();
  var params = "other_list_id=" + clean_element(other_list_id)
  var url = "/entity_list/remove/" + type + "/" + clean_element(list_id) + "?" + params
  window.location= url
})
body.on('click', 'a.add_list', function(){
  var link = $(this);
  var other_list_id = link.parent().parent().parent().find("a.entity_list").attr('title');
  var type = clean_element(page_entity_type());
  var list_id = page_entity_list();
  var params = "other_list_id=" + clean_element(other_list_id)
  var url = "/entity_list/add/" + type + "/" + clean_element(list_id) + "?" + params
  window.location= url
})
body.on('click', 'a.edit_list', function(){
  var type = page_entity_type().split(":")[0];
  var lists = get_favourite_entity_lists()[type];
  var entity_type = page_entity_type();
  var list_id = page_entity_list();

  var url = '/entity_list/' + entity_type + '/edit/' + list_id

  $('#modal').modal('show_url', url)
  
  return true
})
body.on('click', 'ul.new_list > li > a', function(){
  var entity_type = $(this).html();
  var url = '/entity_list/' + entity_type + '/new/'

  get_ajax({url: url, async: false}, function(data){$('#modal').modal('show', data, "New " + entity_type + " list"); $('#top_menu li.favourites').favourites('close')})

  
  return true
})

body.on('click', '.edit_list input[type=submit]', function(){
  var submit = $(this);
  var form = submit.parents('form').first();
  var annotations = {}
  console.log("EDIT")

  $.map(form.find(':input'), function(i){ annotations[i.name] = $(i).val()})

  var new_list_id = annotations['list_id']
  delete annotations['list_id']

  var format = annotations['format']
  delete annotations['format']

  var entities = annotations['entities']
  delete annotations['entities']

  var entity_type = form.parents('.edit_list').first().attr('attr-entity_type')

  if (undefined !== format){ entity_type = entity_type + ':' + clean_element(format) }

  var url = '/entity_list/' + entity_type + '/' + new_list_id  

  get_ajax({url: url, type: 'POST', async: false, data: {annotations: JSON.stringify(annotations), entities: entities}}, function(){ window.location = url })

  return false
})


