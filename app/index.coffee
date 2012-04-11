require('lib/setup')

Spine = require('spine')

class App extends Spine.Controller
  constructor: ->
    super
    @icontemplate = null
    d3.xml "svg/icon.svg", "image/svg+xml", (xml)=>
      @log "loaded icon.svg"
      @icontemplate = document.importNode(d3.select(xml.documentElement).select('#levels').node(), true)
      svg = d3.select('#map').append('svg')
      defs = svg.append('defs')
      mask = defs.append('g').attr('id','iconmask')
      mask.node().appendChild(@icontemplate)
      d3.json "svg/5percent-combined.geojson", (json)=>
        @log "loaded map"
        path = d3.geo.path()
        #iconH = d3.select('#iconmask').attr('height')
        #iconW = d3.select('#iconmask').attr('width')
        iconH = 13
        iconW = 5
        @log "icon dimensions = #{iconH} by #{iconW}"
        console.log "make path"
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
        parts.selectAll('.icon')
          .data(json.features)
          .enter()
          .append('use')
          .attr('xlink:href',"#iconmask")
          #.append('circle')
          #.attr('r', 2)
          #.attr('cx', 0)
          #.attr('cy', 0)
          .attr('class', 'icon')
          .attr('id', (d)-> "puma-#{d.properties.PUMA5}")
          .attr('transform', (d)->
            centroid = path.centroid(d)
            return "translate(#{centroid[0] - iconW/2},#{centroid[1] - iconH})"
          )

        ###
        d3.selectAll('.icon')
          .data(json.features)
          .call((d)-> # setup the widths to be randomly large
            d3.select("#puma-#{d.properties.PUMA5} .level#{i}").attr('width',Math.random()*iconW) for i in [1..5]
          )
        ###
        console.log "made path"

module.exports = App
    
