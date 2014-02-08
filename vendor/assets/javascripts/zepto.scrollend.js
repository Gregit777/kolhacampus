/*global Zepto*/
(function ($) {
  $.fn.scrollend = function (options) {
    var originalCallback,
        callback,
        timer;

    callback = function(){
      clearTimeout(timer);
      timer = setTimeout(function(){
        originalCallback();
      }, 300);
    };

    if(typeof options === 'function'){
      originalCallback = options;
    }

    return this.each(function(){
      var $this = $(this);
      if(typeof options === 'function'){
        $this.on('scroll', callback);
      } else {
        $this.off('scroll', callback);
      }
    });
  };
}(Zepto));