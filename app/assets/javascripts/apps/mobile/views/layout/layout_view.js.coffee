class KolHacampus.LayoutView extends Batman.View

  @accessor 'locale',
    get: -> Batman.I18N.get('locale')
    set: (_, locale) ->
      Batman.I18N.set('locale', locale)

  constructor: ->
    super
    @on 'changePlayerSubview', (viewName) =>
      @subviews.forEach (subview) ->
        subview.fire 'changePlayerSubview', viewName
    @on 'togglePlayerContainer', =>
      @subviews.forEach (subview) ->
        subview.fire 'togglePlayerContainer'

    @on 'loading', @loading
    @on 'loaded', @loaded

  ready: ->
    @menuVisible = false
    @app = $('.app')
    @menuToggle = @get('node').querySelector('.menu-toggle .fa')
    KolHacampus.observe 'currentURL', @onURLChange

  # Handle URL changes. Dispatched by observer on App.currentURL
  onURLChange: =>
    @propagateToSubviews('urlChange')
    if @menuVisible
      setTimeout(@toggleMenu, 200)

  # Toggle sidebar menu
  toggleMenu: =>
    @app.toggleClass('show-menu')
    @menuVisible = !@menuVisible

  # Delegate an event from DOM element to a controller
  # Use data-controller-action to discern the right controller and action to call
  delegateEvent: (el, ev, view) =>
    tgt = $(el)
    [controller, action] = tgt.data('controller-action').split('.')
    KolHacampus[controller].fire action, tgt

  loading: =>
    @menuToggle?.classList.remove('fa-bars')
    @menuToggle?.classList.add('fa-spinner')
    @menuToggle?.classList.add('fa-spin')

  loaded: =>
    @menuToggle?.classList.remove('fa-spinner')
    @menuToggle?.classList.remove('fa-spin')
    @menuToggle?.classList.add('fa-bars')

  # Change locale based on state of locale changer checkbox in sidebar
  changeLocale: (el) ->
    checked = $(el).prop('checked')
    loc = if checked then 'en' else 'he'
    @set 'locale', loc
    $.fn.cookie('locale', loc, { expires: 365 })
    setTimeout( ->
      self.location.reload()
    ,400)
