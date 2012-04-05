require('lib/setup')

Spine = require('spine')

class App extends Spine.Controller
  constructor: ->
    super
    d3.json "combined.json", (json)=>
      path = d3.geo.path()
      svg = d3.select('#map').append('svg')
      parts = svg.append('g')
        .attr('id', 'parts')
        .attr('class','Blues')
      parts.selectAll('path')
        .data(json.features)
        .enter()
        .append('path')
        .attr('d',path)

module.exports = App
    
