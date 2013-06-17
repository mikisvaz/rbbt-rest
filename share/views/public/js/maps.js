function entity_map(type, column, id){
  var url = "/entity_map" + '/' + clean_element(type) + '/' + clean_element(column) + '/' + clean_element(id);

  response = $.ajax({
    url: url,
    async: false,
    method: "GET",
    data: {_format: 'json'},
  })

  return JSON.parse(response.responseText);
}

$('body').on('click', '.map_management a.ensembl', function(){


})
