zlib   = require("zlib")
crypto = require("crypto")

module.exports = exports =
  assert: (condition, message = "Assertion failed") ->
    throw new AssertionError(message) if not condition
  
  hash: (input) ->
    return crypto.createHash("sha256").update(input).digest("hex")

  unixtime: ->
    return Date.now()

  stringifyFn: (key, value) ->
    return value.toString() if value instanceof Function
    return value

  stringify: (inputs...) ->
    result = ""

    for input in inputs
      if typeof(input) is "object"
        result += JSON.stringify(input, this.stringifyFn)
      else
        result += input

    return result

  zip: (input, cb) ->
    zlib.deflate input, (error, buffer) ->
      if error
        cb(error)
      else
        buffer = buffer.toString("base64")
        try
          buffer = JSON.parse(buffer)
        catch e
          # ...
        
        cb(null, buffer)

  unzip: (input, cb) ->
    input = new Buffer(input, "base64") if typeof input is "string"
    zlib.unzip input, (error, buffer) ->
      if error or not buffer
        cb(error)
      else
        buffer = buffer.toString()

        # JSON?
        try
          buffer = JSON.parse(buffer)
        catch e
          # ...
        
        cb(null, buffer)