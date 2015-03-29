# Description:
#   Track deployment queue
#
# Dependencies:
#   None
#
# Commands:
#   hubot queue (list) - show queue for day
#   hubot queue me - add the user to queue
#   hubot queue <issue> - add issue to the queue for user
#   hubot queue remove|deployed <index> - remove the list item from queue
#   hubot queue empty - empty the queue for the day
#
# Author:
#   chrisjlebron

class EasyQueue

  constructor: (@robot) ->
    @cache = {}

    @robot.brain.on 'loaded', =>
      if @robot.brain.data.easyQueue
        @cache = @robot.brain.data.easyQueue

  kill: (item) ->
    response = 'hmmmm...'

    if item
      queue = @sort()
      listItem = queue[item - 1]

      if listItem
        delete @cache[listItem.time]
        response = "Removed item from queue"
      else
        response = 'Nah, yo... stop lyin (please specify number from queue)'
    else
      @cache = {}
      response = 'The queue has been cleared'

    @robot.brain.data.easyQueue = @cache
    response


  addItem: (person, item) ->
    timeNow = new Date()
    @cache[timeNow.toISOString()] = {'user':person, 'item':item}
    @robot.brain.data.easyQueue = @cache
    response = 'Item added to queue'

  getAll: ->
    sorted = @sort()

  # alreadyQueuedResponse: (name) ->
  #   @already_queued_response = [
  #     "#{name} is already in the queue"
  #   ]

  sort: ->
    queue = []
    # console.log @cache
    for key, val of @cache
      # console.log 'queue before'
      # console.log queue
      queue.push({ time: key, object: val })
    # console.log 'queue after'
    # console.log queue
    queue.sort (a, b) -> b.time - a.time


module.exports = (robot) ->
  easyQueue = new EasyQueue robot


  robot.hear /(queue|q) me ?([^\s]+)?$/i, (msg) ->
    person = msg.message.user.name
    item = msg.match[2]
    response = easyQueue.addItem person, item
    msg.send response


  robot.respond /(queue|q) empty$/i, (msg) ->
    response = easyQueue.kill()
    msg.send response


  robot.respond /(queue|q) (remove|deployed) ?(\d+)?$/i, (msg) ->
    args = msg.match[2]
    if not args
      msg.send 'Please specify an item in the list'
    else
      response = easyQueue.kill(args)
      msg.send response


  robot.respond /(queue|q)( list)?$/i, (msg) ->
    response = ['Today\'s Queue']
    queue = easyQueue.getAll()

    if queue.length
      for item, rank in queue
        issueText = if item.object.item then " - #{item.object.item}" else ''
        response.push "#{rank + 1}. #{item.object.user}#{issueText}"
    else
      response = ['Nothing in the queue']

    msg.send response.join("\n")
