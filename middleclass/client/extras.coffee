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
percentBreakouts.push(1)

makeMap = (callback) ->
  d3.json 'svg/5percent-combined.geojson', (json) ->
    doMakeMap('#map',json,callback)

# given a map (json), put it on the target.
# 'rich' is the rich pattern SVG assumed to be about 100x100
doMakeMap = (target,json,callback) ->
  Session?.set('map',json)
  path = d3.geo.path()
  svg = d3.select(target).append('svg')
  defs = svg.append('defs')
  mainG = svg.append('g')
    .attr('class','mapparts')
  for pb,i in percentBreakouts
    r = 1+pb*3
    #console.log "pb = #{pb}"
    patternArea = (d) ->
      d.attr('patternUnits', 'userSpaceOnUse')
      .attr('x','0')
      .attr('y','0')
      .attr('width','5')
      .attr('height','5')
      .attr('viewBox','0 0 10 10')

    p = defs.append('pattern')
      .attr('id', "middlepattern-#{pb}")
      .call(patternArea)
      .append('g')
      .attr('transform',(d) -> "rotate(#{-parseInt(pb*90)} 5 5)")
    p.selectAll('line').data([0..5]).enter().append('line')
      .attr('x1','2.5')
      .attr('y1',(d)->"#{d*2}")
      .attr('x2','7.5')
      .attr('y2',(d)->"#{d*2}")
      .attr('stroke-width', "#{pb}")
      .attr('stroke', d3.rgb('blue').brighter())

    p = defs.append('pattern')
      .attr('id', "upperpattern-#{pb}")
      .call(patternArea)
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
  ### TODO support a mouseover graphic
  .on('mouseover', (d) ->
    $('#hoverdetail').text("State: #{d.properties.State}")
    console.log "doing a mouse over for #upper-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}"
  )
  .on('mouseout', (d) ->
    $('#hoverdetail').text("US")
    console.log "doing a mouse over for #upper-#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}"
  )
  ###
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
        Session.set('status',"Loading stats...")
        doPaintMap(result,Session.get('map'))
        $('#startupdialog').fadeOut()
    )

# a non-meteor method that updates the map.
doPaintMap = (result,map,svg=null) ->
  features = []
  minSPA = 0
  maxSPA = 0
  for d in map.features
    k = "#{d.properties.State}-#{d.properties.PUMA5}"
    if result[k]?
      features.push(d)
      result[k].total = result[k].lower + result[k].middle + result[k].upper
      d.properties.AREA = 0.01 if d.properties.AREA < 0.01
      # from 500 to 2 million, lets change the pattern circle radius depending on this density.
      d.properties.samplesPerArea = result[k].total
      minSPA = d.properties.samplesPerArea if minSPA == 0 or minSPA > d.properties.samplesPerArea
      maxSPA = d.properties.samplesPerArea if maxSPA == 0 or maxSPA < d.properties.samplesPerArea
      #console.log "samples per area? #{result[k].total} / #{d.properties.AREA} = #{result[k].total / d.properties.AREA}"

  om = d3.scale.linear().domain([minSPA,maxSPA]).range([0,1])
  densityopacitymap = (d) -> om(d) + 0.3
  #console.log "working with #{minSPA} and #{maxSPA}: #{densityopacitymap(minSPA)} and #{densityopacitymap(maxSPA)}"

  # http://en.wikipedia.org/wiki/Navajo_white
  # ...it does not easily show stains from cigarette smoke or fingerprints...
  lowcolors = d3.scale.linear().domain([0,1]).range([d3.hsl(36,1,1),d3.hsl(36,0.5,0.5)])
  svg = d3.select('svg') if not svg?
  d = svg.selectAll(".lower")
    .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
  d.exit().remove()
  d.attr('fill', (d) ->
      k = "#{d.properties.State}-#{d.properties.PUMA5}"
      val = round(result[k].lower / result[k].total,percentBreakouts)
      lowcolors(val)
    )
 
  d = svg.selectAll(".middle")
    .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
  d.exit().remove()
  d.attr('fill', (d) ->
      k = "#{d.properties.State}-#{d.properties.PUMA5}"
      val = round(result[k].middle / result[k].total,percentBreakouts)
      "url(#middlepattern-#{val})"
    )

  d = svg.selectAll(".upper")
    .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
  d.exit().remove()
  d.attr('opacity', '0')

# hack for cakefile to read this as an npm module...
module?.exports =
  makeMap: makeMap
  doMakeMap: doMakeMap
  doPaintMap: doPaintMap
  paintMap: paintMap
