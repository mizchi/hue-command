hue = require 'node-hue-api'
fs = require 'fs'
Promise = require 'bluebird'
_ = require 'lodash'
onecolor = require 'onecolor'

configPath = process.env.HOME+'/.hue.json'
api = null

getBridgeIp = -> new Promise (done) ->
  hue.locateBridges()
    .then (bridges) ->
      b = bridges[0]
      done b.ipaddress
    .done()

register = ->
  api = new hue.HueApi()
  getBridgeIp().then (ip) ->
    api.registerUser(ip, null, null)
      .then (username) ->
        fs.writeFileSync configPath, JSON.stringify({ip, username})
        console.log 'write file to', configPath
      .fail -> console.log 'register failed'
      .done()
getLigths = -> new Promise (done) ->
  api.connect().then (result) ->
    # console.log 'result', result
    api.lights().then (lights) ->
      # console.log 'lights',lights
      done(lights)
    .done()
  .done()

onLights = (opts = {}) -> new Promise (done) ->
  getLigths().then ({lights}) ->
    Promise.all(lights.map (light) -> new Promise (done) ->
      color =
        if opts.color
          rgb = onecolor(opts.color).rgb()
          [
            ~~(rgb.r()*255)
            ~~(rgb.g()*255)
            ~~(rgb.b()*255)
          ]
        else
          [
            '255'
            '255'
            '255'
          ]

      state = _.defaults opts,
        on: true
        bri: 254
        sat: 236
        ct: 153
        effect: 'none'
        rgb: color

      # console.log state
      api.setLightState(light.id, state).then done
    ).then done

offLights = -> new Promise (done) ->
  getLigths().then ({lights}) ->
    Promise.all(lights.map (light) -> new Promise (done) ->
      state = hue.lightState.create()
      api.setLightState(
        light.id,
        state.off()
      ).then done
    ).then done

      # console.log light.id, light.name

if fs.existsSync(configPath)
  data = require process.env.HOME+'/.hue.json'
  ip = data.ip
  username = data.username
else
  api.register()
  return

api = new hue.HueApi(ip, username)
module.exports = {
  register
  offLights
  onLights
}
