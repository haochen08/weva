/*
Shameless port of a shameless port
@defunkt => @janl => @aq

See http://github.com/defunkt/mustache for more info.
*/

;(function($) {

// <snip> mustache.js code

  $.mustache = function(template, view, partials) {
    return Mustache.to_html(template, view, partials);
  };

})(jQuery);

