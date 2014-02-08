class KolHacampus.PlayerView extends Batman.View

  source: Batman.helpers.underscore('layout/player')

  isContainerOpen: false

  @accessor 'currentTrack'
  @accessor 'playing'
  @accessor 'loading'
  @accessor 'canComment'
  @accessor 'favoriteTrack'
  @accessor 'mode',
    get: ->
      @get('player')?.get('mode') || @mode
    set: (_, mode) ->
      @mode = mode

  constructor: ->
    super
    @on 'changePlayerSubview', @changeSubview
    @on 'togglePlayerContainer', @toggleContainer
    KolHacampus.observeOnce 'player', @setupPlayer

    @set 'playing', false
    @set 'loading', false
    @set 'canComment', false
    @set 'favoriteTracklist', false
    @set 'mode', 'stream'

    @subviewName = null
    @currentSubview = null
    @isReady = false

  ready: ->
    @isReady = true
    @container = $(@get('node')).parent('.app-footer')

    unless @subviewName is null
      @changeSubview(@subviewName)

  setupPlayer: =>
    @player = KolHacampus.get('player')
    @player.observe 'currentTrack', @onTrackChange
    @player.observe 'mode', (mode) => @set('mode', mode)
    @player.observe 'tracklist', (tracklist) =>
      @set 'favoriteTracklist', !!tracklist?.get('favorite')

    @observePlayerEvents()

  onTrackChange: (track) =>
    @set 'currentTrack', track
    @set 'canComment', track and track.get('track') isnt 'On Air Now'

  # Change current subview. Used to append different subviews to the player view
  # View templates are found under layout/player/
  changeSubview: (name) =>
    unless @isReady
      @subviewName = name
      return

    unless @currentSubview is null
      @subviews.remove @currentSubview
      @currentSubview = null

    @currentSubview = new Batman.View
      source: Batman.helpers.underscore('layout/player/' + name)

    @subviews.add @currentSubview

  # Toggle DOM container up and down
  toggleContainer: ->
    @container.toggleClass('active')
    @isContainerOpen = !@isContainerOpen

  observePlayerEvents: ->
    @player.observe 'playing', @onPlayerPlayPause
    @player.observe 'loading', @onPlayerLoading

  playPause: ->
    @player?.togglePlayPause()

  onPlayerPlayPause: (playing) =>
    @set 'playing', playing

  onPlayerLoading: (loading) =>
    @set 'loading', loading

  skipFive: (dir, el) ->
    tgt = $(el)
    return if tgt.hasClass('disabled')
    if dir is 'back'
      @player.seek -300
    else
      @player.seek 300

  changeTrack: (dir) ->
    if dir is 'next'
      tracklist = @player.nextTracklist()
    else
      tracklist = @player.prevTracklist()

    route = "/programs/#{tracklist.get('program').get('id')}/tracklists/#{tracklist.get('id')}"
    Batman.redirect route

  addComment: ->
    return unless @get('canComment')
    @toggleContainer()

  toggleFavorite: ->
    tracklist = @player.get('tracklist')
    if tracklist.get('favorite')
      tracklist.unset('favorite')
      @set 'favoriteTracklist', false
    else
      tracklist.set('favorite')
      @set 'favoriteTracklist', true