class KolHacampus.BaseModel extends Batman.Model

  @on 'loading', -> KolHacampus.get('layout').fire('loading')
  @on 'loaded', -> KolHacampus.get('layout').fire('loaded')

  @find: (id, callback) ->
    cachedRecord = @_loadIdentity(id)
    if cachedRecord
      if callback
        callback(null, cachedRecord)
      else
        cachedRecord
    else
      super(id, callback)

  @where: (query, sort) ->
    r = @get('loaded').filter( (item) ->
      eq = true
      for key, value of query
        if item.get(key) isnt value
          eq = false
          break
      eq
    )
    if sort isnt undefined
      sortKey = Object.keys(sort)[0]
      sortDir = sort[sortKey]
      r.sortedBy(sortKey, sortDir)
    else
      r

  @getById: (id) ->
    @_loadIdentity(parseInt(id, 10))

  @exists: (id) ->
    @get('loaded.indexedByUnique.id').get(id) isnt undefined