require('lib/setup')

Spine = require('spine')

class App extends Spine.Controller
  constructor: ->
    super
    randomInt = (max, min=0) -> Math.floor(Math.random() * (max - min + 1)) + min

    @icontemplate = null
    d3.xml "svg/icon.svg", "image/svg+xml", (xml)=>
      @icontemplate = document.importNode(d3.select(xml.documentElement).select('#levels').node(), true)
      @log "loaded icon.svg"
      svg = d3.select('#map').append('svg')
      defs = svg.append('defs')
      for i in [1..3]
        mask = defs.append('g').attr('id',"levelmask-#{i}")
        mask.node().appendChild(d3.select(@icontemplate).select("#level-#{i}").node())

      d3.json "svg/5percent-combined.geojson", (json)=>
        @log "loaded map"
        path = d3.geo.path()
        #iconH = d3.select('#iconmask').attr('height')
        #iconW = d3.select('#iconmask').attr('width')
        iconH = 13
        iconW = 5
        @log "icon dimensions = #{iconH} by #{iconW}"
        console.log "maKe path"
        #console.log "PUMA = #{f.properties.PUMA5}" for f in json.features
        #console.log "PUMA = #{f.properties.PUMA5}" for f in json.features
        parts = svg.append('g')
          .attr('id', 'mapgraphic')
          .append('g')
          .call(d3.behavior.zoom().on("zoom", ()=>
            parts.attr("transform", "translate(#{d3.event.translate}) scale(#{d3.event.scale})")
          ))
          .append('g')
        parts.selectAll('.part')
          .data(json.features, (d)-> "#{d.properties.State}-#{d.properties.PUMA5}")
          .enter()
          .append('path')
          .attr('id', (d)-> "puma-#{d.properties.State}-#{d.properties.PUMA5}")
          .attr('class','part')
          .attr('d',path)

        d3.json 'http://localhost:3333/classes/all/25/65', (db) ->
          keys = (k for k,v of db.pumas)
          for d in json.features
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            if db.pumas[k]?
              db.pumas[k].total = db.pumas[k].lower + db.pumas[k].middle + db.pumas[k].upper
          scale = d3.scale.linear().domain([0,1]).range(['#000','#fff'])
          for i in [3..3]
            parts.selectAll(".part")
              .data(keys)
              .transition()
              .delay(300)
              .style('fill', (d) =>
                #val = db.pumas[d].lower / db.pumas[d].total if i == 1
                #val = db.pumas[d].middle / db.pumas[d].total if i == 2
                val = db.pumas[d].upper / db.pumas[d].total
                # $('#puma-36-04304')
                #console.log "setting it to #{val} for #{d} - #{db.pumas[d].upper} / #{db.pumas[d].total} #{i} #{scale(val)}"
                return scale(val)
              )
              #.enter()
              #.append('use')
              #.call(leveladder,db.pumas,i)

        console.log "maDe path"

module.exports = App
    
