class KolHacampus.Category extends KolHacampus.BaseModel
  @resourceName: 'category'
  @storageKey: 'category'

  @encode 'name', 'visible'

  @persist Batman.MemoryStorage

  @hasMany 'posts',
    autoload: false
    saveInline: false
    inverseOf: 'category'