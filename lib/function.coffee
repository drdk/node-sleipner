utils = require("./utils")
Queue = require("./queue")

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
    return if @options.expires isnt 0 then utils.unixtime() + parseInt(@options.expires * 1000, 10) else 0

  # Helpers: Reload logic

  start: (cb) =>
    @queue.enqueue(cb)

    if @isActive is yes
      return no 

    @isActive = yes
    return yes

  stop: (thisArg, args) =>
    while (cb = @queue.dequeue())
      cb.apply(thisArg, args)

    @isActive = no

  getIsReloading: =>
    return @isReloading is yes

  setIsReloading: (isReloading) =>
    @isReloading = isReloading

  # Rewrite original function

  rewrite: ->
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

    @cls[functionName] = (args...) ->
      cb = args.pop()
      return unless start(cb)

      cbWhenReloaded = no
      thisArg        = this

      # Generate a unqiue cache key for this type of call
      if options.cacheKey?
        if options.cacheKey instanceof Function
          cacheKey = options.cacheKey.apply(thisArg, args)
        else
          cacheKey = options.cacheKey

        return stop(thisArg, ["Invalid cache key"])
      else
        cacheKey = "#{functionName}_#{utils.stringify(arguments)}"

      # The "fake" callback used to store any result
      # we might get from the original function
      fakeCb = (error, result...) ->
        console.log "CACHE RELOADED"
        setIsReloading(no)

        if not error
          data =
            duration: generateDuration()
            value:    result
          console.log "DURATION", data.duration, "EXPIRES", generateExpires()
          sleipner.cache.set(cacheKey, data, generateExpires())

        if cbWhenReloaded
          result.unshift(error)

          stop(thisArg, result)

      fakeArgs = args.slice(0)
      fakeArgs.push(fakeCb)

      # Finally, check for cache hit
      sleipner.cache.get cacheKey, (error, data) ->
        if not error and data?.value?
          console.log "CACHE HIT"
          data.value.unshift(null)
          stop(thisArg, data.value)

          if data.duration < utils.unixtime() and not getIsReloading()
            setIsReloading(yes)
            originalFunction.apply(thisArg, fakeArgs)
        else if not getIsReloading()
          console.log "CACHE MISS"
          setIsReloading(yes)
          cbWhenReloaded = yes
          originalFunction.apply(thisArg, fakeArgs)


