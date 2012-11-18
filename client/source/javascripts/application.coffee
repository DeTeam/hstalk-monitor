

window.App = Ember.Application.create 
  socketUrl: "ws://0.0.0.0:8765"

  ready: ->
    console.log "Ember namespace is ok"

  ApplicationController: Ember.Controller.extend
    socket: null
    setupSocket: (logger) ->
      socket = new WebSocket( App.get("socketUrl") )
      socket.onopen = -> console.log "socket connected"
      socket.onmessage = (message) ->
        logger.handleMessage message
      socket.onerror = ->
        console.log "socket shit happens", arguments
      socket.onclose = ->
        console.log "socket closed!", arguments

      @set "socket", socket

    moveTo: (state) ->
      socket = @get "Socket"
      return unless socket
      switch state 
        when "default"
          socket.send JSON.stringify( state: "general" )
        when "tube"
          socket.send JSON.stringify( state: "tube", tube: "default" )

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
          router.get("applicationController").connectOutlet("logger")
          router.get("applicationController").setupSocket router.get("loggerController")
          router.get("applicationController").moveTo "default"

      defaultTube: Ember.Route.extend
        route: "default_tube"
        connectOutlet: (router, context) ->
          router.get("applicationController").moveTo "tube"

      trackGeneral: Ember.Route.transitionTo('index')
      trackDefaultTube: Ember.Route.transitionTo('defaultTube')

$ ->
  console.log "Init app"
  App.initialize()