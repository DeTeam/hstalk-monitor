App.TubeController = Ember.ObjectController.extend
  props: (->
    props = (prop for prop of @get("content")).filter((e) -> e != "state" && e != "name").sort()
    Em.Object.create(name: prop, value: @get("content.#{prop}")) for prop in props
  ).property("content")
  name: (->
    @get("content.name")
  ).property("content")

