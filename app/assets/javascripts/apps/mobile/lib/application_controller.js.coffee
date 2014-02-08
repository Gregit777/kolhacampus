class KolHacampus.ApplicationController extends Batman.Controller

  # Prepare sidebar links for Layout
  getSidebarLinks: ->
    KolHacampus.SidebarLink.setup()
    KolHacampus.SidebarLink.get('all')