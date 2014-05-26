utils = require("./utils")
Queue = require("./queue")
_     = require("lodash")

CacheEntry = require("./cache-entry")

module.exports = exports = class
  constructor: (cls, functionName, options, sleipner) ->
    @queue = Queue()

    @originalFunction = cls[functionName]
    @cls              = cls
    @functionName     = functionName
    @sleipner         = sleipner

    @options = options || {}

    this.for(30) unless @options.duration?
    this.expires(0) unless @options.expires?

    this.for(options.duration) if @options.duration?
    this.expires(options.expires) if @options.expires?

    this.rewrite()

  # Setters
  
  for: (duration) ->
    if duration instanceof Function
      this.newDuration = duration
    else
      @options.duration = parseInt(duration, 10) || 30

    return this

  expires: (expires) ->
    if expires instanceof Function
      this.newExpires = expires
    else
      @options.expires = parseInt(expires, 10) || 0
    
    return this

  # Helpers: Duration and expires

  newDuration: =>
    return utils.unixtime() + parseInt(@options.duration * 1000, 10)

  newExpires: =>
    return parseInt(@options.expires, 10)

  # Helpers: Reload logic

  start: (cb) =>
    @queue.enqueue(cb)

    if @isActive is yes
      return no 

    @isActive = yes
    return yes

  stop: (thisArg, args) =>
    args = _.toArray(args)
    while (cb = @queue.dequeue())
      cb.apply(thisArg, args)

    @isActive = no

  getIsReloading: =>
    return @isReloading is yes

  setIsReloading: (isReloading) =>
    @isReloading = isReloading

  # Rewrite original function

  rewrite: ->
    self = this

    functionName     = @functionName
    options          = @options
    sleipner         = @sleipner

    originalFunction = @originalFunction

    # Helper pointers
    generateDuration = this.newDuration
    generateExpires  = this.newExpires

    start = this.start
    stop  = this.stop

    getIsReloading = this.getIsReloading
    setIsReloading = this.setIsReloading

    @cls[functionName] = ->
      lastArgumentsKey = _.keys(arguments).pop()
      return unless lastArgumentsKey

      cb   = arguments[lastArgumentsKey]
      args = _.clone(arguments)

      delete args[lastArgumentsKey]

      return unless start(cb)

      executeCallbackWhenReloaded = no
      thisArg = this

      # Generate a unqiue cache key for this type of call

      if options.cacheKey?
        if options.cacheKey instanceof Function
          cacheKey = options.cacheKey.apply(thisArg, args)
        else
          cacheKey = options.cacheKey

        return stop(thisArg, ["Invalid cache key"])
      else
        cacheKey = "#{functionName}_#{originalFunction.toString()}_#{utils.stringify(arguments)}"
      
      cacheEntry = new CacheEntry(self, cacheKey)

      # The "fake" callback used to store any result
      # we might get from the original function

      args[lastArgumentsKey] = (error) ->
        setIsReloading(no)
        
        if not error
          cacheEntry.setArguments(_.clone(arguments))
          cacheEntry.save()

        stop(thisArg, _.clone(arguments)) if executeCallbackWhenReloaded

      # Finally, check for cache hit

      sleipner.cache.get cacheKey, (error, data) ->
        if not error and cacheEntry.load(data)
          stop(thisArg, cacheEntry.getArguments())

          if cacheEntry.getShouldReload() and not getIsReloading()
            setIsReloading(yes)
            originalFunction.apply(thisArg, _.toArray(args))
        else if not getIsReloading()
          setIsReloading(yes)
          executeCallbackWhenReloaded = yes
          originalFunction.apply(thisArg, _.toArray(args))


