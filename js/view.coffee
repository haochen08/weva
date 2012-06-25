String.prototype.truncate = ->
  @.replace(/\s+$/, "")

$('#search_box').keypress (e) ->
  if e.keyCode is 13
    keywords = $(@).attr('value').truncate()
    if keywords?
      $.ajax
        url: "http://127.0.0.1:8000/search?q=" + encodeURIComponent(keywords)
        success: (data, status, xhr) ->
          $.get "result.temp.html", (template) ->
            result = $.mustache(template, data)
            $('#results').append(result) if result?  
