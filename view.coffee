String.prototype.truncate ->
  @.replace(/\s+$/, "")

$('#search_box').keypress ->
  keywords = $(@).value.truncate()
  if keywords?
    $.ajax
      url: "/search?q=" + encodeURIComponent(keywords)
      success: (data, status, xhr) ->
        $.get "result.temp.html", (template) ->
          result = $.mustache(template, data)
          $('#results').append(result) if result?  
