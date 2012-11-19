

window.App = Ember.Application.create 
  socketUrl: "ws://0.0.0.0:8765"

  ready: ->
    console.log "Ember namespace is ok"

 
  handlers:
    default: (msg) ->
      App.get("router.tubesController").handleMessage msg

    tube: (msg) ->
      

  ApplicationController: Ember.Controller.extend
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

  TubesController: Ember.ArrayController.extend
    content: []
    handleMessage: (m) ->
      data = JSON.parse(m.data)
      objects = ( Em.Object.create(name: name) for name in data.tubes)
      @set "content", objects

  ApplicationView: Ember.View.extend
    templateName: "application"


  TubesView: Em.View.extend
    templateName: "tube-list"


  Router: Ember.Router.extend
    enableLogging:  true,
    root: Ember.Route.extend
      index: Ember.Route.extend
        route: "/"
        connectOutlets: (router, context) ->
          console.log "index outlets"
          router.get("applicationController").connectOutlet(outletName: "tubes", name: "tubes")
          router.get("applicationController").setupSocket router.get("tubesController")

        general: Ember.Route.extend
          route: "/"
          connectOutlets: (router, context) ->
            router.get("applicationController").moveTo "default"

        tube: Ember.Route.extend 
          route: "/tube/:name"
          connectOutlets: (router, context) ->
            router.get("applicationController").moveTo "tube", tube: context.name

    trackGeneral: Ember.Route.transitionTo('index.general')
    openTube: Ember.Route.transitionTo('tube')

$ ->
  console.log "Init app"
  App.initialize()