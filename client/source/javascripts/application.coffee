window.App = Ember.Application.create
  socketUrl: "ws://0.0.0.0:8765"
  _socket: null

  ready: ->
    console.log "Ember namespace is ok"
    @set "_socket", App.Socket.create(url: @get("socketUrl"))

  serverSend: (msg) ->
    @get("_socket").send msg

  Router: Ember.Router.extend
    enableLogging:  true,
    root: Ember.Route.extend
      index: Ember.Route.extend
        route: "/"
        trackGeneral: ->
          App.serverSend { state: "general" }
        receiveGeneral: (router, data) ->
          console.log "general", arguments
          App.get("router.tubesController").set "content", data
          Ember.Route.transitionTo('general')(router)
        receiveTube: (router, data) ->
          App.get("router.tubeController").set "content", data
          Ember.Route.transitionTo('tube')(router, {name: data.name})

        general: Ember.Route.extend
          route: "/"
          openTube: (router, event) ->
            App.serverSend { state: "tube", tube: event.context.name }
          connectOutlets: (router, context) ->
            router.get("applicationController").connectOutlet "tubes"

        tube: Ember.Route.extend
          route: "/tube/:name"
          deserialize: (router, urlParams) ->
            App.serverSend {state: "tube", tube: urlParams.name}
            {name: urlParams.name}
          connectOutlets: (router, context) ->
            router.get("applicationController").connectOutlet "tube"

$ ->
  App.initialize()

