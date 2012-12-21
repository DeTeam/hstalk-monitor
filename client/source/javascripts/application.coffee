window.App = Ember.Application.create
  socketUrl: "ws://0.0.0.0:8765"

  ready: ->
    console.log "Ember namespace is ok"

  handlers:
    default: (msg) ->
      App.get("router.tubesController").handleMessage msg

    tube: (msg) ->

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
  App.initialize()
