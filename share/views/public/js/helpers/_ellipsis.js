function contract_ellipsis(elem, max){
  if (undefined === max) { max = 5 };
  var text;
  var elements;
  var type;

  if (elem.text() == elem.html()){
    type = 'text';
    text = elem.text();
    elements = text.split(', ');
  }else{
    type = 'html';
    elements = elem.children();
  }

  if (elements.length > max + 2){
    if (type == 'html'){
      elements.removeClass('rbbt_action_setup')
    }
    var rest = elements.length - max;
    var ellipsis = "... (<a href=# class='open_ellipsis'>" + rest + " more</a>)";
    var end_span = $("<span class='ellipsis' attr-text='" + escape(elem.html()) + "'>" + ellipsis + "</span>");
    var new_content;
    
    if (type == 'text'){
      new_content = elements.slice(0, max).join(", ");
      elem.text(new_content);
    }else{
      var links = [];
      var head = elements.slice(0, max).removeClass('long');
      head.each(function(){ links.push(this.outerHTML)})
      new_content = links.join(", ");
      elem.html(new_content);
    }

    end_span.appendTo(elem);

    return(true);
  }else{
    return(false);
  }
}

function restore_ellipsis(elem){
  var span = elem.find('span.ellipsis')
  if (span.length == 1){
    var html = span.attr('attr-text');
    elem.html(unescape(html));
  }
  update_rbbt();
}

$('body').on('click', 'a.open_ellipsis', function(link){
  var link = $(this);
  var span = link.parent('span');
  var container = span.parent();
  restore_ellipsis(container);

  return(false);
})
