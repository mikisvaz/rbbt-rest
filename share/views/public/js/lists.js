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

    $('#modal1').html(type_ul).reveal();
    return false
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
}
