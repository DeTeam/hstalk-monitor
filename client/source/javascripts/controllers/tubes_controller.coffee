App.TubesController = Ember.ObjectController.extend
  props: (->
    props = (prop for prop of @get("content")).filter((e) -> e != "state" && e != "tubes").sort()
    Em.Object.create(name: prop, value: @get("content.#{prop}")) for prop in props
  ).property("content")

  tubes: (->
    @get("content") && ( Em.Object.create(name: name) for name in @get("content.tubes")) || []
  ).property("content")
