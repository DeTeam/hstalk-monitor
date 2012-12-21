App.Socket = Ember.Object.extend
  url: null
  init: ->
    @_super()
    d = $.Deferred()
    socket = new WebSocket( @get("url") )
    socket.onopen = =>
      console.log "socket connected"
      d.resolve socket
    socket.onerror = ->
      console.log "socket shit happens", arguments
    socket.onclose = ->
      console.log "socket closed!", arguments
    socket.onmessage = (msg) ->
      data = JSON.parse(msg.data)
      App.get("router").send Em.String.camelize("receive_" + data.state), data
    @set "dsocket", d.promise()
  send: (msg) ->
    @get("dsocket").done (socket) ->
      socket.send JSON.stringify(msg)
