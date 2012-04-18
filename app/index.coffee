require('lib/setup')

Spine = require('spine')

class App extends Spine.Controller
  constructor: ->
    super
    @log "starting..."
    $('#startuptext').text("Loading map...")
    d3.json "svg/5percent-combined.geojson", (json)=>
      path = d3.geo.path()
      console.log "maKe path"
      svg = d3.select('#map').append('svg')
      parts = svg.selectAll('.part')
        .data(json.features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")

      parts.enter()
        .append('path')
        .attr('id', (d)-> "lower-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
        .attr('class','part lower')
        .attr('d',path)

      svg = d3.select('#map').append('svg')
      parts = svg.selectAll('.part')
        .data(json.features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
      parts.enter()
        .append('path')
        .attr('id', (d)-> "middle-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
        .attr('class','part middle')
        .attr('d',path)

      svg = d3.select('#map').append('svg')
      parts = svg.selectAll('.part')
        .data(json.features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
      parts.enter()
        .append('path')
        .attr('id', (d)-> "upper-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
        .attr('class','part upper')
        .attr('d',path)

      $('#startuptext').text("Loading stats...")
      d3.json 'http://localhost:3333/classes/all/25/65', (db) ->
        console.log "got stats"
        features = []
        for d in json.features
          k = "#{d.properties.State}-#{d.properties.PUMA5}"
          if db.pumas[k]?
            features.push(d)
            db.pumas[k].total = db.pumas[k].lower + db.pumas[k].middle + db.pumas[k].upper
        lowscale = d3.scale.linear().domain([0,1]).range(['rgba(255,0,0,0)','rgba(255,0,0,1)'])
        middlescale = d3.scale.linear().domain([0,1]).range(['rgba(0,255,0,0)','rgba(0,255,0,1)'])
        upperscale = d3.scale.linear().domain([0,1]).range(['rgba(0,0,255,0)','rgba(0,0,255,1)'])
        #TODO 22-01905 -- is combined with xxx b/c of population displacement
        d3.selectAll(".lower")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .transition()
          .delay(300)
          .style('fill', (d) =>
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = db.pumas[k].lower / db.pumas[k].total
            return lowscale(val)
          )
        d3.selectAll(".middle")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .transition()
          .delay(300)
          .style('fill', (d) =>
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = db.pumas[k].middle / db.pumas[k].total
            return middlescale(val)
          )
        d3.selectAll(".upper")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .transition()
          .delay(300)
          .style('fill', (d) =>
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = db.pumas[k].upper / db.pumas[k].total
            return upperscale(val)
          )
        $('#startupdialog').fadeOut()

module.exports = App
    
