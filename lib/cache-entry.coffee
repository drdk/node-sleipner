utils = require("./utils")
_     = require("lodash")

module.exports = exports = class
  constructor: (owner, cacheKey) ->
    @key     = cacheKey
    @owner   = owner

    @data  = {}

  # Setters

  setArguments: (args) =>
    return unless args?

    error = null
    error = args['0'] if args['0']?

    # Error? Extend the current cache duration with 10 seconds
    if @data.args? and typeof @data.args is "object" and error
      @data.duration += 10000
    else
      @data = {} unless typeof @data is "object"
      @data.args  = _.clone(args)
      @data.error = error

  # Getters

  getShouldReload: =>
    return @data?.duration? and @data.duration < utils.unixtime()

  getArguments: =>
    return {} unless @data?.args? and typeof @data.args is "object"
    return @data.args

  # ...

  load: (data) =>
    @data = data

    return data?.args? and not data.error

  save: =>
    args = _.toArray(@data.args)
    
    @data.duration = @owner.newDuration.apply(@owner, args)
    @owner.sleipner.cache.set(@key, @data, @owner.newExpires.apply(@owner, args))

  toString: =>
    return JSON.stringify(@data)
