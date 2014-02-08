class KolHacampus.SidebarLink extends Batman.Model
  @resourceName: 'sidebar_link'
  @storageKey: 'sidebar_link'

  @encode 'route', 'label', 'icon', 'type', 'active'

  @persist Batman.MemoryStorage

  @links: [
    {route_name: 'onair', label: Batman.I18N.translate('nav',{count: 'onair_now'}), icon: 'fa-microphone', active: false, type: 'link'}
    {route_name: 'programs', label: Batman.I18N.translate('nav',{count: 'library'}), icon: 'fa-music', active: false, type: 'link'}
    {route_name: 'schedule', label: Batman.I18N.translate('nav',{count: 'schedule'}), icon: 'fa-list', active: false, type: 'link'}
    {route_name: 'tracklists.favorites', label: Batman.I18N.translate('nav',{count: 'favorites'}), icon: 'fa-star', active: false, type: 'link'}
    {route_name: 'about', label: Batman.I18N.translate('nav',{count: 'about'}), icon: 'fa-book', active: false, type: 'link'}
  ]

  # Setup sidebar links
  # Merge @links with loaded categories to create a list of navigation links for sidebar
  @setup: ->
    data = KolHacampus.get('data')
    for link, i in @links
      link.id = 'link-' + parseInt(i) + 1
      link.route = KolHacampus.get('routes').get(link.route_name)
      @createFromJSON(link).save()

    #route = KolHacampus.get('routes.categories')
    #for category in data.categories
    #  category.visible = 1
    #  record = KolHacampus.Category.createFromJSON(category)
    #  link =
    #    id: 'category-' + category.id
    #    route: route.get(record).get('posts')
    #    label: category.name
    #    icon: null
    #    active: false
    #    type: 'category'
    #  @createFromJSON(link).save()