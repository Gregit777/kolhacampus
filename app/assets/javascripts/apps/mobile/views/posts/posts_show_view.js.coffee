class KolHacampus.PostsShowView extends Batman.View

  ready: ->
    addTwitterButton = (d, s, id) ->
      el = d.getElementById(id)
      el.parentNode.removeChild(el) if el
      js = undefined
      fjs = d.getElementsByTagName(s)[0]
      p = (if /^http:/.test(d.location) then "http" else "https")
      js = d.createElement(s)
      js.id = id
      js.src = p + "://platform.twitter.com/widgets.js"
      fjs.parentNode.insertBefore js, fjs

    addTwitterButton(document, "script", "twitter-wjs")