try
  round = require('../common').round
catch e
  console.log "no require"

# Utility classes for fading and such... {{{
# This class will manage the visibility of a specific item. You specify
# the timeout and the item, and it will ensure that if the mouse moves
# a button is visible for at least X ms. Once its visible as long
# as the mouse moves. Once its invisible the button will appear within
# a second.
class VisibleOnMovementItem
  constructor: (item,ms) ->
    @item = item
    @ms = ms
    @lastEvent = new Date().getTime()
    fn = => @checkFade()
    Meteor.setInterval(fn,@ms/5)
    # TODO make this automatically unregister itself to minimize the overhead.
    $('body').mousemove (e) => @lastEvent = (new Date()).getTime()
  isVisible: => $(@item).is(':visible')
  checkFade: =>
    if @isVisible()
      # if there has been no movement in the last @ms then fade out:
      change = new Date().getTime() > @lastEvent + @ms
      $(@item).fadeOut() if change
    else
      # if there has been any movement recently, then fade in.
      change = @lastEvent + 1000 > new Date().getTime()
      $(@item).fadeIn() if change

ContextWatcher = (method) ->
    contextrecaller = ->
      ctx = new Meteor.deps.Context()
      ctx.on_invalidate contextrecaller
      ctx.run method
    contextrecaller()

checkPumaTotals = (pumatotals) ->
  oldPumaTotals = Session?.get('pumatotals')
  newcount = d3.sum(p.lower+p.middle+p.upper for k,p of pumatotals)
  #if not oldPumaTotals? or (oldPumaTotals.lowmarker != pumatotals.lowmarker or oldPumaTotals.middlemarker != pumatotals.middlemarker)
  if not oldPumaTotals? or d3.sum(p.total for k,p of oldPumaTotals) <= newcount
    # TODO I'm assuming here that the age/school filters are OFF the first time
    for k,v of pumatotals
      # the absolute total of surveys, period
      pumatotals[k].total = pumatotals[k].lower + pumatotals[k].middle + pumatotals[k].upper
    Session?.set('pumatotals',pumatotals)
# }}}

percentBreakouts = (a*0.1 for a in [0..9])
#TODO update the granularity
#percentBreakouts = (a*0.03 for a in [0..30])
percentBreakouts.push(1)

class MapKey # The logic for making the map {{{
  constructor: (target,moneyMarkers,mapJson) ->
    @moneyMarkers = moneyMarkers
    @border = 5
    @width = 200
    @height = 100 # height of the main part
    @lheight = 100 # extra height for the state map
    @dataall = ({ x: i, y: 0 } for v,i in @moneyMarkers)
    @datalower = ({ x: i, y: 0 } for v,i in @moneyMarkers)
    @datamiddle= ({ x: i, y: 0 } for v,i in @moneyMarkers)
    @dataupper = ({ x: i, y: 0 } for v,i in @moneyMarkers)
    data = d3.layout.stack()
    @dodata = -> data([@datalower,@datamiddle,@dataupper,@dataall])

    @x = d3.scale.linear().domain([0,@moneyMarkers.length]).range([0,@width-@border])
    @y = d3.scale.linear().domain([0,1]).range([0,@height-@border*2])

    @keyArea = d3.svg.area().interpolate('basis')
      .x( (d) => @border + @x(d.x) )
      .y0( (d) => @height - @border - @y(d.y0) )
      .y1( (d) => @height - @border - @y(d.y+d.y0) )

    svg = d3.select(target).append('svg')
    defs = svg.append('defs')
    addPatterns(defs)
    @mainKey = svg.append('g')
      .attr('id','mainmapkey')
      .attr('class','mapKey')
      .attr('transform', "translate(10,10)")
    paths = @mainKey.selectAll('path')
      .data(@dodata())
    paths.enter()
      .append('path')
      .style('fill', (d,i) ->
        return 'url(#lowerpattern-0.5-0)' if i == 0
        return 'url(#middlepattern-0.5-0)' if i == 1
        return 'url(#upperpattern-0.5-0)' if i == 2
        '#ccc'
      )
    paths.enter()
      .append('text')
        .attr('id', (d,i) -> "mapkey-desc-#{i}")
        .attr('class', 'mapkey-desc mapkeytext')
        .attr('text-anchor', 'middle')
      .attr('d', @keyArea)
    @mainKey.append('line')
      .attr('id', 'lmLine')
      .attr('x1', @x(5))
      .attr('y1', 0)
      .attr('x2', @x(5))
      .attr('y2', @height - @border)
      .style('stroke', 'black')
    @mainKey.append('line')
      .attr('id', 'muLine')
      .attr('x1', @border + @x(10))
      .attr('y1', 0)
      .attr('x2', @border + @x(10))
      .attr('y2', @height - @border)
      .style('stroke', 'black')
    @mainKey.append('line')
      .attr('class', 'mapkeyaxis')
      .attr('x1', 0)
      .attr('y1', @height - @border)
      .attr('x2', @width)
      .attr('y2', @height - @border)
      .style('stroke', 'black')
    @mainKey.append('text')
      .attr('class', 'mapkeytext')
      .attr('x', @border)
      .attr('y', @height)
      .attr('text-anchor', 'end')
      .text('$0')
    @mainKey.append('text')
      .attr('class', 'mapkeytext')
      .attr('x', @width)
      .attr('y', @height)
      .attr('text-anchor', 'end')
      .text('$100M')
    # setup a state with all the reference patterns to explain them...# {{{
    path = d3.geo.path()
    stateKey = 20 # kansas
    map = (d for d in mapJson.features when d.properties.State == stateKey)
    centroid = path.centroid(map[0])
    @mainKey.append('g')
      .attr('transform',"scale(1.3) translate(#{30+@border-centroid[0]},#{@border+@height-centroid[1]})")
      .attr('id', 'maponkey')
      .selectAll('path')
      .data(map, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
      .enter()
      .append('path')
      .attr('id', (d)-> "maponkey-#{d.properties.PUMA5}")
      .attr('fill', '#ddd')
      .attr('stroke', '#ddd')
      .attr('d',path)
      #.on('mouseover', (d) ->
      #  console.log "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}"
      #)
    @mainKey.select('#maponkey-00100').attr('fill','url(#lowerpattern-1-0)')
    m = (m for m in map when m.properties.PUMA5 == '00100')[0]
    c = path.centroid(m)
    @mainKey.select('#maponkey').append('line').attr('class','mapkeyaxis')
      .attr('x1',c[0]).attr('y1',c[1]-10).attr('x2',c[0]+10).attr('y2',c[1]-20)
    @mainKey.select('#maponkey').append('text').attr('class','mapkeytext')
      .attr('x',c[0]+10).attr('y',c[1]-20).text('all lower')

    @mainKey.select('#maponkey-00200').attr('fill','url(#middlepattern-1-0)')
    m = (m for m in map when m.properties.PUMA5 == '00200')[0]
    c = path.centroid(m)
    @mainKey.select('#maponkey').append('line').attr('class','mapkeyaxis')
      .attr('x1',c[0]).attr('y1',c[1]-10).attr('x2',c[0]+10).attr('y2',c[1]-20)
    @mainKey.select('#maponkey').append('text').attr('class','mapkeytext')
      .attr('x',c[0]+10).attr('y',c[1]-20).text('all middle')

    @mainKey.select('#maponkey-00300').attr('fill','url(#upperpattern-1-0)')
    m = (m for m in map when m.properties.PUMA5 == '00300')[0]
    c = path.centroid(m)
    @mainKey.select('#maponkey').append('line').attr('class','mapkeyaxis')
      .attr('x1',c[0]).attr('y1',c[1]-10).attr('x2',c[0]+10).attr('y2',c[1]-17)
    @mainKey.select('#maponkey').append('text').attr('class','mapkeytext')
      .attr('x',c[0]+10).attr('y',c[1]-17).text('all upper')

    @mainKey.select('#maponkey-01200').attr('fill','url(#lowerpattern-0.5-0)')
    m = (m for m in map when m.properties.PUMA5 == '01200')[0]
    c = path.centroid(m)
    @mainKey.select('#maponkey').append('line').attr('class','mapkeyaxis')
      .attr('x1',c[0]).attr('y1',c[1]+10).attr('x2',c[0]-10).attr('y2',c[1]+20)
    @mainKey.select('#maponkey').append('text').attr('class','mapkeytext')
      .attr('x',c[0]-10).attr('y',c[1]+25).text('lower/upper').attr('text-anchor','middle')
    @mainKey.select('#maponkey').append('path').attr('fill','url(#upperpattern-0.5-0)').attr('d',path(m))

    @mainKey.select('#maponkey-01000').attr('fill','url(#lowerpattern-0.5-0)')
    m = (m for m in map when m.properties.PUMA5 == '01000')[0]
    @mainKey.select('#maponkey').append('path').attr('fill','url(#middlepattern-0.5-0)').attr('d',path(m))

    @mainKey.select('#maponkey-01100').attr('fill','url(#lowerpattern-0.5-0)')
    m = (m for m in map when m.properties.PUMA5 == '01100')[0]
    c = path.centroid(m)
    @mainKey.select('#maponkey').append('line').attr('class','mapkeyaxis')
      .attr('x1',c[0]).attr('y1',c[1]+10).attr('x2',c[0]-10).attr('y2',c[1]+20)
    @mainKey.select('#maponkey').append('text').attr('class','mapkeytext')
      .attr('x',c[0]-10).attr('y',c[1]+25).text('lower/middle').attr('text-anchor','middle')
    @mainKey.select('#maponkey').append('path').attr('fill','url(#middlepattern-0.5-0)').attr('d',path(m))

    @mainKey.select('#maponkey-00900').attr('fill','url(#lowerpattern-0-0)')
    m = (m for m in map when m.properties.PUMA5 == '00900')[0]
    c = path.centroid(m)
    @mainKey.select('#maponkey').append('line').attr('class','mapkeyaxis')
      .attr('x1',c[0]+5).attr('y1',c[1]-5).attr('x2',c[0]+30).attr('y2',c[1])
    @mainKey.select('#maponkey').append('text').attr('class','mapkeytext')
      .attr('x',c[0]+17).attr('y',c[1]-2).text('middle/upper').attr('transform',"rotate(30 #{c[0]+30} #{c[1]})")
    @mainKey.select('#maponkey').append('path').attr('fill','url(#middlepattern-0.5-0)').attr('d',path(m))
    @mainKey.select('#maponkey').append('path').attr('fill','url(#upperpattern-0.5-0)').attr('d',path(m))

    @mainKey.select('#maponkey-01500').attr('fill','url(#lowerpattern-0.30000000000000004-0)')
    m = (m for m in map when m.properties.PUMA5 == '01500')[0]
    c = path.centroid(m)
    @mainKey.select('#maponkey').append('line').attr('class','mapkeyaxis')
      .attr('x1',c[0]+5).attr('y1',c[1]-5).attr('x2',c[0]+30).attr('y2',c[1])
    @mainKey.select('#maponkey').append('text').attr('class','mapkeytext')
      .attr('x',c[0]+17).attr('y',c[1]-2).text('lower/middle/upper').attr('transform',"rotate(30 #{c[0]+30} #{c[1]})")
    @mainKey.select('#maponkey').append('path').attr('fill','url(#middlepattern-0.30000000000000004-0)').attr('d',path(m))
    @mainKey.select('#maponkey').append('path').attr('fill','url(#upperpattern-0.30000000000000004-0)').attr('d',path(m))

    @mainKey.select('#maponkey-01600').attr('fill','url(#lowerpattern-0.30000000000000004-0)')
    @mainKey.select('#maponkey').append('path').attr('fill','url(#middlepattern-0.30000000000000004-0)')
      .attr('d',path((m for m in map when m.properties.PUMA5 == '01600')[0]))
    @mainKey.select('#maponkey').append('path').attr('fill','url(#upperpattern-0.30000000000000004-0)')
      .attr('d',path((m for m in map when m.properties.PUMA5 == '01600')[0]))# }}}

  updateStatic: (oneVal,lm,middlem) =>
    lm = parseInt(lm)
    middlem = parseInt(middlem)
    lmi = (i for m,i in @moneyMarkers when m == lm)[0]
    mlmi = (i for m,i in @moneyMarkers when m == middlem)[0]
    for mm,i in @moneyMarkers
      @dataall[i].y = 0
      @datalower[i].y = 0
      @datamiddle[i].y = 0
      @dataupper[i].y = 0
    @privateupdate(0,oneVal.lower,0,oneVal.middle,0,oneVal.upper,lmi,mlmi)


  update: (result,pumatotals,lm,middlem) =>
    max = 0
    lm = parseInt(lm)
    middlem = parseInt(middlem)
    lmi = (i for m,i in @moneyMarkers when m == lm)[0]
    mlmi = (i for m,i in @moneyMarkers when m == middlem)[0]
    for mm,i in @moneyMarkers
      @dataall[i].y = 0
      @datalower[i].y = 0
      @datamiddle[i].y = 0
      @dataupper[i].y = 0
    alow = d3.sum(pt.lower for k,pt of pumatotals)
    amed = d3.sum(pt.middle for k,pt of pumatotals)
    ahig = d3.sum(pt.upper for k,pt of pumatotals)
    # since I don't have the actual buckets Ive innadvertantly added the values
    # into multiple buckets....divide it out:
    low = d3.sum(pt.lower for k,pt of result)
    med = d3.sum(pt.middle for k,pt of result)
    hig = d3.sum(pt.upper for k,pt of result)
    alow = alow - low
    amed = amed - med
    ahig = ahig - hig
    low = 0 if isNaN(low)
    med = 0 if isNaN(med)
    hig = 0 if isNaN(hig)
    @privateupdate(alow,low,amed,med,ahig,hig,lmi,mlmi)

  privateupdate: (alow,low,amed,med,ahig,hig,lmi,mlmi) =>
    for mm,i in @moneyMarkers
      if i < lmi
        @dataall[i].y = alow
        @datalower[i].y = low
        @datamiddle[i].y = 0
        @dataupper[i].y = 0
      else if i >= lmi and i <= mlmi
        @dataall[i].y = amed
        @datalower[i].y = 0
        @datamiddle[i].y = med
        @dataupper[i].y = 0
      else if i > mlmi
        @dataall[i].y = ahig
        @datalower[i].y = 0
        @datamiddle[i].y = 0
        @dataupper[i].y = hig
      else
        console.log "don't know what to do with #{i}"

    max = d3.max([low+alow,med+amed,hig+ahig])
    @y = d3.scale.linear().domain([0,max]).range([0,@height-@border*2])
    #console.log "#s: #{low} #{med} #{hig}"
    #console.log "#a: #{alow} #{amed} #{ahig}"

    @mainKey.selectAll('path')
      .data(@dodata())
      .transition()
      .duration(500)
      .attr('d', @keyArea)
    @mainKey.selectAll('.mapkey-desc')
      .transition()
      .duration(500)
      .attr('x', (d,i) =>
        if i == 0
          return @border + @x(lmi)/2 if d3.max([alow,amed,ahig]) == alow
          return @border + @x(lmi) + @x(mlmi-lmi)/2 if d3.max([alow,amed,ahig]) == amed
          return @border + @x(mlmi) + @x(@moneyMarkers.length-mlmi)/2 if d3.max([alow,amed,ahig]) == ahig
        return @border + @x(lmi)/2 if i == 1
        return @border + @x(lmi+parseInt((mlmi-lmi)/2)) if i == 2
        return @border + @x(mlmi) + @x(@moneyMarkers.length-mlmi)/2 if i == 3
      )
      .attr('y', (d,i) =>
        return @height - @border - @y(d3.max([alow,amed,ahig])) if i == 0
        return @height - @border - @y(low) if i == 1
        return @height - @border - @y(med) if i == 2
        return @height - @border - @y(hig) if i == 3
      )
      .text( (d,i) ->
        return "#{parseInt( (d3.max([alow,amed,ahig])+d3.max([low,med,hig])) / d3.sum([low,med,hig,alow,amed,ahig]) * 100 )}%" if i == 0 and d3.max([alow,amed,ahig]) != 0
        return "#{parseInt(low / d3.sum([alow,amed,ahig,low,med,hig]) * 100 )}%" if i == 1 and low != 0
        return "#{parseInt(med / d3.sum([alow,amed,ahig,low,med,hig]) * 100 )}%" if i == 2 and med != 0
        return "#{parseInt(hig / d3.sum([alow,amed,ahig,low,med,hig]) * 100 )}%" if i == 3 and hig != 0
        return ''
      )
    @mainKey.selectAll('#lmLine')
      .transition()
      .duration(500)
      .attr('x1', @border + @x(lmi))
      .attr('x2', @border + @x(lmi))
    @mainKey.selectAll('#muLine')
      .transition()
      .duration(500)
      .attr('x1', @border + @x(mlmi))
      .attr('x2', @border + @x(mlmi))
# }}}
# Make the main map# {{{
makeMap = (pumatotals,callback) ->
  d3.json 'svg/5percent-combined.geojson', (json) ->
    doMakeMap('#map',json,pumatotals,callback)
    # pick the state for the key
    Session.set('mapkey', new MapKey('#hoverdetail',moneyMarkers,json))

addPatterns = (defs) ->
  # http://en.wikipedia.org/wiki/Navajo_white
  # ...it does not easily show stains from cigarette smoke or fingerprints...
  lowcolors = d3.scale.sqrt().domain([0,1]).range([d3.hsl(36,0,0.9),d3.hsl(36,0.8,0.9)])
  middlecolors = d3.scale.linear().domain([0,1]).range([d3.hsl(216,0.4,0.6),d3.hsl(216,0.8,0.9)])
  uppercolors = d3.scale.linear().domain([0,1]).range([d3.hsl(96,0.4,0.6),d3.hsl(96,0.8,0.9)])
  for density in percentBreakouts
    for pb in percentBreakouts
      patternArea = (d) ->
        d.attr('patternUnits', 'userSpaceOnUse')
        .attr('x','0')
        .attr('y','0')
        .attr('width', "#{10 - density*7.9 + 0.1}")
        .attr('height',"#{10 - density*7.9 + 0.1}")
        .attr('viewBox','0 0 10 10')
      p = defs.append('pattern')
        .attr('id', "lowerpattern-#{pb}-#{density}")
        .call(patternArea)
        .append('g')
      p.append('rect')
        .attr('x','0')
        .attr('y','0')
        .attr('width','10')
        .attr('height','10')
        .attr('fill', lowcolors(pb))
      p = defs.append('pattern')
        .attr('id', "middlepattern-#{pb}-#{density}")
        .call(patternArea)
        .append('g')
        #.attr('transform',(d) -> "rotate(#{parseInt(pb*45)} 0 0)")
      p.append('polygon')
        .attr('points',"0,0 #{10-(1-pb)*10},0 10,5 #{10-(1-pb)*10},10 0,10 #{(1-pb)*10},5 0,0")
        .attr('fill', middlecolors(pb))
      p = defs.append('pattern')
        .attr('id', "upperpattern-#{pb}-#{density}")
        .call(patternArea)
        .append('g')
        #.attr('transform',(d) -> "rotate(#{-parseInt(pb*45)} 0 0)")
      p.append('rect')
        .attr('x','0')
        .attr('y',"#{10*(1-pb)}")
        .attr('width','10')
        .attr('height',"#{10*pb}")
        .attr('fill', uppercolors(pb))

# given a map (json), put it on the target.
# 'rich' is the rich pattern SVG assumed to be about 100x100
doMakeMap = (target,json,pumatotals,callback) ->
  Session?.set('map',json)
  centered = null
  path = d3.geo.path()
  svg = d3.select(target).append('svg')
  defs = svg.append('defs')
  mainG = svg.append('g')
    .attr('class','mapparts')
  addPatterns(defs)
  parts = mainG.selectAll('.part')
    .data(json.features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
  parts.enter()
    .append('path')
    .attr('id', (d)-> "lower-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
    .attr('class','part lower')
    .attr('fill', 'white')
    .attr('d',path)
  parts.enter()
    .append('path')
    .attr('id', (d)-> "middle-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
    .attr('class','part middle')
    .attr('d',path)
  parts.enter()
    .append('path')
    .attr('id', (d)-> "upper-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
    .attr('class','part upper')
    .attr('d',path)
    .on('mouseover', (d) ->
      ls = Session.get('lastsearch')
      pumatotals = Session.get('pumatotals')
      k = "#{d.properties.State}-#{d.properties.PUMA5}"
      console.log "this area = #{path.area(d)}"
      Session.get('mapkey').updateStatic(ls[k],Session.get('lowmarker'),Session.get('middlemarker'))
    )
    .on('mouseout', (d) ->
      Session.get('mapkey').update(Session.get('lastsearch'),Session.get('pumatotals'),Session.get('lowmarker'),Session.get('middlemarker'))
    )
    .on('click', (d) ->
      x = 0
      y = 0
      k = 1
      centered = Session.get('zoom')
      console.log "click on #{centered}"
      if d && not centered?
        centroid = path.centroid(d)
        console.log "centering on #{centroid}"
        k = 8
        x = -centroid[0] + 300/k
        y = -centroid[1] + 400/k
        Session.set('zoom',d)
        centered = d
      else
        Session.set('zoom',null)
        console.log "uncentering"
        centered = null

      mainG
        .transition()
        .duration(1000)
        .attr("transform", "scale(" + k + ")translate(" + x + "," + y + ")")
        .style("stroke-width", 1.5 / k + "px")
    )
  checkPumaTotals(pumatotals)
  callback?()
# }}}
# make a call, and repain the map, using Meteor constants to keep it up to date.# {{{
paintMap = ->
  paintMapContext = new Meteor.deps.Context()
  paintMapContext.on_invalidate paintMap
  paintMapContext.run ->
    $('#startupdialog').fadeIn()
    Session.set('status',"Updating map...")
    Meteor.call('getGroup', Session.get('lowmarker'), Session.get('middlemarker'), Session.get('age'), Session.get('school'), (err, result) ->
      if err
        console.log "ERROR: #{err}"
      else
        Session.set('lastsearch',result)
        Session.set('status',"Loading stats...")
        checkPumaTotals(result)
        doPaintMap(result,Session.get('pumatotals'),Session.get('map'),d3.select('#map svg'))
        Session.get('mapkey').update(result,Session.get('pumatotals'),Session.get('lowmarker'),Session.get('middlemarker'))
        $('#startupdialog').fadeOut()
    )

# a non-meteor method that updates the map.
doPaintMap = (result,pumatotals,map,svg=null) ->
  path = d3.geo.path()
  features = []
  minSPA = 0
  maxSPA = 0
  minTotal = 0
  maxTotal = 0
  for d in map.features
    k = "#{d.properties.State}-#{d.properties.PUMA5}"
    if result[k]?
      features.push(d)
      minTotal = pumatotals[k].total if minTotal == 0 or minTotal > pumatotals[k].total
      maxTotal = pumatotals[k].total if maxTotal == 0 or maxTotal < pumatotals[k].total
      d.properties.samplesPerArea = path.area(d)
      d.properties.samplesPerArea = 1000 if d.properties.samplesPerArea > 1000
      d.properties.samplesPerArea = 1 if d.properties.samplesPerArea < 1
      minSPA = d.properties.samplesPerArea if minSPA == 0 or minSPA > d.properties.samplesPerArea
      maxSPA = d.properties.samplesPerArea if maxSPA == 0 or maxSPA < d.properties.samplesPerArea
      #console.log "samples per area? #{result[k].total} / #{d.properties.AREA} = #{result[k].total / d.properties.AREA}"

  console.log "totals: #{minTotal} - #{maxTotal}"
  console.log "densities: #{minSPA} - #{maxSPA}"
  dens = d3.scale.sqrt().domain([minSPA,maxSPA]).range([0,1])
  totsF = d3.scale.log().domain([minTotal,maxTotal]).range([0,0.8])
  tots = (d) -> 0.2 + totsF(d)

  svg = d3.select('svg') if not svg?
  d = svg.selectAll(".lower")
    .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
  d.exit().remove()
  d.attr('fill', (d) ->
      k = "#{d.properties.State}-#{d.properties.PUMA5}"
      val = round(result[k].lower / (result[k].lower + result[k].middle + result[k].upper),percentBreakouts)
      den = round(1-dens(d.properties.samplesPerArea),percentBreakouts)
      "url(#lowerpattern-#{val}-#{den})"
    )
  #d.attr('opacity', (d) -> tots(pumatotals["#{d.properties.State}-#{d.properties.PUMA5}"].total))

  d = svg.selectAll(".middle")
    .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
  d.exit().remove()
  d.attr('fill', (d) ->
      k = "#{d.properties.State}-#{d.properties.PUMA5}"
      val = round(result[k].middle / (result[k].lower + result[k].middle + result[k].upper),percentBreakouts)
      den = round(1-dens(d.properties.samplesPerArea),percentBreakouts)
      #console.log "url(#middlepattern-#{val}-#{den}) #{result[k].middle} #{pumatotals[k].total}"
      "url(#middlepattern-#{val}-#{den})"
    )
  #d.attr('opacity', (d) -> tots(pumatotals["#{d.properties.State}-#{d.properties.PUMA5}"].total))

  d = svg.selectAll(".upper")
    .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
  d.exit().remove()
  d.attr('fill', (d) ->
      k = "#{d.properties.State}-#{d.properties.PUMA5}"
      val = round(result[k].upper / (result[k].lower + result[k].middle + result[k].upper),percentBreakouts)
      den = round(1-dens(d.properties.samplesPerArea),percentBreakouts)
      "url(#upperpattern-#{val}-#{den})"
    )
  #d.attr('opacity', (d) -> tots(pumatotals["#{d.properties.State}-#{d.properties.PUMA5}"].total))
# }}}

# hack for cakefile to read this as an npm module...
module?.exports =
  makeMap: makeMap
  doMakeMap: doMakeMap
  doPaintMap: doPaintMap
  paintMap: paintMap

#vim: set fdm=marker:
