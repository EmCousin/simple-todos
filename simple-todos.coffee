Tasks = new (Mongo.Collection)('tasks')

if Meteor.isClient
  Template.body.helpers
    tasks: ->
      if Session.get('hideCompleted')
        # If hide completed is checked, filter tasks
        Tasks.find { checked: $ne: true }, sort: createdAt: -1
      else
        # Otherwise, return all of the tasks
        Tasks.find {}, sort: createdAt: -1

    hideCompleted: ->
      Session.get 'hideCompleted'

    incompleteCount: ->
      Tasks.find({ checked: $ne: true }).count()

  Template.body.events
    'submit .new-task': (event) ->
      # Prevent default browser form submit
      event.preventDefault()
      #Get value from form element
      text = event.target.text.value
      # Insert a task into the collection
      Tasks.insert
        text: text
        createdAt: new Date
      # Clear form
      event.target.text.value = ''
      return

    'change .hide-completed input': (event) ->
      Session.set 'hideCompleted', event.target.checked
      return

  Template.task.events
    'click .toggle-checked': ->
      # Set the checked property to the opposite of its current value
      Tasks.update @_id, $set: checked: !@checked
      return
    'click .delete': ->
      Tasks.remove @_id
      return
