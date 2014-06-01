utils = require("./utils")
scls  = require("./class")
CacheStats = require("./cache-stats")

cacheProviders = []

cacheSetStats = CacheStats()
cacheGetStats = CacheStats()

module.exports = exports =
  logger: console

  method: (cls, fn, options = {}) ->
    result = new scls(cls, this)
    return result.method(fn, options)

  # Cache

  cache:
    set: (key, value, expires = 0) ->
      return if cacheProviders.length is 0
      key = utils.hash(key)
      cacheSetStats.start(key)

      try
        value = JSON.stringify(value, utils.stringifyFn)
      catch e
        # ...

      utils.zip value, (error, buffer) ->
        if not error
          for provider in cacheProviders
            provider.set(key, buffer, expires)

        cacheSetStats.stop(key)

    get: (key, cb) ->
      return cb("No providers added") if cacheProviders.length is 0
      key = utils.hash(key)
      cacheGetStats.start(key)

      returned = no
      count    = cacheProviders.length

      triggerCb = (error, value) ->
        return if (error and count isnt 0) or returned
        cacheGetStats.stop(key)
        returned = yes
        cb(error, value)

      for provider in cacheProviders
        return if returned
        count--

        provider.get key, (error, data) ->
          if not error
            utils.unzip data, (error, data) ->
              return triggerCb("Failed to unzip data") if error
              triggerCb(null, data)
          else
            triggerCb(error)

  # Provider control

  providers:
    add: (provider) ->
      return if not provider? or typeof(provider) isnt "object" or not provider["get"]? or not provider["set"]?
      cacheProviders.push(provider)

    remove: (provider) ->
      n = cacheProviders.indexOf(provider)
      if n isnt -1
        cacheProviders.splice(n, 1)

  stats: ->
    result =
      cache_stats:
        set: cacheSetStats.get()
        get: cacheGetStats.get()

    return result