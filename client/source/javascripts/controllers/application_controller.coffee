App.ApplicationController = Ember.Controller.extend
  socket: null
  setupSocket: ->
    d = $.Deferred()
    socket = new WebSocket( App.get("socketUrl") )

    socket.onopen = =>
      @set "socket", socket
      console.log "socket connected"
      d.resolve socket

    socket.onerror = ->
      console.log "socket shit happens", arguments

    socket.onclose = ->
      console.log "socket closed!", arguments

    @set "dsocket", d.promise()

  moveTo: (state, options = {}) ->
    @get("dsocket").done =>
      socket = @get "socket"
      return unless socket
      console.log "lets move to", state
      msg = switch state
        when "default"
          { state: "general" }
        when "tube"
          socket.onmessage = App.get "handlers.tube"
          { state: "tube", tube: "default" }
      console.log "sending", msg
      socket.send JSON.stringify( _.extend(options, msg) )
      socket.onmessage = App.get("handlers.#{state}")
