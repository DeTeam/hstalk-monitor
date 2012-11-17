

window.App = Ember.Application.create 
  socketUrl: "ws://0.0.0.0:8765"

  ready: ->
    console.log "Ember namespace is ok"

  ApplicationController: Ember.Controller.extend
    socket: null
    setupSocket: (logger) ->
      socket = new WebSocket( App.get("socketUrl") )
      socket.onopen = ->
        socket.send "beanstalk"
      socket.onmessage = (message) ->
        logger.handleMessage message
      socket.onerror = ->
        console.log "socket shit happens", arguments
      socket.onclose = ->
        console.log "socket closed!", arguments

      this.set "socket", socket

  LoggerController: Ember.ArrayController.extend
    content: []
    handleMessage: (m) ->
      obj = Ember.Object.create JSON.parse(m.data)
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