class KolHacampus.Tracklist extends KolHacampus.BaseModel
  @resourceName: 'tracklists'
  @storageKey: 'api/mobile/v1/feeds'

  @persist Batman.RailsStorage

  @belongsTo 'program'

  @encode 'id', 'start_time', 'ondemand_url', 'program_id'

  @encode 'feed_items',
    decode: (value, key, incomingJSON, outgoingObject, record) ->
      record.feedItemsAsSet(value)

    encode: (value) ->
      if value instanceof Batman.Set
        value = value.toArray()
      value.map( (v) ->
        json = if v instanceof Batman.Object then v.toJSON() else v
        delete json.active if json.hasOwnProperty('active')
        delete json.on_air if json.hasOwnProperty('on_air')
        json
      )

  @encode 'publish_at',
    decode: (value) ->
      new Date(value).getTime()

  @encode 'description',
    decode: (value) ->
      if value is null or value.trim().length is 0
        '&nbsp;'
      else
        value

  @accessor 'raw_program'

  @accessor 'onair',
    get: ->
      currentProgramId = (KolHacampus.get('schedule') || KolHacampus.Schedule.get('loaded.first')).currentProgramId()
      programId = @get('program').get('id')
      currentProgramId is programId

  @accessor 'favorite',
    get: ->
      id = @get('id')
      KolHacampus.FavoriteTracklist.get('all.indexedByUnique.id').get(id) isnt undefined

    set: (_, value) ->
      data =
        id: @get('id')
        description: @get('description')
        publish_at: @get('publish_at')
        program: @get('program')
        title: @get('title')

      KolHacampus.FavoriteTracklist.create data, (err, fav) -> fav

    unset: ->
      KolHacampus.FavoriteTracklist.find @get('id'), (err, fav) ->
        fav.destroy()

  @accessor 'title', -> [@get('program').get('name'), moment(@get('publish_at')).format("DD MMM YYYY")].join(' - ')

  @encodeTimestamps()

  # Convert feed items array to Batman.Set
  # @param {Array} feedItems feed items array to convert to Batman.Set
  # @return {Batman.Set}
  feedItemsAsSet: (feedItems) ->
    items = new Batman.Set
    for item in feedItems
      item.active = false
      items.add new Batman.Object(item)

    items.forEach (item) ->
      item.set('on_air', false)

    if @get('onair') and items.get('length') > 0
      items.get('last').set('on_air', true)

    items

  getDefaultTrack: ->
    new Batman.Object
      id: @get('id')
      track: 'On Air Now'
      artist: @get('program').get('name')
      image: @get('program').get('image').tiny.url

  # Add comment to track in tracklist
  # @param {Object} comment comment to add to track
  addComment: (comment) ->
    url = "/#{@constructor.storageKey}/#{@get('id')}"
    $.post(url, {comment: comment} , (data) =>
      res = if typeof(data) is 'string' then JSON.parse(data) else data
      feedItems = @feedItemsAsSet(res.feed_items)
      if comment.item_id
        feedItem = feedItems.get('indexedByUnique.id').get(comment.item_id)
        feedItem.set 'active', true if feedItem

      @set 'feed_items', feedItems
    )

  addFeedItems: (items) ->
    feedItems = @get('feed_items')
    indexedItems = feedItems.get('indexedByUnique.id')
    for item in items
      feedItems.add(new Batman.Object(item)) unless indexedItems.get(item.id)

    if @get('onair')
      feedItems.forEach (item) -> item.set('on_air', false)
      last = @get('feed_items.last')
      last.set('on_air', true) if last

class KolHacampus.FavoriteTracklist extends KolHacampus.BaseModel

  @resourceName: 'favorite_tracklists'
  @storageKey: 'favorite_tracklists'

  @persist Batman.LocalStorage

  @encode 'id', 'description', 'publish_at', 'program', 'title'

