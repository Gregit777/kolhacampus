class KolHacampus.SidebarView extends Batman.View

  source: Batman.helpers.underscore('layout/sidebar')

  @accessor 'mailto', -> 'mailto:info@106fm.co.il?subject=106fm - Contact Us'
  ready: ->
    links = KolHacampus.get('controllers.application').getSidebarLinks()
    @set 'links', links
    @on 'urlChange', @checkCurrentRoute

  checkCurrentRoute: =>
    currentPath = KolHacampus.get('currentURL')
    active = @get('links.indexedByUnique.active').get(true)
    active.set('active', false) if active
    @get('links').forEach (link) ->
      path = link.get('route').get('path')
      if currentPath is path or (currentPath.indexOf(path) > -1 and path isnt '/')
        link.set('active', true)