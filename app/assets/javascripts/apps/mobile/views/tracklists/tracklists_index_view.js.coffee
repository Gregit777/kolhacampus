ViewMixin =

  playTrack: (id) ->
    player = KolHacampus.get('player')
    player.stop()
    KolHacampus.Tracklist.find id, (err, tracklist) ->
      player.setMode 'ondemand', tracklist
      setTimeout( ->
        player.togglePlayPause()
      , 300)

class KolHacampus.TracklistsIndexView extends KolHacampus.ScrollableView
  @mixin ViewMixin

class KolHacampus.TracklistsFavoritesView extends KolHacampus.ScrollableView
  @mixin ViewMixin
