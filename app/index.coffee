require('lib/setup')

Spine = require('spine')

class App extends Spine.Controller
  constructor: ->
    super
    d3.xml "svg/1percent.svg", "image/svg+xml", (xml)=>
      console.log "xml = #{xml.documentElement}"
      importNode = document.importNode(xml.documentElement, true)
      #d3.select('#map').node().appendChild(importNode)
      console.log "Map loaded"
      #d3.select('#mainmap svg').attr('fill',Options.nodatacountries)

module.exports = App
    
