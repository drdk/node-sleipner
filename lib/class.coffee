sfn = require("./function")

module.exports = exports = class
  constructor: (cls, sleipner) ->
    @sleipner = sleipner
    @cls      = cls

  method: (fn, options) ->
    return new sfn(@cls::, fn, options, @sleipner)