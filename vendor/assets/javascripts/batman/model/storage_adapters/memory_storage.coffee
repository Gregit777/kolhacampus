class MemoreStore

  constructor: ->
    @store = {}

  setItem: (key, value) ->
    @store[key] = value
    value

  getItem: (key) ->
    @store[key]

  removeItem: (key) ->
    delete @store[key]

  key: (i) ->
    Object.keys(@store)[i]

class Batman.MemoryStorage extends Batman.LocalStorage

  constructor: ->
    super
    @storage = new MemoreStore()