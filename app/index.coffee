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
      defs = svg.append('defs')
      # Using this URL to pass params to my patterns:
      # http://www.w3.org/TR/2009/WD-SVGParamPrimer-20090430/#URLParameters
      p = defs.append('pattern')
        .attr('id', 'lowerpattern')
        .attr('patternUnits', 'userSpaceOnUse')
        .attr('x',0)
        .attr('y',0)
        .attr('width',10)
        .attr('height',10)
        .attr('viewBox','0 0 5 5')
      p.append('rect')
        .attr('x',0)
        .attr('y',0)
        .attr('width', 2.5)
        .attr('height', 2.5)
        .attr('fill', 'red')
      p.append('rect')
        .attr('x',2.5)
        .attr('y',2.5)
        .attr('width', 2.5)
        .attr('height', 2.5)
        .attr('fill', 'red')
      p = defs.append('pattern')
        .attr('id', 'middlepattern')
        .attr('patternUnits', 'userSpaceOnUse')
        .attr('x',0)
        .attr('y',0)
        .attr('width',10)
        .attr('height',10)
        .attr('viewBox','0 0 5 5')
      p.append('rect')
        .attr('x',2.5)
        .attr('y',0)
        .attr('width', 2.5)
        .attr('height', 2.5)
        .attr('fill', 'green')
      p.append('rect')
        .attr('x',0)
        .attr('y',2.5)
        .attr('width', 2.5)
        .attr('height', 2.5)
        .attr('fill', 'green')
      parts = svg.selectAll('.part')
        .data(json.features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")

      parts.enter()
        .append('path')
        .attr('id', (d)-> "lower-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
        .attr('class','part lower')
        .attr('d',path)

      ###
      svg = d3.select('#map').append('svg')
      parts = svg.selectAll('.part')
        .data(json.features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
      ###
      parts.enter()
        .append('path')
        .attr('id', (d)-> "middle-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
        .attr('class','part middle')
        .attr('d',path)

      ###
      svg = d3.select('#map').append('svg')
      parts = svg.selectAll('.part')
        .data(json.features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
      ###
      parts.enter()
        .append('path')
        .attr('id', (d)-> "upper-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
        .attr('class','part upper')
        .attr('d',path)

      $('#startuptext').text("Loading stats...")
      d3.json 'http://localhost:3333/classes/all/20/90', (db) ->
        features = []
        for d in json.features
          k = "#{d.properties.State}-#{d.properties.PUMA5}"
          if db.pumas[k]?
            features.push(d)
            db.pumas[k].total = db.pumas[k].lower + db.pumas[k].middle + db.pumas[k].upper

        lCnt = 0
        mCnt = 0
        uCnt = 0
        lSum = 0
        mSum = 0
        uSum = 0
        for k,v of db.pumas
          lCnt += v.lower
          mCnt += v.middle
          uCnt += v.upper
          lSum += v.lAmount
          mSum += v.mAmount
          uSum += v.uAmount
        console.log "Total sums LMU = #{lCnt},#{mCnt},#{uCnt}  #{lSum},#{mSum},#{uSum} #{lSum/lCnt},#{mSum/mCnt},#{uSum/uCnt}"

        lowscale = d3.scale.linear().domain([0,1]).range(['rgba(255,0,0,0)','rgba(255,0,0,1)'])
        middlescale = d3.scale.linear().domain([0,1]).range(['rgba(0,255,0,0)','rgba(0,255,0,1)'])
        upperscale = d3.scale.linear().domain([0,1]).range(['rgba(0,0,255,0)','rgba(0,0,255,1)'])
        #TODO 22-01905 -- is combined with xxx b/c of population displacement
        d3.selectAll(".lower")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .transition()
          .delay(1000)
          .attr('fill',"url(#lowerpattern)")
          .attr('opacity', (d) =>
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = db.pumas[k].lower / db.pumas[k].total
            #return lowscale(val)
          )
        d3.selectAll(".middle")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .transition()
          .delay(1000)
          .attr('fill',"url(#middlepattern)")
          .attr('opacity', (d) =>
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = db.pumas[k].middle / db.pumas[k].total
            #return middlescale(val)
          )
        d3.selectAll(".upper")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .transition()
          .delay(1000)
          .attr('fill', 'blue')
          .style('opacity', (d) =>
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = db.pumas[k].upper / db.pumas[k].total
            #return upperscale(val)
          )
        $('#startupdialog').fadeOut()

module.exports = App
    
