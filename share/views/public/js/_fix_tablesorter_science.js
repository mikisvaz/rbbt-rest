$.tablesorter.addParser({ 
  // set a unique id
  id: 'scinot', 
  is: function(s) { 
    return /^\s*[+\-]?(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+\-]?\d+)?\s*$/.test(s); 
  }, 
  format: function(s) { 
    return $.tablesorter.formatFloat(s);
  }, 
  type: 'numeric' 
});

$.tablesorter.addParser({ 
  // set a unique id
  id: 'anchor_text', 
  is: function(s) { 
    return /<\/a>/.test(s); 
  }, 
  format: function(s) { 
    var text = $(s).find('a').text();
    return text;
  }, 
  type: 'text' 
});

$.tablesorter.addParser({ 
  // set a unique id
  id: 'percentage', 
  is: function(s) { 
    return /\d+\s*%/.test(s); 
  }, 
  format: function(s) { 
    var num =  $.tablesorter.formatFloat(s);
    return num;
  }, 
  type: 'numeric' 
});

