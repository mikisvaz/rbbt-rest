register_dom_update('.documented.segment > .help.label', function(item){
  item.click(function(){
    var segment = $(this).parent('.documented.segment')
    var documentation = segment.find(' > .hidden.documentation')
    var header = documentation.find('> h1')

    var documentation_html
    var documentation_title

    if (header.length > 0){
      console.log('header')
      documentation_dup = documentation.clone()
      documentation_title = documentation_dup.find(' > h1').first().html()
      documentation_dup.find(' > h1').first().remove()
      documentation_html = documentation_dup.html()
    }else{
      documentation_html = documentation.html()
      documentation_title = 'Documentation'
    }
    console.log(documentation_html)
    var doc_div = $('<div>').addClass('documentation').append(documentation_html)
    console.log(doc_div)
    rbbt.modal.controller.show(doc_div[0].outerHTML, documentation_title)
  })
})
