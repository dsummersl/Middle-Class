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
      for i in [1..5]
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
          .attr('class','part')
          .attr('d',path)

        leveladder = (s,i)->
          scale = Math.random()/i
          s.attr('xlink:href',"#levelmask-#{i}")
            .attr('class', "level-${i}")
            .attr('id', (d)-> "puma-#{d.properties.PUMA5}-#{i}")
            .attr('transform', (d)->
              centroid = path.centroid(d)
              return "translate(#{centroid[0] - scale*iconW/2},#{centroid[1] - iconH}) scale(#{scale},1)"
            )

        for i in [1..5]
          parts.selectAll("level-#{i}")
            .data(json.features)
            .enter()
            .append('use')
            .call(leveladder,i)

        console.log "maDe path"

module.exports = App
    
