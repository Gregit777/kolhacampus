#= require ./abstract_binding

class Batman.DOM.RadioBinding extends Batman.DOM.AbstractBinding
  @accessor 'parsedNodeValue', -> Batman.DOM.attrReaders._parseAttribute(@node.value)

  firstBind: true
  dataChange: (value) ->
    boundValue = @get 'filteredValue'
    if boundValue?
      @node.checked = (boundValue is Batman.DOM.attrReaders._parseAttribute(@node.value))
    else
      if @firstBind && @node.checked
        @set 'filteredValue', @get('parsedNodeValue')
    @firstBind = false

  nodeChange: (node) ->
    if @isTwoWay()
      @set 'filteredValue', @get('parsedNodeValue')
