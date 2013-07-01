function setup_list_management(){
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

    $('#modal1').html(type_ul);
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

    open_url_in_reveal('modal1', url)
    //get_ajax({url:url, async: false}, function(data){$('#modal1').html(data);})
    
    return true
  })
  body.on('click', 'a.new_list', function(){
    var entity_type = $(this).html();
    var url = '/entity_list/' + entity_type + '/new/'

    //$.ajax(url, {async: false, success: function(data){$('#modal1').html(data);}})
    get_ajax({url: url, async: false}, function(data){$('#modal1').html(data);})
    
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

    //var entity_type = page_entity_type().split(":")[0];
    var entity_type = form.parents('.edit_list').first().attr('attr-entity_type')

    if (undefined !== format){ entity_type = entity_type + ':' + clean_element(format) }

    var url = '/entity_list/' + entity_type + '/' + new_list_id  

    //$.ajax({url: url, type: 'POST', async: false, data: {annotations: JSON.stringify(annotations), entities: entities}, success: function(){ window.location = url }})
    get_ajax({url: url, type: 'POST', async: false, data: {annotations: JSON.stringify(annotations), entities: entities}}, function(){ window.location = url })

    return false
  })
}

function list_entities(type, id){
  var url = "/entity_list" + '/' + type + '/' + id;

  //response = $.ajax({
  //  url: url,
  //  async: false,
  //  method: "GET",
  //  data: {_format: 'json'},
  //})

  //return JSON.parse(response.responseText)['entities'];
  return JSON.parse(get_ajax({url: url, async: false, method: "GET", data: {_format: 'json'}}))['entities']
}

function list_info(type, id){
  var url = "/entity_list" + '/' + type + '/' + id;

  //response = $.ajax({
  //  url: url,
  //  async: false,
  //  method: "GET",
  //  data: {_format: 'info'},
  //})

  //return JSON.parse(response.responseText);
  return JSON.parse(get_ajax({url: url, async: false, method: "GET", data: {_format: 'info'}}))
}

function list_array(type, list){
  return "list:" + type + ":" + list;
}
