Tasks = new (Mongo.Collection)('tasks')

if Meteor.isServer
  # This code only runs on the server

  Meteor.publish 'tasks', ->
    return Tasks.find
      $or: [
        { private: $ne: true },
        { owner: @userId }
      ]

if Meteor.isClient
  # This code only runs on the client

  Meteor.subscribe 'tasks'

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
      Meteor.call('addTask', text)

      # Clear form
      event.target.text.value = ''
      return

    'change .hide-completed input': (event) ->
      Session.set 'hideCompleted', event.target.checked
      return

  Template.task.helpers
    isOwner: ->
      @owner == Meteor.userId()

  Template.task.events
    'click .toggle-checked': ->
      # Set the checked property to the opposite of its current value
      Meteor.call 'setChecked', @_id, !@checked
      return

    'click .delete': ->
      Meteor.call 'deleteTask', @_id
      return

    'click .toggle-private': ->
      Meteor.call 'setPrivate', @_id, !@private

  Accounts.ui.config
    passwordSignupFields: "USERNAME_ONLY"


# Code available in both server and client
Meteor.methods
  addTask: (text) ->
    # Make sure the user is logged in before inserting
    throw new (Meteor.Error)('not-authorized') unless Meteor.userId()

    Tasks.insert
      text: text
      createdAt: new Date     # current time
      owner: Meteor.userId()  # _id of logged in user
      username: Meteor.user().username # username of logged in user

  deleteTask: (taskId) ->
    task = Tasks.findOne taskId
    throw new (Meteor.Error)('not-authorized') if task.owner != Meteor.userId()

    Tasks.remove taskId

  setChecked: (taskId, setChecked) ->
    task = Tasks.findOne taskId
    throw new (Meteor.Error)('not-authorized') if task.private && task.owner != Meteor.userId()

    Tasks.update taskId, $set: checked: setChecked

  setPrivate: (taskId, setToPrivate) ->
    task = Tasks.findOne taskId

    # Make sure only the task owner can make a task private

    throw new (Meteor.Error)('not-authorized') unless task.owner == Meteor.userId()

    Tasks.update taskId, $set: private: setToPrivate

