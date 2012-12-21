App.TubesController = Ember.ArrayController.extend
  content: []
  handleMessage: (m) ->
    data = JSON.parse(m.data)
    objects = ( Em.Object.create(name: name) for name in data.tubes)
    @set "content", objects
