class KolHacampus.TracklistsOnairView extends KolHacampus.ScrollableView

  bound: false
  scrollBottom: true

  viewDidAppear: ->
    super
    unless @bound
      @el = $(@get('node'))
      @container = @el.find('.scroll-container')
      @target = @el.find('.scroll-target')
      @addPullToRefresh()
      @attchScrollEndEvent()
      @attachedTapEvent()
      @enableTrackExpansion()
      setTimeout( =>
        @scrollToTracklist()
      , 400)

  viewWillDisappear: ->
    super
    clearTimeout(@timer) if @timer
    @removePullToRefresh()
    @detachScrollEndEvent()
    @detachTapEvent()
    @disableTrackExpansion()

  attchScrollEndEvent: ->
    $('.scroll-container').scrollend(@onContainerScrollEnd)

  detachScrollEndEvent: ->
    $('.scroll-container').scrollend('detach')

  attachedTapEvent: ->
    @hammer = Hammer(@scrollContainer)
    @onTapCallback = @scrollToActiveTrack.bind(@)
    @hammer.on('doubletap', @onTapCallback)

  detachTapEvent: ->
    @hammer.off('doubletap', @onTapCallback)

  # Setup pull to refresh for on air tracklists
  addPullToRefresh: ->
    @bound = true
    @ptf = new PullToRefresh(@target, @container, @onPullToRefresh)
    @on 'tracklist:loaded', @onTracklistLoaded

  # Remove pull to refresh from DOM
  removePullToRefresh: ->
    @ptf.cancel()
    @off 'tracklist:loaded', @onTracklistLoaded
    @bound = false

  # Handle pull to refresh events
  onPullToRefresh: =>
    setTimeout( =>
      @ptf.resetTarget()
      @controller.prevProgram()
    , 500)
    @scrollBottom = false

  # Scroll container to tracklist by ID
  scrollToTracklist: (id) =>
    if @scrollBottom
      @container[0].scrollTop = @target.height()
    else
      f = @el.find('#tracklist-'+id)
      o = f.offset()
      @container[0].scrollTop = @container[0].scrollTop + o.height - 120
    @loadVisibleImages()

  # Handle tracklist load event
  # Scrolls to loaded tracklist
  onTracklistLoaded: (id, l) =>
    @ptf.cancel() if l >= 6
    setTimeout( =>
      @scrollToTracklist(id)
    ,100)

  # Add DOM events to expand track item
  enableTrackExpansion: ->
    @el.on('click', '.toggle-active', @toggleTrack)

  # Remove DOM events to expand track item
  disableTrackExpansion: ->
    @el.off('click', '.toggle-active', @toggleTrack)

  # Toggle active track in controller by ID
  toggleTrack: (e) =>
    tgt = $(e.target)
    track = tgt.parents('.track')
    @controller.toggleActiveTrack(track.attr('id'))
    o = track.offset()
    @container[0].scrollTop = track[0].offsetTop
    @onContainerScrollEnd()

  scrollToActiveTrack: ->
    f = @el.find('.onair')
    if f[0]
      o = f.offset()
      @container[0].scrollTop = f[0].offsetTop - o.height
      @loadVisibleImages()

  onContainerScrollEnd: =>
    clearTimeout(@timer) if @timer
    @timer = setTimeout( =>
      @scrollToActiveTrack()
    , 1000 * 60 * 3)