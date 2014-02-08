Batman.LifecycleEvents =
  initialize: ->
    @::fireLifecycleEvent = fire

  lifecycleEvent: (eventName, normalizeFunction) ->
    beforeName = "before#{Batman.helpers.camelize(eventName)}"
    afterName = "after#{Batman.helpers.camelize(eventName)}"

    addCallback = (lifecycleEventName) ->
      (callbackName, options) ->
        if Batman.typeOf(callbackName) == 'Object'
          [callbackName, options] = [options, callbackName]

        if Batman.typeOf(callbackName) == 'String'
          callback = -> @[callbackName].apply(this, arguments)
        else
          callback = callbackName

        options = normalizeFunction?(options) || options

        target = @prototype || this
        Batman.initializeObject(target)

        handlers = target._batman[lifecycleEventName] ||= []
        handlers.push(options: options, callback: callback)

    @[beforeName] = addCallback(beforeName)
    @::[beforeName] = addCallback(beforeName)

    @[afterName] = addCallback(afterName)
    @::[afterName] = addCallback(afterName)

fire = (lifecycleEventName, args...) ->
  return unless handlers = @_batman.get(lifecycleEventName)

  for {options, callback} in handlers
    continue if options?.if and !options.if.apply(this, args)
    continue if options?.unless and options.unless.apply(this, args)
    return false if callback.apply(this, args) == false
