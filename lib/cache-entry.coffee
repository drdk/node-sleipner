utils = require("./utils")
_     = require("lodash")

module.exports = exports = class
  constructor: (owner, cacheKey) ->
    @key     = cacheKey
    @owner   = owner
    @logger  = @owner.sleipner.logger

    @data  = {}

  # Setters

  setArguments: (args) =>
    return unless args?

    error = null
    error = args['0'] if args['0']?

    # Error? Extend the current cache duration with 30 seconds
    if @data.args? or typeof @data.args is "object" and error
      @data.duration = utils.unixtime() + 30 * 1000
      @logger.error "Tried to set erroneous arguments (#{error.toString()}) of a - before - valid cache (extending duration with 30 seconds from now)"
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
    args  = _.toArray(@data.args)
    error = args[0] if args instanceof Array
    error = yes if not args? or not args instanceof Array

    if not error
      @data.duration = @owner.newDuration.apply(@owner, args)
      @owner.sleipner.cache.set(@key, @data, @owner.newExpires.apply(@owner, args))

  toString: =>
    return JSON.stringify(@data)
