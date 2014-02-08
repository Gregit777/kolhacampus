/*global jQuery*/
(function($){

  var setupSelect2Fields, setupSelect2Field, setupSelect2MultiField, setupSelect2TagField,
    delimiter = '~|~';

  setupSelect2Fields = function(){
    (window.select2_fields || []).forEach(setupSelect2Field);
    (window.select2_multi_fields || []).forEach(setupSelect2MultiField);
    (window.select2_tags_fields || []).forEach(setupSelect2TagField);
  };

  setupSelect2MultiField = function(id){
    $('#'+id).select2();
  };

  setupSelect2TagField = function(id){
    var el = $('#'+id),
      tags = el.val().split(',');
    el.select2({
      placeholder: "Add Tag",
      tags:tags
    });
  };

  setupSelect2Field = function(id){
    $('#'+id).select2({
      placeholder: "Search for an item",
      minimumInputLength: 3,
      ajax: { // instead of writing the function to execute the request we use Select2's convenient helper
        url: "/api/shared/v1/autocomplete/title",
        dataType: 'json',
        data: function (term) {
          var o = {q: term},
            index = this.data('search');
          if(index){
            o.index = index;
          }
          return o;
        },
        results: function (data, page) {
          data.map(function(d){
            d.id = [d._type, d.id, d.title].join(delimiter);
            delete d._type;
          });
          return {results: data};
        }
      },
      initSelection: function(el, cb){
        var v = el.val(),
          parts = v.split(delimiter);
        cb({id: v, title: parts[2]});
      },
      formatResult: function(item){
        return item.title;
      },
      formatSelection: function(item){
        return item.title;
      }
    });
  };

  $(document).ready(setupSelect2Fields);

}(jQuery));