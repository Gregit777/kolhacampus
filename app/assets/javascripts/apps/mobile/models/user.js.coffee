class KolHacampus.User extends KolHacampus.BaseModel
  @resourceName: 'users'
  @storageKey: 'api/mobile/v1/users'

  @persist Batman.RailsStorage

  @belongsTo 'program', polymorfic: true

  @hasMany 'posts',
    autoload: false
    saveInline: false
    inverseOf: 'user'

  # Use @encode to tell batman.js which properties Rails will send back with its JSON.
  @encode 'first_name', 'last_name', 'fullname', 'about', 'image'
  @encodeTimestamps()

