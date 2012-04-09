require('lib/setup')

Spine = require('spine')

class App extends Spine.Controller
  constructor: ->
    super
    d3.csv "data/nc.csv", (csv)->
    d3.json "svg/5percent-combined.geojson", (json)->
      path = d3.geo.path()
      svg = d3.select('#map').append('svg')
      console.log "total parts = #{json}"
      #console.log "PUMA = #{f.properties.PUMA5}" for f in json.features
      #console.log "PUMA = #{f.properties.PUMA5}" for f in json.features
      parts = svg.append('g')
        .attr('id', 'parts')
        .attr('class','map')
      parts.selectAll('path')
        .data(json.features)
        .enter()
        .append('path')
        .attr('d',path)

module.exports = App
    
