class KolHacampus.Program extends KolHacampus.BaseModel
  @resourceName: 'programs'
  @storageKey: 'api/mobile/v1/programs'

  @persist Batman.RailsStorage

  @hasMany 'users',
    autoload: false
    saveInline: false

  @hasMany 'tracklists',
    autoload: false
    saveInline: false

  # Use @encode to tell batman.js which properties Rails will send back with its JSON.
  @encode 'id', 'name', 'description', 'is_set', 'live', 'active', 'image', 'tracklist_count', 'tag_list', 'has_tracklists'
  @encodeTimestamps()

  @accessor 'tracklists', -> KolHacampus.Tracklist.where({program_id: @get('id')}, {id: 'asc'}).toArray()

  # Load the program's on air tracklist
  loadOnAirTracklist: (time, cb) =>
    d = [time.getFullYear(), time.getMonth()+1, time.getDate()].join('-')
    t = [time.getHours(),'00'].join(':')
    @constructor.fire 'loading'
    new Batman.Request
      url: "/#{@constructor.storageKey}/#{@get('id')}/feeds/at/#{d + 'T' + t}"
      type: 'json'
      success: (response) =>
        exists = KolHacampus.Tracklist.exists(response.id)
        if exists
          tl = KolHacampus.Tracklist.getById(response.id)
          feedItems = tl.get('feed_items')
          if feedItems.get('length') isnt response.feed_items.length
            tl.addFeedItems(response.feed_items)
        else
          tl = KolHacampus.Tracklist.createFromJSON(response)
        cb(tl, exists)
        @constructor.fire 'loaded'

  nextTracklist: (current) ->
    tracklists = @get('tracklists')
    l = tracklists.length
    index = @tracklistIndex(tracklists, current)
    nextIndex = if index + 1 is l then 0 else index + 1
    tracklists[nextIndex]

  prevTracklist: (current) ->
    tracklists = @get('tracklists')
    l = tracklists.length
    index = @tracklistIndex(tracklists, current)
    nextIndex = if index is 0 then l - 1 else index - 1
    tracklists[nextIndex]

  tracklistIndex: (tracklists, tracklist) ->
    curIndex = 0
    tracklists.forEach (tl, index) ->
      curIndex = index if tl.get('id') is tracklist.get('id')
    curIndex
