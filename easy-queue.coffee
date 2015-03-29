# Description:
#   Track deployment queue
#
# Dependencies:
#   None
#
# Commands:
#   hubot queue - show queue for day
#   hubot queue me - add the user to queue, with timestamp
#   hubot queue <issue> - add issue to the queue for user, with timestamp
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
    console.log @cache
    console.log @robot.brain
    if item
      delete @cache[item]
    else
      delete @cache

    @robot.brain.data.easyQueue = @cache


# @TODO: thinking items should be added to queue with ID instead of key. This
#        would allow for multiple deploys per person, and would simplify sorting,
#        but would make individual deletion more difficult. Alternately, could
#        modify cache so that if key (person) already exists, we add index to
#        both (depending on timestamp)

  addItem: (person, item) ->
    timeNow = new Date()
    # currentHour = timeNow.getUTCHours() - (timeNow.getTimezoneOffset() / 60)
    # currentMinutes = timeNow.getUTCMinutes()
    # currentSeconds = timeNow.getUTCSeconds()
    # @cache[person] = [currentHour, ':', currentMinutes, currentSeconds, ' EST (UTC-05:00)'].join('')
    @cache[timeNow.toISOString()] = {'user':person, 'item':item}
    @robot.brain.data.easyQueue = @cache

  getAll: ->
    sorted = @sort()

  # alreadyQueuedResponse: (name) ->
  #   @already_queued_response = [
  #     "#{name} is already in the queue"
  #   ]

  sort: ->
    queue = []
    console.log @cache
    for key, val of @cache
      console.log 'queue before'
      console.log queue
      queue.push({ time: key, object: val })
    console.log 'queue after'
    console.log queue
    queue.sort (a, b) -> b.time - a.time


module.exports = (robot) ->
  easyQueue = new EasyQueue robot


  robot.hear /(queue|q) me ?(\S+[^-\s])?$/i, (msg) ->
    person = msg.message.user.name
    item = if msg.match[2] then msg.match[2].toLowerCase()
    easyQueue.addItem person, item


  robot.respond /(queue|q) empty$/i, (msg) ->
    easyQueue.kill()
    msg.send 'The queue has been cleared'


  robot.respond /(queue|q) remove ?(\d+)?$/i, (msg) ->
    args = msg.match[1]
    if not args then msg.send 'Please specify an item in the list'
    easyQueue.kill(args)


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
