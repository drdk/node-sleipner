Sleipner  = require("sleipner-js")
Memcached = require("sleipner-js-memcached")
# ...
request = require("request")
express = require("express")
app     = express()

class OpenWeatherAPI
  currentWeather: (city, cb) ->
    request "http://api.openweathermap.org/data/2.5/weather?q=#{city}", (error, response, body) ->
      if not error and response.statusCode is 200
        cb(null, JSON.parse(body))
      else
        cb(error || "Something bad happened. :-(")

# Add the caching providers we want to use
Sleipner.providers.add(new Memcached(["127.0.0.1"]))

# Specify what to cache
Sleipner.method(OpenWeatherAPI, "currentWeather", duration: 30, expires: 120)

module.exports = exports = ->
  app.get "/:city?", (req, res) ->
    api = new OpenWeatherAPI()
    req.params.city ||= "London"
    req.params.city   = req.params.city.charAt(0).toUpperCase() + req.params.city.slice(1)
    api.currentWeather req.params.city, (error, weatherData) ->
      if not error and (current = weatherData.weather?.shift())?
        res.send(200, """
          <h1>Weather report for #{weatherData.name}, #{weatherData.sys.country}</h1>
          <p>Currently #{current.description} with a temperature of #{Math.round(-272.15 + parseFloat(weatherData.main.temp))} &deg;C.</p>
          <p>The cloud cover is about #{weatherData.clouds.all}&#37; and there's an average windspeed of #{weatherData.wind.speed} m/s.</p>
          """)
      else
        res.send(500, error);

  app.listen(process.env.PORT || 3000)