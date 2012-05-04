try
  round = require('../common').round
catch e
  console.log "no require"

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

percentBreakouts = (a*0.1 for a in [0..9])
#TODO update the granularity
#percentBreakouts = (a*0.03 for a in [0..30])
percentBreakouts.push(1)

class MapKey
  constructor: (target,moneyMarkers) ->
    @moneyMarkers = moneyMarkers
    @border = 5
    @width = 200
    @height = 100
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
    @mainKey.selectAll('path')
      .data(@dodata())
      .enter()
      .append('path')
      #.style('fill', -> d3.interpolateRgb('#aad','#556')(Math.random()))
      # how to specify?
      #.style('fill', 'url(#middlepattern-0.4-0.4)')
      .style('fill', (d,i) ->
        return 'url(#lowerpattern-0.4-0.4)' if i == 0
        return 'url(#middlepattern-0.4-0.4)' if i == 1
        return 'url(#upperpattern-0.4-0.4)' if i == 2
        'gray'
      )
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

  update: (result,pumatotals,lm,middlem) =>
    max = 0
    lm = parseInt(lm)
    middlem = parseInt(middlem)
    for mm,i in @moneyMarkers
      @dataall[i].y = 0
      @datalower[i].y = 0
      @datamiddle[i].y = 0
      @dataupper[i].y = 0
      for k,pt of result
        @datalower[i].y += pt.lower if mm <= lm
        @datamiddle[i].y += pt.middle if mm > lm and mm <= middlem
        @dataupper[i].y += pt.upper if mm > middlem
      for k,pt of pumatotals
        @dataall[i].y += pt.lower if mm <= lm
        @dataall[i].y += pt.middle if mm > lm and mm <= middlem
        @dataall[i].y += pt.upper if mm > middlem
      #@dataall[i].y -= @datalower[i].y + @datamiddle[i].y + @dataupper[i].y
    for mm,i in @moneyMarkers
      max = @dataall[i].y if max < @dataall[i].y
    @y = d3.scale.linear().domain([0,max]).range([0,@height-@border*2])
    for mm,i in @moneyMarkers
      console.log "for #{i} the height would be #{@y(@datalower[i].y)} #{@y(@datamiddle[i].y)} #{@y(@dataupper[i].y)} #{@y(@dataall[i].y)} for #{@dataall[i].y}"
    @mainKey.selectAll('path')
      .data(@dodata())
      .transition()
      .duration(1000)
      .attr('d', @keyArea)
    @mainKey.selectAll('#lmLine')
      .transition()
      .duration(1000)
      .attr('x1', @border + @x((i for m,i in @moneyMarkers when m == lm)[0]))
      .attr('x2', @border + @x((i for m,i in @moneyMarkers when m == lm)[0]))
    @mainKey.selectAll('#muLine')
      .transition()
      .duration(1000)
      .attr('x1', @border + @x((i for m,i in @moneyMarkers when m == middlem)[0]))
      .attr('x2', @border + @x((i for m,i in @moneyMarkers when m == middlem)[0]))

makeMap = (pumatotals,callback) ->
  d3.json 'svg/5percent-combined.geojson', (json) ->
    doMakeMap('#map',json,pumatotals,callback)
    Session.set('mapkey', new MapKey('#hoverdetail',moneyMarkers))

addPatterns = (defs) ->
  for density in percentBreakouts
    for pb in percentBreakouts
      patternArea = (d) ->
        d.attr('patternUnits', 'userSpaceOnUse')
        .attr('x','0')
        .attr('y','0')
        #.attr('width', "10")
        #.attr('height',"10")
        .attr('width', "#{10 - density*9.9 + 0.1}")
        .attr('height',"#{10 - density*9.9 + 0.1}")
        .attr('viewBox','0 0 10 10')

      p = defs.append('pattern')
        .attr('id', "middlepattern-#{pb}-#{density}")
        .call(patternArea)
        .append('g')
        .attr('transform',(d) -> "rotate(#{-parseInt(pb*90)} 5 5)")
      p.selectAll('line').data([-1..5]).enter().append('line')
        .attr('x1','0')
        .attr('y1',(d)->"#{d*2}") # 0, 2, 4, 8
        .attr('x2','10')
        .attr('y2',(d)->"#{d*2}")
        .attr('stroke-width', "#{pb*2.1}")
        .attr('stroke', d3.rgb('blue').brighter())

      p = defs.append('pattern')
        .attr('id', "upperpattern-#{pb}-#{density}")
        .call(patternArea)
        .append('g')
        .attr('transform',(d) -> "rotate(#{-parseInt(pb*90)} 5 5)")
      p.selectAll('line').data([-1..5]).enter().append('line')
        .attr('x1','0')
        .attr('y1',(d)->"#{d*2+1}") # 1 3 5 9
        .attr('x2','10')
        .attr('y2',(d)->"#{d*2+1}")
        .attr('stroke-width', "#{pb*2.1}")
        .attr('stroke', d3.rgb('red').brighter())

# given a map (json), put it on the target.
# 'rich' is the rich pattern SVG assumed to be about 100x100
doMakeMap = (target,json,pumatotals,callback) ->
  Session?.set('map',json)
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
      #$('#hoverdetail').html("Lower: #{ls[k].lower}<br/>Middle: #{ls[k].middle}<br/>Upper: #{ls[k].upper}")
      #$('#hoverdetail').html("Lower: #{ls[k].lower}<br/>Middle: #{ls[k].middle}<br/>Upper: #{ls[k].upper}<br/>#{d.properties.samplesPerArea}")
      #$('#hoverdetail').html("Lower: #{ls[k].lower}<br/>Middle: #{ls[k].middle}<br/>Upper: #{ls[k].upper}<br/>#{k}")
    )
    .on('mouseout', (d) ->
      console.log 'nop'
      #$('#hoverdetail').text("")
      #console.log "doing a mouse over for #upper-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}"
    )
  # TODO I'm assuming here that the age/school filters are OFF the first time
  for d in json.features
    k = "#{d.properties.State}-#{d.properties.PUMA5}"
    if pumatotals[k]?
      # the absolute total of surveys, period
      pumatotals[k].total = pumatotals[k].lower + pumatotals[k].middle + pumatotals[k].upper
      d.properties.AREA = 0.01 if d.properties.AREA < 0.01
      # from 500 to 2 million, lets change the pattern circle radius depending on this density.
      d.properties.samplesPerArea = pumatotals[k].total / d.properties.AREA
  Session.set('pumatotals',pumatotals)

  callback?()


# make a call, and repain the map, using Meteor constants to keep it up to date.
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
        doPaintMap(result,Session.get('pumatotals'),Session.get('map'),d3.select('#map svg'))
        Session.get('mapkey').update(result,Session.get('pumatotals'),Session.get('lowmarker'),Session.get('middlemarker'))
        $('#startupdialog').fadeOut()
    )

# a non-meteor method that updates the map.
doPaintMap = (result,pumatotals,map,svg=null) ->
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
      minSPA = d.properties.samplesPerArea if minSPA == 0 or minSPA > d.properties.samplesPerArea
      maxSPA = d.properties.samplesPerArea if maxSPA == 0 or maxSPA < d.properties.samplesPerArea
      #console.log "samples per area? #{result[k].total} / #{d.properties.AREA} = #{result[k].total / d.properties.AREA}"

  console.log "totals: #{minTotal} - #{maxTotal}"
  console.log "densities: #{minSPA} - #{maxSPA}"
  dens = d3.scale.log().domain([minSPA,maxSPA]).range([0,1])
  totsF = d3.scale.log().domain([minTotal,maxTotal]).range([0,0.8])
  tots = (d) -> 0.2 + totsF(d)

  # http://en.wikipedia.org/wiki/Navajo_white
  # ...it does not easily show stains from cigarette smoke or fingerprints...
  lowcolors = d3.scale.linear().domain([0,1]).range([d3.hsl(36,1,1),d3.hsl(36,0.5,0.5)])
  svg = d3.select('svg') if not svg?
  d = svg.selectAll(".lower")
    .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
  d.exit().remove()
  d.attr('fill', (d) ->
      k = "#{d.properties.State}-#{d.properties.PUMA5}"
      val = round(result[k].lower / pumatotals[k].total,percentBreakouts)
      lowcolors(val)
    )
  #d.attr('opacity', (d) -> tots(pumatotals["#{d.properties.State}-#{d.properties.PUMA5}"].total))

  d = svg.selectAll(".middle")
    .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
  d.exit().remove()
  d.attr('fill', (d) ->
      k = "#{d.properties.State}-#{d.properties.PUMA5}"
      val = round(result[k].middle / pumatotals[k].total,percentBreakouts)
      den = round(dens(d.properties.samplesPerArea),percentBreakouts)
      #console.log "url(#middlepattern-#{val}-#{den}) #{result[k].middle} #{pumatotals[k].total}"
      "url(#middlepattern-#{val}-#{den})"
    )
  #d.attr('opacity', (d) -> tots(pumatotals["#{d.properties.State}-#{d.properties.PUMA5}"].total))

  d = svg.selectAll(".upper")
    .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
  d.exit().remove()
  d.attr('fill', (d) ->
      k = "#{d.properties.State}-#{d.properties.PUMA5}"
      val = round(result[k].upper / pumatotals[k].total,percentBreakouts)
      den = round(dens(d.properties.samplesPerArea),percentBreakouts)
      "url(#upperpattern-#{val}-#{den})"
    )
  #d.attr('opacity', (d) -> tots(pumatotals["#{d.properties.State}-#{d.properties.PUMA5}"].total))

# hack for cakefile to read this as an npm module...
module?.exports =
  makeMap: makeMap
  doMakeMap: doMakeMap
  doPaintMap: doPaintMap
  paintMap: paintMap
