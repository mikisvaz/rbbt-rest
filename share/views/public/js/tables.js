function parse_page(page){
  var parts = page.split('~')
  switch(parts.length){
    case 1:
      return { num: parseInt(parts[0]) };
      break;
    case 2:
      return { num: parseInt(parts[0]), field: parts[1] };
      break;
    case 3:
      return { num: parseInt(parts[0]) , field: parts[2], size: parseInt(parts[1]) };
      break;
  }
}

function format_page(num, size, field){
  var parts = [num];
  if ( undefined !== size) parts.push(size)
  if ( undefined !== field) parts.push(field)

  return parts.join("~")
}

function fix_long_table_cells(table, max){
  var update = false;
  table.find('td').each(function(){
    update = contract_ellipsis($(this), max) || update;
  });
  if (update){
    update_rbbt();
  }
}

register_dom_update('table:not(.noellipsis)', function(table){
  fix_long_table_cells(table, 5);
})

register_dom_update('table:not(.nosort, [attr-page])', function(table){
  table.tablesorter().addClass('sorted');
})

register_dom_update('table > tfoot > tr > th > ul.table_pagination > li.num > a:not(.active)', function(link){
  link.click(function(){
    var link = $(this)
    var table = link.parents('table').first();
    var url = table.attr('attr-url')
    var page = table.attr('attr-page')

    var page_info = parse_page(page)
    var num = link.html()
    var size = page_info["size"]
    var field = page_info["field"]

    url = add_parameter(url, '_page',  escape(format_page(num, size, field)))
    url = add_parameter(url, '_format', 'table')

    replace_object(table, url, true, function(){
      table.attr('attr-page', format_page(num, size, field))
      $.scrollTo(table.find('tfoot'), {axis : 'y', offset: {top: - window.innerHeight + 100 }})
    });

    return false
  })
})

register_dom_update('table > tfoot > tr > th > ul.table_pagination > li.arrow > a.prev', function(link){
  link.click(function(){
    var link = $(this)
    var table = link.parents('table').first();
    var url = table.attr('attr-url')
    var page = table.attr('attr-page')
    var total = parseInt(table.attr('attr-total_pages'))

    var page_info = parse_page(page)
    var num = page_info["num"]
    var size = page_info["size"]
    var field = page_info["field"]

    num = num - 1

    if (num < 1) return false

    url = add_parameter(url, '_page',  escape(format_page(num, size, field)))
    url = add_parameter(url, '_format', 'table')

    replace_object(table, url, true, function(){
      table.attr('attr-page', format_page(num, size, field))
      $.scrollTo(table.find('tfoot'), {axis : 'y', offset: {top: - window.innerHeight + 100 }})
    });

    return false
  })
})

register_dom_update('table > tfoot > tr > th > ul.table_pagination > li.arrow > a.next', function(link){
  link.click(function(){
    var link = $(this)
    var table = link.parents('table').first();
    var url = table.attr('attr-url')
    var page = table.attr('attr-page')
    var total = parseInt(link.parent('li').prev().find('a').html())

    var page_info = parse_page(page)
    var num = page_info["num"]
    var size = page_info["size"]
    var field = page_info["field"]

    if (num >= total) return false

    num = num + 1


    url = add_parameter(url, '_page',  escape(format_page(num, size, field)))
    url = add_parameter(url, '_format', 'table')

    replace_object(table, url, true, function(){
      table.attr('attr-page', format_page(num, size, field))
      $.scrollTo(table.find('tfoot'), {axis : 'y', offset: {top: - window.innerHeight + 100 }})
    });

    return false
  })
})


register_dom_update('table > tfoot > tr > th > ul.table_pagination > li.all > a', function(link){
  link.click(function(){
    var table = link.parents('table').first();
    var url = table.attr('attr-url')

    url = add_parameter(url, '_page',  '')
    url = add_parameter(url, '_format', 'table')

    replace_object(table, url, true, function(){
      $.scrollTo(table.find('tfoot'), {axis : 'y', offset: {top: - window.innerHeight + 100 }})
    });

    return false
  })
})

register_dom_update('table[attr-page] > thead > tr > th', function(th){
  th.click(function(){
    var th = $(this)
    var table = th.parents('table').first();
    var url = table.attr('attr-url')
    var page = table.attr('attr-page')

    var page_info = parse_page(page)
    var num = 1
    var size = page_info["size"]
    var field = th.html();

    var direction

    if (th.is('.headerSortDown')){
      direction = -1
    }else{
      direction = 1
    }

    if (direction == -1){
      ffield = '-' + field;
    }else{
      ffield = field;
    }


    url = add_parameter(url, '_page',  escape(format_page(num, size, ffield)))
    url = add_parameter(url, '_format', 'table')

    replace_object(table, url, true, function(){
      var th = table.find('thead > tr > th:contains(' + field + ')')
      table.addClass('sorted')
      table.attr('attr-page', format_page(num, size, ffield))
      if (direction == 1){
        th.removeClass('headerSortUp');
        th.addClass('headerSortDown');
      }else{
        th.removeClass('headerSortDown');
        th.addClass('headerSortUp')
      }
    });

    return false

  })
})
