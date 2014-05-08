# Sleipner
This is a caching, and general performance enhancement, library for [node.js](http://nodejs.org). Sleipner is also Odin's Eight Legged Horse.

![My little Sleipner](http://24.media.tumblr.com/tumblr_m4jjr17oGK1rwcxwko1_500.png)

* [How it works](#how)
* [Expectations](#expectations)
  * [Rewrite support](#rewrite-support)
  * [Callbacks](#callbacks)
  * [Return values: No, sorry](#return-values)
* [Usage](#usage)
  * [Providers](#providers)
  * [Caching: Instance method](#caching-instance-method)
  * [General cache](#general-cache)
* [Example](#example)

<a name="how"/>
## How it works
Sleipner works by rewriting the functions you want to be cached, generating a unique cache key based on the parameters and the function. When a successful result is returned, that result will be cached for the specified amount of time.

You can make it work with pretty much any cache system you want rather easily. See the [memcached](https://github.com/drdk/node-sleipner-memcached) provider for an example on how to do that.

<a name="expectations"/>
## Expectations
JavaScript being the way it is, I had to impose a few things and make some assumptions:

<a name="rewrite-support"/>
#### Rewrite support
For the time being, I've only implemented support for rewriting instance methods. Support for stand-alone and 'static' methods will come at a later time.

<a name="callbacks"/>
#### Callbacks
Sleipner expects the last parameter of any function cached to be a callback function. The first parameter of the callback function must be an error parameter.

<a name="return-values"/>
#### Return values: No, sorry
Given that JavaScript is asynchronous by design, caching functions returning a value is not currently supported. Some day, maybe.

<a name="usage"/>
# Usage
<a name="providers"/>
#### Providers
A provider is basically a wrapper around some kind of cache store to be used. You can make and add as many providers as you want using the follow methods:

```coffee
Sleipner.providers.add(Class Instance provider)
Sleipner.providers.remove(Class Instance provider)
```

Providers are expected to be objects, with a `get` and `set` method, looking like this:
```coffee
class CustomProvider
    get: (key, cb) ->
    set: (key, value, expires = 0) ->
```

<a name="caching-instance-method"/>
#### Caching: Instance method

To cache any instance method, all you have to do is this:
```coffee
Sleipner.method(Class cls, String functionName, Object options)
```

The `options` object can contain the following:

* `duration` (Number, default 30): The amount of time, in seconds, the result should be cached before refreshing it. While refreshing, the cached result is returned until done, given that it hasn't expired meanwhile.
* `expires` (Number, default 0): The amount of time, in seconds, the result should be cached. When expired, a refresh is requirement before returning anything. `0` means it'll never expire.
* `cacheKey` can be either a string or a function:
  * When it's a string, the supplied key is used instead of the automatically genereated one.
  * When a function, the function is called (with the incoming arguments) and is expected to return a key string.

A key is automatically genereated based on the function and the arguments supplied to it. If you, however, wish to either specify a key or return a key from a function, do it here.

<a name="general-cache"/>
#### General cache
If you want to use Sleipner for more than rewriting and caching instance methods, you can get and set cache values as you wish:

```coffee
Sleipner.cache.get(String key, Function callback)
Sleipner.cache.set(String key, Mixed value, Number expiresInSeconds)
```

<a name="example"/>
## Example
There's also a working example in the `sample` folder. `cd` to it and run `npm install && node sample.js`.

```coffee
Sleipner  = require("sleipner-js")
Memcached = require("sleipner-js-memcached")
Redis     = require("sleipner-js-redis")
Whatever  = require("sleipner-js-whatever")

# Add the caching providers we want to use
Sleipner.providers.add(new Memcached(["10.0.1.1", "10.0.1.2", "10.0.1.3"]))
Sleipner.providers.add(new Redis(["10.0.1.4", "10.0.1.5", "10.0.1.6"]))
Sleipner.providers.add(new Whatever(["10.0.1.7", "10.0.1.8", "10.0.1.9"]))

# ...

class API
    someMethod: (arg1, arg2, ..., argN, callback) ->
        # logic
        callback(error, arg1, arg2, ..., argN)

# Add the caching providers we want to use
Sleipner.providers.add(new Memcached(["127.0.0.1"]))

# Specify what to cache
Sleipner.method(API, "someMethod", duration: 30, expires: 120)
```