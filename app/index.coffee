require('lib/setup')

Spine = require('spine')

class StackGenerator
  constructor: ->
  
  
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
        console.log "make path"
        #console.log "PUMA = #{f.properties.PUMA5}" for f in json.features
        #console.log "PUMA = #{f.properties.PUMA5}" for f in json.features
        parts = svg.append('g')
          .attr('id', 'parts')
          .attr('class','map')
          .append('g')
          .call(d3.behavior.zoom().on("zoom", ()=>
            parts.attr("transform", "translate(#{d3.event.translate}) scale(#{d3.event.scale})")
          ))
          .append('g')
        parts.selectAll('.part')
          .data(json.features)
          .enter()
          .append('use')
          .attr('class', 'part')
          .attr('xlink:href',"#iconmask")
          .attr('height',50)
          .attr('width',50)
          .attr('transform', (d)->
            centroid = path.centroid(d)
            return "translate(#{centroid[0]},#{centroid[1]})"
          )
        console.log "made path"

module.exports = App
    
