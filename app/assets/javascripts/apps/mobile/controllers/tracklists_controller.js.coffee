class KolHacampus.TracklistsController extends KolHacampus.ApplicationController
  routingKey: 'tracklists'

  constructor: ->
    super
    @constructor.on 'addComment', @addComment
    @on 'addTracklist', @addTracklist

  @afterAction only: "onair", ->
    @prevProgram() unless @get('tracklists.first').get('feed_items').length

  @afterAction only: 'show', (params) ->
    program_id = parseInt(params.programId, 10)
    loaded = KolHacampus.Tracklist.get('loaded.indexedBy.program_id').get(program_id).get('length')
    KolHacampus.Tracklist.load({program_id: program_id}) if loaded <= 1

  index: (params) ->
    program_id = parseInt(params.programId, 10)
    KolHacampus.Program.find program_id, (err, program) =>
      @set 'program', program
      loaded = KolHacampus.Tracklist.get('loaded.indexedBy.program_id').get(program_id).get('length')
      if loaded is 0
        KolHacampus.Tracklist.load {program_id: program_id}, (err, tracklists) =>
          tracklists.sort (a, b) -> b.get('id') - a.get('id')
          @set 'tracklists', tracklists
          @render()
      else
        @set 'tracklists', KolHacampus.Tracklist.where {program_id: program_id}
        @render()

    @render(false)

  show: (params) ->
    program_id = parseInt(params.programId, 10)
    KolHacampus.Program.find program_id, (err, program) =>
      @set 'program', program
      KolHacampus.Tracklist.find params.id, (err, tracklist) =>
        @set 'tracklist', tracklist
        player = KolHacampus.get('player')
        player.setMode 'ondemand', tracklist
        KolHacampus.get('layout').fire 'changePlayerSubview', 'track_comment'
        @render()

    @render(false)

  onair: ->
    schedule = KolHacampus.get('schedule')
    time = schedule.getCurrentTime().getTime()
    curProgId = schedule.currentProgramId()
    @set 'schedule', schedule
    @set 'tracklists', KolHacampus.Tracklist.where({publish_at: time}, {publish_at: 'asc'})
    @set 'program', KolHacampus.Program.getById(curProgId)
    KolHacampus.get('layout').fire 'changePlayerSubview', 'track_comment'
    player = KolHacampus.get('player')
    player.stop()
    player.setMode 'stream'

  favorites: ->
    @set 'tracklists', KolHacampus.FavoriteTracklist.get('all')

  # Load previous program in schedule into feed
  prevProgram: ->
    lastTracklist = @get('tracklists').get('first')
    d = new Date(lastTracklist.get('publish_at'))
    [id, time] = @get('schedule').prev(d)
    KolHacampus.Program.find(id, (err, program) =>
      unless KolHacampus.Program.exists(id)
        KolHacampus.Program.createFromJSON(program) if err is undefined
      program.loadOnAirTracklist time, (tracklist) =>
        tracklists = @get('tracklists')
        tracklists.add tracklist
        @currentView.fire('tracklist:loaded', tracklist.get('id'), tracklists.get('length'))
    )

  # Show add comments form
  showCommentForm: (btn) =>
    @commentedFeedItem = btn.id
    KolHacampus.get('layout').fire 'togglePlayerContainer'

  # Add comment from comments form to track in tracklist
  addComment: (_form) =>
    form = $(_form)
    data = form.serializeArray()
    comment = data[0]
    if @commentedFeedItem
      [tracklistId, feedItemId] = @commentedFeedItem.split('-')
      tracklist = KolHacampus.Tracklist.getById(parseInt(tracklistId, 10))
    else
      tracklist = @get('tracklists').get('last')
      feedItems = tracklist.get('feed_items')
      if feedItems.get('length')
        feedItemId = feedItems.get('last').get('id')
      else
        feedItemId = null

    if comment.value.replace(/\/s+/g,'').length
      obj =
        message: comment.value
        item_id: feedItemId

      tracklist.observeOnce 'feed_items', => @currentView.loadVisibleImages()
      tracklist.addComment(obj)

    form.find('texarea').val('')
    KolHacampus.get('layout').fire 'togglePlayerContainer'

  # Toggle tracklist's track active state
  toggleActiveTrack: (id) ->
    [tracklistId, trackId] = id.split('-')
    tracklist = KolHacampus.Tracklist.getById(tracklistId)
    feedItems = tracklist.get('feed_items')
    item = feedItems.get('indexedByUnique.id').get(trackId)
    item.set 'active', !item.get('active')

  # Adds a new tracklist to controller's tracklists set.
  # Called when a new tracklist was loaded from Application
  addTracklist: (tracklist) =>
    tracklists = @get('tracklists')
    tracklists.get('last').get('feed_items.last').set('on_air', false)
    tracklists.insertWithIndexes [tracklist], 0