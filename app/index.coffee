require('lib/setup')

Spine = require('spine')

class App extends Spine.Controller
  constructor: ->
    super
    #console.log "d3 val #{k} = #{v}" for k,v of d3
    #d3.select('nothing')
    console.log "version = #{d3.version}"

module.exports = App
    
