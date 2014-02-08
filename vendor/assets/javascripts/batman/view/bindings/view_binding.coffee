#= require ./abstract_binding

class Batman.DOM.ViewBinding extends Batman.DOM.AbstractBinding
  onlyObserve: Batman.BindingDefinitionOnlyObserve.Data
  skipChildren: true
  bindImmediately: false

  constructor: (definition) ->
    @superview = definition.view
    super

  initialized: ->
    @bind()

  dataChange: (viewClassOrInstance) ->
    @viewInstance?.removeFromSuperview()

    return if not viewClassOrInstance
    if viewClassOrInstance.isView
      @fromViewClass = false
      @viewInstance = viewClassOrInstance
      @viewInstance.removeFromSuperview()
    else
      @fromViewClass = true
      @viewInstance = new viewClassOrInstance

    @node.removeAttribute('data-view')

    if options = @viewInstance.constructor._batman.get('options')
      for option in options
        attributeName = "data-view-#{option.toLowerCase()}"
        if keyPath = @node.getAttribute(attributeName)
          @node.removeAttribute(attributeName)
          definition = new Batman.DOM.ReaderBindingDefinition(@node, keyPath, @superview)
          new Batman.DOM.ViewArgumentBinding(definition, option, @viewInstance)

    @viewInstance.set('parentNode', @node)
    @viewInstance.set('node', @node)
    @viewInstance.loadView(@node)

    @superview.subviews.add(@viewInstance)

  die: ->
    if @fromViewClass
      @viewInstance.die()
    else
      @viewInstance.removeFromSuperview()

    @superview = null
    @viewInstance = null
    super

class Batman.DOM.ViewArgumentBinding extends Batman.DOM.AbstractBinding
  onlyObserve: Batman.BindingDefinitionOnlyObserve.Data

  constructor: (definition, @option, @targetView) ->
    super(definition)

    @targetView.observe @option, @_updateValue = (value) =>
      return if @isDataChanging
      @view.setKeypath(@keyPath, value)

  dataChange: (value) ->
    @isDataChanging = true
    @targetView.set(@option, value)
    @isDataChanging = false

  die: ->
    @targetView.forget(@option, @_updateValue)
    @targetView = null
    super
