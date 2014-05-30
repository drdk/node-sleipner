class Stats
  constructor: ->
    console.log "STATS INITIALIZED"
    @totalRequests = 0
    @totalTime     = 0.0

    @timers = {}
    @stats  =
      requests:      0
      total_seconds: 0.0
      average:       0.0
      longest:       []
      shortest:      []

    setInterval(this.average, 5 * 60 * 1000)

  average: =>
    @stats.average = @totalTime / @totalRequests
    @totalTime     = 0
    @totalRequests = 0

  start: (key) ->
    return if @timers[key]?
    @timers[key] = Date.now()

  stop: (key) ->
    return unless @timers[key]?
    total = (Date.now() - @timers[key]) / 1000
    delete @timers[key]

    @totalTime += total
    @totalRequests++

    @stats.requests++
    @stats.total_seconds += total
    @stats.longest.push(key: key, time: total)
    @stats.shortest.push(key: key, time: total)
    this.sortAndPurge()


  sortAndPurge: ->
    @stats.shortest.sort (a, b) ->
      return a.time - b.time

    @stats.longest.sort (a, b) ->
      return b.time - a.time

    @stats.longest  = @stats.longest.splice(0, 10)
    @stats.shortest = @stats.shortest.splice(0, 10)

  get: ->
    return @stats

module.exports = exports = ->
  return new Stats()