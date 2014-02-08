class Logger
  logLevel: 'debug'
  environment: 'development'

  debug: (args...) ->
    @log('debug',args) if ['debug'].indexOf(@logLevel) > -1

  warn: (args...) ->
    @log('warn',args) if ['debug','warn'].indexOf(@logLevel) > -1

  error: (args...) ->
    if ['debug','warn','error'].indexOf(@logLevel) > -1
      @log('error',args)

  log: (level, args) ->
    args.unshift "(#{level})"
    console?.log.apply(console, args)

@Logger = Logger