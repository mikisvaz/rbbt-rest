function entity_map(type, column, id, complete){
  var url = "/entity_map" + '/' + clean_element(type) + '/' + clean_element(column) + '/' + clean_element(id);
  return rbbt.ajax({url: url, async: false, method: "GET", data: {_format: 'json'}}, complete)
}

$('body').on('click', '#modal form.rename_map input[type=submit]', function(){
  console.log(1)
  var map = rbbt.page.map();
  var map_id = map.id

  var submit = $(this);
  var input = submit.closest('form').find('input[name=rename]')
  var new_name = input.val();
  var entity_type = map.type
  var column = map.column
  url = '/entity_map/rename/'+ clean_element(entity_type) + '/'+ clean_element(column) +'/' + clean_element(map_id) + '?new_name=' + clean_element(new_name)
  window.location = url
  return false
})

$('body').on('click', '.rank_products form input[type=submit]', function(){
  var map = rbbt.page.map();
  var map1 = map.id;

  var input = $(this);
  var select = input.closest('form').find('select')
  var map2 = select.val();
  var entity_type = map.type
  var column = map.column
  var column2 = select.find('option:selected').attr('attr-column')
  url = "/entity_map/rank_products?map1=" + clean_element(map1) + "&map2=" + clean_element(map2) + '&entity_type=' + entity_type + "&column=" + column +  "&column2=" + column2
  window.location = url
  return false
})

$('body').on('click', '.plot form input[type=submit]', function(){
  var map = rbbt.page.map();
  var map1 = map.id;

  var input = $(this);
  var select = input.closest('form').find('select')
  var map2 = select.val();
  var entity_type = map.type
  var column = map.column
  var column2 = select.find('option:selected').attr('attr-column')

  m.sync([entity_map(entity_type,column,map1), entity_map(entity_type,column2, map2)]).then(function(res){
    var modal = $('#modal')
    var container = $('<div>').addClass('plot_container')

    var res1, res2
    res1 = res[0]
    res2 = res[1]

    var tmp_data = []
    forHash(res1,function(k,v1){
      var v2 = res2[k]
      if (undefined !== v2)
        tmp_data.push([v1,v2,k])
    })
    tmp_data = tmp_data.sort(function(a,b){ return a[0] - b[0] })

    var data = []
    var keys = []

    for(i in tmp_data){
      var k,v1,v2 
      v1 = tmp_data[i][0]
      v2 = tmp_data[i][1]
      k = tmp_data[i][2]

      keys.push(k)
      data.push([v1,v2])
    }

    require_js('https://code.highcharts.com/highcharts.js', function(){
         container.highcharts({
        title: {
            text: map1 + ' vs. ' + map2,
            x: -20 //center
        },
        subtitle: {
            text: 'Comparison plot',
            x: -20
        },
        xAxis: {
            title: {
                text: map1 + ': ' + column
            },
        },
        yAxis: {
            title: {
                text: map2 + ': ' + column2
            },
        },
        legend: {
            layout: 'vertical',
            align: 'right',
            verticalAlign: 'middle',
            borderWidth: 0
        },
        series: [{
            name: 'Comparison',
            data: data,
            labels: keys,
        }]
    });

    modal.find('.content').append(container)
 
    })
  })

  return false
})

