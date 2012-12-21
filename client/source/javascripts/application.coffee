window.App = Ember.Application.create
  socketUrl: "ws://0.0.0.0:8765"
  _socket: null

  ready: ->
    console.log "Ember namespace is ok"
    @set "_socket", App.Socket.create(url: @get("socketUrl"))
    @serverSend { state: "general" }

  serverSend: (msg) ->
    @get("_socket").send msg

  Router: Ember.Router.extend
    enableLogging:  true,
    root: Ember.Route.extend
      index: Ember.Route.extend
        route: "/"
        receiveGeneral: (router, data) ->
          console.log "general", arguments
          tubes = ( Em.Object.create(name: name) for name in data.tubes)
          App.get("router.tubesController").set "content", tubes
          Ember.Route.transitionTo('general')(router)
        receiveTube: (router, data) ->
          console.log "Tube data", data

        general: Ember.Route.extend
          route: "/"
          openTube: (router, event) ->
            App.serverSend { state: "tube", tube: event.context.name }
          connectOutlets: (router, context) ->
            router.get("applicationController").connectOutlet(outletName: "tubes", name: "tubes")

        tube: Ember.Route.extend
          route: "/tube/:name"
          connectOutlets: (router, context) ->

$ ->
  App.initialize()
