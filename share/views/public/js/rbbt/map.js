function entity_map(type, column, id, complete){
  var url = "/entity_map" + '/' + clean_element(type) + '/' + clean_element(column) + '/' + clean_element(id);
  return JSON.parse(get_ajax({url: url, async: false, method: "GET", data: {_format: 'json'}}, complete))
}

$('body').on('click', '.rank_products form input[type=submit]', function(){
  var map1 = page_entity_map();

  var input = $(this);
  var select = input.closest('form').find('select')
  var map2 = select.val();
  var entity_type = page_entity_base_type()
  var column = page_entity_map_column()
  url = "/entity_map/rank_products?map1=" + clean_element(map1) + "&map2=" + clean_element(map2) + '&entity_type=' + entity_type + "&column=" + column
  window.location = url
  return false
})

