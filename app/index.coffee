require('lib/setup')

Spine = require('spine')

class App extends Spine.Controller
  constructor: ->
    super
    @log "starting..."
    d3.json "svg/5percent-combined.geojson", (json)=>
      @log "loaded map"
      path = d3.geo.path()
      console.log "maKe path"
      svg = d3.select('#map').append('svg')
      parts = svg.append('g')
        .attr('id', 'mapgraphic')
        .append('g')
        .call(d3.behavior.zoom().on("zoom", ()=>
          parts.attr("transform", "translate(#{d3.event.translate}) scale(#{d3.event.scale})")
        ))
        .append('g')
      parts.selectAll('.part')
        .data(json.features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
        .enter()
        .append('path')
        .attr('id', (d)-> "puma-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
        .attr('class','part')
        .attr('d',path)

      d3.json 'http://localhost:3333/classes/all/25/65', (db) ->
        console.log "got stats"
        features = []
        for d in json.features
          k = "#{d.properties.State}-#{d.properties.PUMA5}"
          if db.pumas[k]?
            features.push(d)
            db.pumas[k].total = db.pumas[k].lower + db.pumas[k].middle + db.pumas[k].upper
        scale = d3.scale.linear().domain([0,1]).range(['#bbd3f9','#f1ee9c'])
        #console.log "map = "+ ("#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}" for d in json.features)
        #console.log "mat = "+ ("#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}" for d in features)
        for i in [3..3]
          parts.selectAll(".part")
            .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
            .transition()
            .delay(300)
            .style('fill', (d) =>
              k = "#{d.properties.State}-#{d.properties.PUMA5}"
              #val = db.pumas[k].lower / db.pumas[k].total
              #val = db.pumas[k].middle / db.pumas[k].total
              val = db.pumas[k].upper / db.pumas[k].total
              # TODO these are empty :(
              # $('#puma-37-02100')
              # $('#puma-37-03000')
              #console.log "setting it to #{val} for #{d} - #{db.pumas[d].upper} / #{db.pumas[d].total} #{i} #{scale(val)}"
              return scale(val)
            )

      console.log "maDe path"

module.exports = App
    
