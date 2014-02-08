#= require_self

#= require_tree ./lib
#= require_tree ./helpers
#= require_tree ./controllers
#= require_tree ./models
#= require_tree ./views

Batman.config.pathToHTML = '/assets/apps/mobile/html'

class KolHacampus extends Batman.App

  # get rid of DOM flicker
  Batman.DOM.Yield.clearAllStale = -> {}

  @layout: 'layout'

  # @resources 'products'
  # @resources 'discounts', except: ['edit']
  # @resources 'customers', only: ['new', 'show']

  @resources 'posts', only: ['show']

  @resources 'categories', ->
    @resources 'posts', only: ['index']

  @resources 'programs', only: ['index'], ->
    @resources 'tracklists', only: ['index', 'show']

  @resources 'tracklists', only: ['show'], ->
    @collection 'favorites'
  # @resources 'pages', ->
  #   @collection 'count'
  #   @member 'duplicate'

  @route '/about', 'about#index', as: 'about'
  @route '/schedule', 'schedule#index', as: 'schedule'
  @route '/', 'tracklists#onair', as: 'onair'
  # @route 'apps/private', 'apps#private', as: 'privateApps'

  @root 'onair#index'

  @classAccessor 'retina',
    get: ->
      mediaQuery = "(-webkit-min-device-pixel-ratio: 1.5), (min--moz-device-pixel-ratio: 1.5), (-o-min-device-pixel-ratio: 3/2), (min-resolution: 1.5dppx)"
      return true if window.devicePixelRatio > 1
      return true if window.matchMedia and window.matchMedia(mediaQuery).matches
      false

  @classAccessor 'data'

  @classAccessor 'schedule'

  @classAccessor 'currentController',
    get: ->
      c = @get('currentRoute').get('controller')
      @get('controllers').get(c)

  @classAccessor 'currentTrack'

  # Initialize application data
  @initData: =>
    @set 'logger', new Logger()
    data = @get('data')
    data.current.tracklist.on_air = true
    data.schedule.tz_offset = data.tz_offset
    KolHacampus.Schedule.createFromJSON(data.schedule)
    KolHacampus.Program.createFromJSON(data.current.program)
    KolHacampus.Tracklist.createFromJSON(data.current.tracklist)
    @set 'schedule', KolHacampus.Schedule.get('loaded.first')
    @setupCSRF()
    @initPlayer()

  # Setup CSRF headers for XHR requests
  @setupCSRF: ->
    token = $("meta[name='csrf-token']").attr("content")
    headers = $.extend($.ajaxSettings.headers or {}, {"X-CSRF-Token": token})
    $.ajaxSettings.headers = headers

  @on 'run', @initData

  @initPlayer: ->
    @set 'player', new KolHacampus.AudioPlayer

(global ? window).KolHacampus = KolHacampus
