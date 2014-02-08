class KolHacampus.AboutController extends KolHacampus.ApplicationController
  routingKey: 'about'

  index: ->
    if KolHacampus.About.get('loaded.length')
      @set 'about', KolHacampus.About.get('loaded.first')
    else
      KolHacampus.About.load (err, results) =>
        @set 'about', results[0]