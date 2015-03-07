# Description:
#   Track deployment queue
#
# Dependencies:
#   None
#
# Commands:
#   hubot queue - show queue for day
#   hubot queue me - add the user to queue, with timestamp
#   hubot dequeue me - remove the user from queue
#   hubot queue empty - empty the queue for the day
#
#   hubot queue <repo#issue> - add issue to queue for user
#   hubot dequeue <repo#issue> - dequeue an issue
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
    if item
      delete @cache[item]
    else
      delete @cache

    @robot.brain.data.easyQueue = @cache

  addUser: (person) ->
    timeNow = new Date()
    # currentHour = timeNow.getUTCHours() - (timeNow.getTimezoneOffset() / 60)
    # currentMinutes = timeNow.getUTCMinutes()
    # currentSeconds = timeNow.getUTCSeconds()
    # @cache[person] = [currentHour, ':', currentMinutes, currentSeconds, ' EST (UTC-05:00)'].join('')
    @cache[person] = timeNow
    @robot.brain.data.easyQueue = @cache

  getAll: ->
    sorted = @sort()

  alreadyQueuedResponse: (name) ->
    @already_queued_response = [
      "#{name} is already in the queue"
    ]

  sort: ->
    queue = []
    for key, val of @cache
      queue.push({ name: key, time: val })
    queue.sort (a, b) -> b.time - a.time


module.exports = (robot) ->
  easyQueue = new EasyQueue robot


  robot.hear /queue me ?(\S+[^-\s])?$/i, (msg) ->
    person = if msg.match[1] then msg.match[1].toLowerCase() else msg.message.user.name
    easyQueue.addUser person


  robot.respond /queue empty$/i, (msg) ->
    easyQueue.kill()
    msg.send 'The queue has been cleared'


  robot.respond /queue( list)?$/i, (msg) ->
    response = ['Today\'s Queue']
    queue = easyQueue.getAll()

    if queue.length
      for item, rank in queue
        response.push "#{rank + 1}. #{item.name} - #{item.time}"
    else
      response = ['Nothing in the queue']

    msg.send response.join("\n")
