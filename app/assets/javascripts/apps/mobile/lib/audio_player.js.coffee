class KolHacampus.AudioPlayer extends Batman.Object

  @accessor 'playing'
  @accessor 'mode'
  @accessor 'ready'
  @accessor 'loaded'
  @accessor 'canplay'
  @accessor 'tracklist'
  @accessor 'trackUpdater'
  @accessor 'currentTrack'
  @accessor 'position'
  @accessor 'duration'

  streamURL: 'http://212.29.254.129:7075/;'

  constructor: ->
    @set 'playing', false
    @set 'canplay', false
    @set 'loading', false
    @set 'ready',   false
    @set 'mode',    'stream'

    that = @
    new Audio5js(
      swf_path: '/assets/audio5js.swf'
      codecs: ['mp4', 'mp3'],
      throw_errors: false,
      format_time: false
      ready: ->
        that.playerReady(@)
    )

  playerReady: (player) ->
    @set 'ready', true
    @player = player
    @addPlayerEvents()
    @set 'trackUpdater', new TrackUpdater(@)

  addPlayerEvents: ->
    @player.on('canplay', @playerCanPlay)
    @player.on('play', @playerPlay)
    @player.on('pause', @playerPause)
    @player.on('ended', @playerEnded)
    @player.on('error', @onPlayerError)
    @player.on('timeupdate', @updatePlayerPosition)

  playerCanPlay: =>
    @player.play()
    @loadCount = 0
    @set 'loading', false
    @set 'canplay', true
    @get('trackUpdater').checkCurrentTrack()

  playerPlay: =>
    @set 'playing', true

  playerPause: =>
    @set 'playing', false

  playerEnded: =>
    @set 'loading', false
    @set 'playing', false
    @set 'canplay', false

  updatePlayerPosition: (pos, dur) =>
    @set 'position', pos
    @set 'durection', dur

  setMode: (mode, tracklist = null) ->
    @set 'mode', mode
    @set 'tracklist', tracklist
    @get('trackUpdater').checkCurrentTrack()

  prevTracklist: ->
    current = @get('tracklist')
    prev = current.get('program').prevTracklist(current)
    @stop()
    @setMode 'ondemand', prev
    @togglePlayPause()
    prev

  nextTracklist: ->
    current = @get('tracklist')
    next = current.get('program').nextTracklist(current)
    @stop()
    @setMode 'ondemand', next
    @togglePlayPause()
    next

  loadAudio: (url) ->
    @loadCount or= 0
    @set 'loading', true
    @player.load(url)
    @loadCount += 1

  onPlayerError: =>
    @playerEnded()
    if @loadCount > 20
      @loadCount = 0
    else
      setTimeout( =>
        @loadAudio(@streamURL)
      , 200)

  stop: ->
    @player.pause()
    @playerEnded()

  togglePlayPause: ->
    if @get('ready') and @get('canplay')
      @player?.playPause()
    else
      if @get('mode') is 'stream'
        @loadAudio @streamURL
      else
        @loadAudio @get('tracklist').get('ondemand_url')

  seek: (time) ->
    if @get('mode') is 'ondemand' and @get 'playing'
      pos = @player.position
      @player.seek Math.max(pos + time, 0)

class TrackUpdater extends Batman.Object

  interval: 30
  timer: null

  constructor: (player) ->
    super
    @set 'player', player
    @checkCurrentTrack()

  # Check currently playing track
  # If player is in stream mode, checks current on air now track.
  # If player is in ondemand mode, check currently playing track from tracklist
  checkCurrentTrack: =>
    unless @timer is null
      clearTimeout(@timer)
      @timer = null

    if @get('player').get('mode') is 'stream'
      @checkOnAirTrack()
    else
      @checkOnDemandTrack()

  # Check current on air now track
  checkOnAirTrack: ->
    if KolHacampus.get('currentRoute') is undefined
      @timer = setTimeout @checkCurrentTrack, 2 * 1000
      return
    schedule = KolHacampus.get('schedule')
    time = schedule.getCurrentTime()
    curProgId = schedule.currentProgramId()
    KolHacampus.Program.find(curProgId, (err, program) =>
      unless KolHacampus.Program.exists(curProgId)
        KolHacampus.Program.createFromJSON(program)
      program.loadOnAirTracklist time, (tracklist, update) =>
        currentController = KolHacampus.get('currentController')
        if currentController.get('tracklists') and not update
          currentController.fire 'addTracklist', tracklist

        @updateOnAirTrack(tracklist)
        @timer = setTimeout @checkCurrentTrack, @interval * 1000
    )

  # Check current ondemand track
  checkOnDemandTrack: ->
    player = @get('player')
    tracklist = player.get('tracklist')
    [hour, minute] = tracklist.get('start_time').split(':').map (s) -> parseInt(s, 10)
    startTime = moment({hour: hour, minute: minute})
    curTime = startTime.add('s', player.get('position') or 0)
    curTimeStr = curTime.format('HH:mm:ss')
    feed_items = tracklist.get('feed_items')
    remaning = feed_items.filter (item) -> item.get('start_time') <= curTimeStr
    current = remaning.get('last')
    prev = feed_items.get('indexedByUnique.on_air').get(true)
    prev.set('on_air', false) if prev
    if current
      current.set 'on_air', true
      player.set 'currentTrack', current
    @timer = setTimeout @checkCurrentTrack, (@interval / 2) * 1000

  # Update on air now track
  updateOnAirTrack: (tracklist) ->
    player = @get('player')
    onAir = tracklist.get('feed_items').get('indexedByUnique.on_air').get(true)
    onAir = tracklist.getDefaultTrack() if not onAir

    currentTrack = player.get('currentTrack')
    if not currentTrack
      player.set 'currentTrack', onAir
    else if currentTrack.get('id') isnt onAir.get('id')
      player.set 'currentTrack', onAir