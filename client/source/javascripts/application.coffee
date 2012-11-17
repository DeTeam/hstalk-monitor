

window.App = Ember.Application.create 
  socketUrl: "ws://0.0.0.0:8765"

  ready: ->
    console.log "Ember namespace is ok"

  ApplicationController: Ember.Controller.extend
    socket: null
    setupSocket: (logger) ->
      socket = new WebSocket( App.get("socketUrl") )
      this.set "socket", socket
      socket.onopen = ->
        console.log "socket opened"
      socket.onmessage = (message) ->
        console.log "receive message", message
        logger.handleMessage message

  LoggerController: Ember.ArrayController.extend
    content: []
    handleMessage: (m) ->
      obj = Ember.Object.create raw: m.data
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

$ ->
  console.log "Init app"
  App.initialize()