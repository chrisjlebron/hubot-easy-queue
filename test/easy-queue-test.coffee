# path   = require 'path'
chai = require 'chai'
{ expect } = chai

Robot = require 'hubot/src/robot'
TextMessage = require('hubot/src/message').TextMessage

# uncomment if you need to debug hubot for tests
# process.env.HUBOT_LOG_LEVEL = 'debug'

describe 'hubot-easy-queue', ->
  robot = {}
  user1 = {}
  user2 = {}
  adapter = {}

  before (done) ->
    # this is global setup for the test
    # we'll create a robot & set up the env as we expect it
    # create new robot, without http, using the mock adapter
    robot = new Robot null, 'mock-adapter', false, 'qbot'

    robot.adapter.on 'connected', ->
      # console.log path
      # only load scripts we absolutely need, like auth.coffee
      # process.env.HUBOT_AUTH_ADMIN = '1'
      # robot.loadFile path.resolve(path.join('node_modules/hubot/src/scripts')),'auth.coffee'
      # robot.loadFile path.resolve(path.join('node_modules/hubot/scripts')),'httpd.coffee'

      # load the module under test and configure it for the
      # robot.  This is in place of external-scripts
      (require '../src/easy-queue')(robot)


      # create a user
      user1 = robot.brain.userForId "1",
        name: 'first',
        room: '#mocha'

      user2 = robot.brain.userForId "2",
        name: 'second',
        room: '#mocha'

      adapter = robot.adapter

      done()

    robot.run()

  after ->
    # Shutdown the robot after the tests are finished running
    robot.shutdown()

  afterEach ->
    # Need to remove the listeners after each test runs so they
    # don't run in duplicate, i.e. after first adapter.on, the second
    # (and third, etc.) will be added on top, but the first will keep responding
    # to each new adapter.receive
    robot.adapter.removeAllListeners()


# Might also want to consider replacing with (or adding in)
# checks against robot.brain.data.easyQueue, rather than
# text messages, as text is more liable to change
  it 'prints the help text', (done) ->
    adapter.on 'send', (envelope, strings) ->
      expect(strings[0]).to.contain('Commands:')
      done()

    adapter.receive new TextMessage user1, 'qbot queue help'

  it 'adds user to queue', (done) ->
    adapter.on 'send', (envelope, strings) ->
      expect(strings[0]).to.match(/Item added to queue\n\nDeployment Queue:\n1\. first/)
      done()

    adapter.receive new TextMessage user1, 'qbot queue me'

  it 'adds user with issue to queue', (done) ->
    adapter.on 'send', (envelope, strings) ->
      expect(strings[0]).to.match(/Item added to queue\n\nDeployment Queue:\n1\. first\n2\. second - 123/)
      done()

    adapter.receive new TextMessage user2, 'qbot queue me 123'

  it 'prints the queue', (done) ->
    adapter.on 'send', (envelope, strings) ->
      expect(strings[0]).to.match(/Deployment Queue:\n1. first\n2. second - 123/)
      done()

    adapter.receive new TextMessage user1, 'qbot queue list'

  it 'throws error when trying to remove item not in list', (done) ->
    adapter.on 'send', (envelope, strings) ->
      expect(strings[0].toLowerCase()).to.contain('please specify an item number from the list')
      done()

    adapter.receive new TextMessage user1, 'qbot queue remove 42'

  it 'removes specified item from list', (done) ->
    adapter.on 'send', (envelope, strings) ->
      expect(strings[0].toLowerCase()).to.contain('removed item from queue')
      done()

    adapter.receive new TextMessage user1, 'qbot queue remove 2'

  it 'removes top item from list', (done) ->
    adapter.on 'send', (envelope, strings) ->
      command = envelope.message.text

      # only perform assertion for the "deployed" command (ignore adding new item)
      if command.match(/deployed/)
        expect(strings[0]).to.contain('Removed item from queue\n\nDeployment Queue:\n1. second - 2')
        done()

    adapter.receive new TextMessage user2, 'qbot queue me 2'
    adapter.receive new TextMessage user2, 'qbot queue deployed'

  it 'clears all items from list', (done) ->
    adapter.on 'send', (envelope, strings) ->
      command = envelope.message.text
      queue = robot.brain.data.easyQueue

      # only perform assertion for the "deployed" command (ignore adding new item)
      if command.match(/empty/)
        expect(strings[0].toLowerCase()).to.contain('nothing in the queue')
        expect(queue).to.be.empty
        done()

    adapter.receive new TextMessage user1, 'qbot queue me 3'
    adapter.receive new TextMessage user2, 'qbot queue me 4'
    adapter.receive new TextMessage user2, 'qbot queue empty'
