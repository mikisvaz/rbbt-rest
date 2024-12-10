function list_entities(type, id){
  var url = "/entity_list" + '/' + type + '/' + id;

  url = rbbt.url_add_script_name(url)
  return get_ajax({url: url, async: false, method: "GET", data: {_format: 'json'}})['entities']
}

function list_info(type, id){
  var url = "/entity_list" + '/' + type + '/' + id;

  url = rbbt.url_add_script_name(url)
  return get_ajax({url: url, async: false, method: "GET", data: {_format: 'info'}})
}

function list_array(type, list){
  return "list:" + type + ":" + list;
}

var body = $('body');

body.on('click', 'a.compare_list', function(){
  var type = rbbt.page.list().type;
  var lists = Object.keys(rbbt.favourites.lists.types()[type]);

  if (undefined == lists || lists.length == 0){
    alert("No lists to compare with");
    return false
  }

  var list_id = rbbt.page.list().id;
  console.log(list_id)
  console.log(lists)
  lists = remove_from_array(lists, list_id)
  console.log(lists)


  var buttons = m('.ui.buttons.list_comparison_buttons', [
    m('a.intersect_lists.ui.compact.button',{href:'#'}, 'Intersect'),
    m('a.remove_list.ui.compact.button',{href:'#'}, 'Remove'),
    m('a.add_list.ui.compact.button',{href:'#'}, 'Add')
  ])

  var list_ul = m('ul.list_comparison.lists.clean_list', 
                  mapArray(lists, function(l){ 
                    return m('li', [buttons, rbbt.page.list_link(type, l)])
                  }))


  rbbt.modal.controller.show(list_ul, "Compare list")
  return false
})

body.on('click', 'a.intersect_lists', function(){
  var link = $(this);
  var other_list_id = link.parent().parent().find("a.entity_list").attr('title');
  var type = clean_element(rbbt.page.list().type);
  var list_id = rbbt.page.list().id;
  var params = "other_list_id=" + clean_element(other_list_id)
  var url = "/entity_list/intersect/" + clean_element(type) + "/" + clean_element(list_id) + "?" + params

  url = rbbt.url_add_script_name(url)
  window.location= url
})

body.on('click', 'a.remove_list', function(){
  var link = $(this);
  var other_list_id = link.parent().parent().find("a.entity_list").attr('title');
  var type = clean_element(rbbt.page.list().type);
  var list_id = rbbt.page.list().id;
  var params = "other_list_id=" + clean_element(other_list_id)
  var url = "/entity_list/remove/" + clean_element(type) + "/" + clean_element(list_id) + "?" + params

  url = rbbt.url_add_script_name(url)
  window.location= url
})

body.on('click', 'a.add_list', function(){
  var link = $(this);
  var other_list_id = link.parent().parent().find("a.entity_list").attr('title');
  var type = clean_element(rbbt.page.list().type);
  var list_id = rbbt.page.list().id;
  var params = "other_list_id=" + clean_element(other_list_id)
  var url = "/entity_list/add/" + clean_element(type) + "/" + clean_element(list_id) + "?" + params
  url = rbbt.url_add_script_name(url)
  window.location= url
})

body.on('click', 'a.edit_list', function(){
  var type = rbbt.page.list().type;
  var lists = rbbt.favourites.lists.types()[type];
  var entity_type = rbbt.page.list().full_type();
  var list_id = rbbt.page.list().id;

  var url = '/entity_list/' + clean_element(entity_type) + '/edit/' + clean_element(list_id)
  url = rbbt.url_add_script_name(url)

  rbbt.modal.controller.show_url(url, "Edit list")
  
  return true
})

body.on('click', 'ul.new_list > li > a', function(){
  var entity_type = $(this).html();
  var url = '/entity_list/' + entity_type + '/new/'

  url = rbbt.url_add_script_name(url)
  get_ajax({url: url, async: false}, function(data){$('#modal').modal('show', data, "New " + entity_type + " list"); $('#top_menu li.favourites').favourites('close')})

  
  return true
})

body.on('click', '.edit_list input[type=submit]', function(){
  var submit = $(this);
  var form = submit.parents('form').first();
  var annotations = {}

  $.map(form.find(':input'), function(i){ annotations[i.name] = $(i).val()})

  var new_list_id = annotations['list_id']
  delete annotations['list_id']

  var format = annotations['format']
  delete annotations['format']

  var entities = annotations['entities']
  delete annotations['entities']

  var entity_type = form.parents('.edit_list').first().attr('attr-entity_type')

  if (undefined !== format){ entity_type = entity_type + ':' + clean_element(format) }

  var url = '/entity_list/' + clean_element(entity_type) + '/' + clean_element(new_list_id)

  url = rbbt.url_add_script_name(url)
  get_ajax({url: url, type: 'POST', async: false, data: {annotations: JSON.stringify(annotations), entities: entities}}, function(){ window.location = url })

  return false
})


