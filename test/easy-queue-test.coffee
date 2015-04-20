# path   = require 'path'
chai = require 'chai'
{ expect } = chai

Robot = require 'hubot/src/robot'
TextMessage = require('hubot/src/message').TextMessage

process.env.HUBOT_LOG_LEVEL = 'debug'

describe 'hubot-easy-queue', ->
  robot = {}
  user1 = {}
  user2 = {}
  adapter = {}

  before (done) ->
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
    robot.shutdown()

  afterEach ->
    robot.adapter.removeAllListeners()


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
