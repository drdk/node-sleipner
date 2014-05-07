# Simple priority queue used various places ...

class PriorityQueue
  constructor: ->
    @queue = []

  # Sorting

  __better: (a, b) ->
    @queue[a].priority < @queue[b].priority

  __swap: (a, b) ->
    [@queue[a], @queue[b]] = [@queue[b], @queue[a]]

  __up: ->
    n = @queue.length - 1

    while n > 0
      parent = Math.floor((n - 1) / 2)
      return if this.__better(parent, n)
      this.__swap(n, parent)
      n = parent

  __down: ->
    max = @queue.length
    n   = 0

    while n < max
      c1 = 2*n + 1
      c2 = c1 + 1
      best = n
      best = c1 if c1 < max and this.__better(c1, best)
      best = c2 if c2 < max and this.__better(c2, best)
      return if best is n
      this.__swap(n, best)
      n = best


  # Control

  enqueue: (value, priority = 1) ->
    priority = 1 if priority < 1 or not priority instanceof Number

    @queue.push
      priority: priority
      value:    value

    this.__up()

  dequeue: ->
    return no if @queue.length is 0
    value = @queue[0].value
    last  = @queue.pop()

    if @queue.length > 0
      @queue[0] = last
      this.__down()

    return value

module.exports = exports = ->
  new PriorityQueue()
