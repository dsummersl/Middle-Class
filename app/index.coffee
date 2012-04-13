require('lib/setup')

Spine = require('spine')

class App extends Spine.Controller
  constructor: ->
    super
    randomInt = (max, min=0) -> Math.floor(Math.random() * (max - min + 1)) + min

    @icontemplate = null
    d3.xml "svg/icon.svg", "image/svg+xml", (xml)=>
      @log "loaded icon.svg"
      @icontemplate = document.importNode(d3.select(xml.documentElement).select('#levels').node(), true)
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
          .data(json.features)
          .enter()
          .append('path')
          .attr('id', (d)-> "puma-#{d.properties.PUMA5}")
          .attr('class','part')
          .attr('d',path)

        leveladder = (s,pumas,i)->
          s.attr('xlink:href',"#levelmask-#{i}")
            .attr('class', "level-#{i}")
            .attr('id', (d)-> "puma-#{d}-#{i}")
            .attr('transform', (d)->
              centroid = pumas[d].centroid
              console.log "no value for #{d}" if not pumas[d].centroid
              scale = 1
              return "translate(#{centroid[0] - scale*iconW/2},#{centroid[1] - iconH}) scale(#{scale},1)"
            )

        d3.json('http://localhost:3333/classes/all/lte/20', (db) ->
          i = 1
          keys = (k for k,v of db.pumas)
          #okeys = (v.properties.PUMA5 for v in json.features)
          #console.log "got this many summaries: #{keys.length}"
          #console.log "got this many features: #{okeys.length}"
          #console.log "summaries = #{keys}"
          #console.log "features = #{okeys}"
          for d in json.features
            k = "#{d.properties.PUMA5}"
            if db.pumas[k]?
              #console.log "setting #{k}"
              db.pumas[k].centroid = path.centroid(d)
          console.log "selecting..."
          parts.selectAll("level-#{i}")
            .data(keys)
            .enter()
            .append('use')
            .call(leveladder,db.pumas,i)
        )

        console.log "maDe path"

module.exports = App
    
