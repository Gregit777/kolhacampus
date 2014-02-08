class KolHacampus.About extends KolHacampus.BaseModel
  @resourceName: 'about'
  @storageKey: 'api/mobile/v1/about'

  @encode 'id', 'text'

  @persist Batman.RailsStorage