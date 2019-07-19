
function parse_page(page){
  if (undefined === page){ page = "" }
  if (page == "" ){ return {} }
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
  if ( undefined !== size) return "";

  var parts = [num];
  if ( undefined !== size) parts.push(size)
  if ( undefined !== field) parts.push(field)

  return parts.join("~")
}

$.widget("rbbt.table", {

 options: {
   ellipsis: 5,
 },

 _fix_long_table_cells: function(max){
   var update = false;
   $(this.element).find('td').each(function(){
     update = contract_ellipsis($(this), max) || update;
   });
   if (update){
     update_rbbt();
   }
 },


 
 _update: function(url, num, size, field, filter, complete){
  var table = this.element
  var tool = this

  url = rbbt.url_add_script_name(url)

  url = add_parameter(url, '_page',  escape(format_page(num, size, field)))
  url = add_parameter(url, '_format', 'table')
  if (undefined != filter){ url = add_parameter(url, '_filter',  escape(filter)) }

  replace_object(table, url, true, function(){
   table.attr('attr-page', format_page(num, size, field)).attr('rbbt-update_tags','')
   update_rbbt();
   if (undefined === complete){
    $.scrollTo(table.find('tfoot'), {axis : 'y', offset: {top: - window.innerHeight + 100 }});
   }else{ complete() }
   if (tool.options.ellipsis !== undefined && ! $(table).hasClass('no_js')){
    tool._fix_long_table_cells(5);
   }
  });

 },

 _status: function(){
  var table = this.element
  var url = table.attr('attr-url')
  var page = table.attr('attr-page')
  var filter = table.attr('attr-filter')

  var total = parseInt(table.attr('attr-total_size'))

  var page_info = parse_page(page)
  var num = parseInt(page_info["num"])
  var size = parseInt(page_info["size"])
  var field = page_info["field"]

  if (isNaN(num)){ num = undefined}
  if (isNaN(size)){ size = undefined}

  var stat = {url: url, page: page, num: num, field: field, filter: filter, total: total, size: size};

  return stat
 },

 _create: function() {
  var tool = this;
  var table = tool.element

  if (!$(this.element).hasClass('.noellipsis')){
    this._fix_long_table_cells(this.options.ellipsis);
  }else{
    this.options.ellipsis = false
  }

  //{{{ Pagination
  //
  table.on('click', 'tfoot > tr > th > .table_pagination > .num:not(.active)', function(link){
   var link = $(this)

   var stat = tool._status()

   tool._update(stat.url, link.html(), stat.size, stat.field, stat.filter)

   return false
  })

  table.on('click', 'tfoot > tr > th > .table_pagination > .arrow.prev', function(link){
   var stat = tool._status()

   if (stat.num > 1){ stat.num = stat.num - 1 }

   tool._update(stat.url, stat.num, stat.size, stat.field, stat.filter)

   return false
  })

  table.on('click', 'tfoot > tr > th > .table_pagination > .arrow.next', function(evt){
   var stat = tool._status();
   var last = parseInt($(this).parents('.table_pagination').first().find('a.num').last().html())

   if (stat.num < last){ stat.num = stat.num + 1 }

   tool._update(stat.url, stat.num, stat.size, stat.field, stat.filter)

   return false
  })

  table.on('click', 'tfoot > tr > th > .table_pagination > .all', function(link){
   var stat = tool._status()

   tool._update(stat.url, '', stat.size, stat.field, stat.filter)

   return false
  })

  //{{{ Sorting
  //
  table.on('click', '> thead > tr > th', function(th){
   var th = $(this)
   var table = tool.element;

   var direction

   var stat = tool._status()

   stat.field = th.html()
   stat.num = 1

   if (th.is('.headerSortDown')){
    direction = 1;
   }else{
    direction = -1;
   }

   orig_field = stat.field
   if (direction == -1){
    stat.field = '-' + stat.field;
   }else{
    stat.field = stat.field;
   }

   tool._update(stat.url, stat.num, stat.size, stat.field, stat.filter, function(){
    var th = table.find('thead > tr > th:contains(' + orig_field + ')')

    if (direction == -1){
     th.removeClass('headerSortUp');
     th.addClass('headerSortDown');
    }else{
     th.removeClass('headerSortDown');
     th.addClass('headerSortUp')
    }
   })
   table.addClass('sorted')

   return false
  })

  //{{{ Sorting
  var filter_id = table.find('a.filter.rbbt_reveal_trigger').attr('attr-reveal_id')
  $('body').on('click', '.modal[attr-reveal_source_id=' + filter_id + '] .filter_controls form input[type=submit]', function(){
   var submit = $(this);
   var form = submit.parents('form')
   var filter = ""

   form.find('input').not('[type=submit]').each(function(){
     var input = $(this)
     var val = input.val()
     var name = input.attr('name')

     if (val != ""){
     if (filter != ""){ filter += ";;"}
     filter += name + "~" + val;
    }
   })

   var modal = submit.closest('.modal')
   var modal = $('#modal')
   var source_id = modal.attr('attr-reveal_source_id')
   var source = $('#' + source_id);
   var table = source.parents('table').first();
   var url = table.attr('attr-url')
   var page = table.attr('attr-page')

   url = add_parameter(url, '_page',  "1")

   if (undefined != filter){ url = add_parameter(url, '_filter',  escape(filter)) }

   url = add_parameter(url, '_format', 'table')

   replace_object(table, url, true, function(){
    table.attr('attr-page', "1").attr('attr-filter', filter).attr('rbbt-update_tags','')
    update_rbbt();
    $.scrollTo(table.find('tfoot'), {axis : 'y', offset: {top: - window.innerHeight + 100 }})
   });

   rbbt.modal.controller.close()
   return false
  })

  //{{{ Columns
  //
  var filter_id = table.find('a.table_column.rbbt_reveal_trigger').attr('attr-reveal_id')
  $('body').on('click', '.modal[attr-reveal_source_id=' + filter_id + '] a.save_column_list', function(){
   var link = $(this);
   var column = link.parent().find('span.field').html()


   var modal = $('#modal')
   var source_id = modal.attr('attr-reveal_source_id')
   var source = $('#' + source_id);
   var table = source.parents('table').first();

   var url = table.attr('attr-url')
   var page = table.attr('attr-page')
   var filter = table.attr('attr-filter')

   var page_info = parse_page(page)
   var num   = 'all'
   var size  = page_info["size"]
   var field = page_info["field"]

   url = add_parameter(url, '_page',  escape(format_page(num, size, field)))
   url = add_parameter(url, '_format', 'entities')
   url = add_parameter(url, '_column', column)
   if (undefined != filter){ url = add_parameter(url, '_filter',  escape(filter)) }

   rbbt.modal.controller.show_url(url)
   //modal.modal('show_url', url)
   return false
  });

  var filter_id = table.find('a.table_column.rbbt_reveal_trigger').attr('attr-reveal_id')
  $('body').on('click', '.modal[attr-reveal_source_id=' + filter_id + '] a.save_column_map', function(){
   var link = $(this);
   var column = link.parent().find('span.field').html()


   var modal = $('#modal')
   var source_id = modal.attr('attr-reveal_source_id')
   var source = $('#' + source_id);
   var table = source.parents('table').first();

   var url = table.attr('attr-url')
   var page = table.attr('attr-page')
   var filter = table.attr('attr-filter')

   var page_info = parse_page(page)
   var num   = 'all'
   var size  = page_info["size"]
   var field = page_info["field"]

   url = add_parameter(url, '_page',  escape(format_page(num, size, field)))
   url = add_parameter(url, '_column', escape(column))
   url = add_parameter(url, '_format', 'map')
   if (undefined != filter){ url = add_parameter(url, '_filter',  escape(filter)) }

   rbbt.modal.controller.show_url(url)
   //modal.modal('show_url', url)
   return false
  });

 },
})

