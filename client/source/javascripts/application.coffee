

window.App = Ember.Application.create 
  socketUrl: "ws://0.0.0.0:8765"

  ready: ->
    console.log "Ember namespace is ok"

  ApplicationController: Ember.Controller.extend
    socket: null
    setupSocket: (logger) ->
      d = $.Deferred()
      socket = new WebSocket( App.get("socketUrl") )
      socket.onopen = =>
        @set "socket", socket
        console.log "socket connected"
        d.resolve()
      socket.onmessage = (message) ->
        logger.handleMessage message
      socket.onerror = ->
        console.log "socket shit happens", arguments
      socket.onclose = ->
        console.log "socket closed!", arguments

      @set "dsocket", d.promise()

    moveTo: (state) ->
      @get("dsocket").done =>
        socket = @get "socket"
        return unless socket
        console.log "lets move to", state
        msg = switch state 
          when "default"
            JSON.stringify( state: "general" )
          when "tube"
            JSON.stringify( state: "tube", tube: "default" )
        console.log "sending", msg
        blob = new Blob([msg])
        socket.send msg

  LoggerController: Ember.ArrayController.extend
    content: []
    handleMessage: (m) ->
      obj = Ember.Object.create JSON.parse(m.data)
      console.log obj
      this.pushObject obj

  ApplicationView: Ember.View.extend
    templateName: "application"

  LoggerView: Ember.View.extend
    templateName: "logger"

  Router: Ember.Router.extend
    enableLogging:  true,
    root: Ember.Route.extend
      index: Ember.Route.extend
        route: "/"
        connectOutlets: (router, context) ->
          console.log "index outlets"
          router.get("applicationController").connectOutlet("logger")
          router.get("applicationController").setupSocket router.get("loggerController")

        general: Ember.Route.extend
          route: "/"
          connectOutlets: (router, context) ->
            router.get("applicationController").moveTo "default"

        defaultTube: Ember.Route.extend 
          route: "/tube"
          connectOutlets: (router, context) ->
            router.get("applicationController").moveTo "tube"

    trackGeneral: Ember.Route.transitionTo('index.general')
    trackDefaultTube: Ember.Route.transitionTo('index.defaultTube')

$ ->
  console.log "Init app"
  App.initialize()