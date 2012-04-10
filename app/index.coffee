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
      mask = defs.append('mask').attr('id','iconmask')
      mask.node().appendChild(@icontemplate)
      defs.append('rect')
        .attr('id','iconmaskinstance')
        .attr('height',10)
        .attr('width',10)
        .attr('mask', "url(#iconmask)")
      d3.json "svg/5percent-combined.geojson", (json)=>
        @log "loaded map"
        path = d3.geo.path()
        console.log "make path"
        #console.log "PUMA = #{f.properties.PUMA5}" for f in json.features
        #console.log "PUMA = #{f.properties.PUMA5}" for f in json.features
        parts = svg.append('g')
          .attr('id', 'parts')
          .attr('class','map')
        parts.selectAll('.part')
          .data(json.features)
          .enter()
          .append('use')
          .attr('class', 'part')
          .attr('xlink:href',"#iconmaskinstance")
          .attr('height',50)
          .attr('width',50)
          .attr('transform', (d)->
            centroid = path.centroid(d)
            return "translate(#{centroid[0]},#{centroid[1]})"
          )
        console.log "made path"
      ###
      #         var centroid = path.centroid(d),
41             x = centroid[0],
42             y = centroid[1];
43         return "translate(" + x + "," + y + ")"
44             + "scale(" + Math.sqrt(data[+d.id] * 5 || 0) + ")"
45             + "translate(" + -x + "," + -y + ")";
      ###

module.exports = App
    
