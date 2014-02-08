#= require ../lib/polyfills/zest
#= require ../lib/polyfills/reqwest
#= require ../lib/polyfills/contains

Batman.extend Batman.DOM,
  querySelectorAll: (node, selector) ->
    zest(selector, node)

  querySelector: (node, selector) ->
    zest(selector, node)[0]

  setInnerHTML: (node, html) ->
    node?.innerHTML = html

  containsNode: (parent, child) ->
    if !child
      child = parent
      parent = document.body

    window.containsNode(parent, child)

  textContent: (node) ->
    node.textContent ? node.innerText

  destroyNode: (node) ->
    Batman.DOM.cleanupNode(node)
    node?.parentNode?.removeChild(node)

Batman.extend Batman.Request.prototype,
  _parseResponseHeaders: (xhr) ->
    headers = xhr.getAllResponseHeaders().split('\n').reduce((acc, header) ->
      if matches = header.match(/([^:]*):\s*(.*)/)
        key = matches[1]
        value = matches[2]
        acc[key] = value
      acc
    , {})

  send: (data) ->
    data ?= @get('data')
    @fire 'loading'

    options =
      url: @get 'url'
      method: @get 'method'
      type: @get 'type'
      headers: @get 'headers'

      success: (response) =>
        @mixin
          xhr: xhr
          response: response
          status: xhr?.status
          responseHeaders: @_parseResponseHeaders(xhr)

        @fire 'success', response

      error: (xhr) =>
        @mixin
          xhr: xhr
          response: xhr.responseText || xhr.content
          status: xhr.status
          responseHeaders: @_parseResponseHeaders(xhr)

        xhr.request = @
        @fire 'error', xhr

      complete: =>
        @fire 'loaded'

    if options.method in ['PUT', 'POST']
      if @hasFileUploads()
        options.data = @constructor.objectToFormData(data)
      else
        options.contentType = @get('contentType')
        options.data = Batman.URI.queryFromParams(data)

    else
      options.data = data

    # Fires the request. Grab a reference to the xhr object so we can get the status code elsewhere.
    xhr = (reqwest options).request
