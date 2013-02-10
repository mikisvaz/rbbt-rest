
function fix_long_table_cells(table, max){
  var update = false;
  table.find('td').each(function(){
    update = contract_ellipsis($(this), max) || update;
  });
  if (update){
    update_dom();
  }
}

register_dom_update('table:not(.noellipsis)', function(table){
  fix_long_table_cells(table, 5);
})

register_dom_update('table:not(.nosort)', function(table){
  table.tablesorter().addClass('sorted');
})


