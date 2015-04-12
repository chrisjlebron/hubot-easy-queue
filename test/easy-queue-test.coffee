expect = require 'chai'
{ expect } = chai
# path   = require('path')

Robot = require 'hubot/src/robot'
TextMessage = require('hubot/src/message').TextMessage

describe 'hubot-easy-queue', ->
  robot = null
  user = null
  adapter = null

  beforeEach (done) ->
    # create new robot, without http, using the mock adapter
    robot = new Robot null, 'mock-adapter', false, 'TestBot'

    robot.adapter.on 'connected', ->
      # only load scripts we absolutely need, like auth.coffee
      process.env.HUBOT_AUTH_ADMIN = '1'
      robot.loadFile(path.resolve(path.join('node_modules/hubot/src/scripts')),'auth.coffee')

      # load the module under test and configure it for the
      # robot.  This is in place of external-scripts
      require("../index")(robot);

      # create a user
      user = robot.brain.userForId "1",
        name: 'mocha',
        room: '#mocha'

      adapter = robot.adapter

      done()

    robot.run()

  afterEach ->
    robot.shutdown()

  it 'responds when greeted', (done) ->
    # here's where the magic happens!
    adapter.on 'reply', (envelope, strings) ->
      expect strings[0].match(/Why hello there/)
      done()

      adapter.receive new TextMessage user, 'Computer!'
