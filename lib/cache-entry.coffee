utils = require("./utils")

module.exports = exports = class
  FRESH     = 0
  STALE     = 1
  EXCEPTION = 2

  NULL_ERROR = -1

  constructor: (owner, cacheKey) ->
    @key     = cacheKey
    @owner   = owner

    @data  = {}

  # Setters

  setArguments: (args) ->
    return unless args?

    error = null
    error = args['0'] if args['0']?

    # Error? Extend the current cache duration with 10 seconds
    if @data.args? and typeof @data.args is "object" and error
      @data.duration += 10000
    else
      @data.args  = args
      @data.error = error

  # Getters

  getShouldReload: ->
    return @data?.duration? and @data.duration < utils.unixtime()

  getArguments: ->
    return {} unless @data?.args? and typeof @data.args is "object"
    return @data.args

  # ...

  load: (data) ->
    @data = data

    return data?.args? and not data.error

  save: ->
    args = @data.args
    
    @data.duration = @owner.newDuration.apply(@owner, args)
    @owner.sleipner.cache.set(@key, @data, @owner.newExpires.apply(@owner, args))

  toString: ->
    return JSON.stringify(@data)