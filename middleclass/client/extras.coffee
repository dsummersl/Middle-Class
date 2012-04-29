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

# Given an integer v and an array of integers, find the smallest integer in the
# array that is larger than v.
breakout = (v,markers) ->
  bucket = 0
  bucket = a for a in markers when a >= v and bucket == 0
  return bucket

percentBreakouts = (a*0.1 for a in [0..9])
percentBreakouts.push(1)

makeMap = (callback) ->
  d3.json 'svg/5percent-combined.geojson', (json) ->
    populateMap('#map',json,callback)

# given a map (json), put it on the target.
populateMap = (target,json,callback) ->
  Session?.set('map',json)
  path = d3.geo.path()
  svg = d3.select(target).append('svg')
  defs = svg.append('defs')
  # width: each circle is radius 5, and I want to show 3 whole ones on the top layer
  # width = 3 * 5 + .5 + 1 + 1 + .5 = 15 + 3 = 18
  # height: two rows, no space between the rows:
  # height = 2 * 5 + 1 = 11
  for pb,i in percentBreakouts
    w = 10*pb
    patternArea = (d) ->
      d.attr('patternUnits', 'userSpaceOnUse')
      .attr('x',0)
      .attr('y',0)
      .attr('width',1)
      .attr('height',1)
      .attr('viewBox','0 0 10 10')
    p = defs.append('pattern')
      .attr('id', "middlepattern-#{pb}")
      .call(patternArea)
    p.append('rect')
      .attr('x',0)
      .attr('y',0)
      .attr('width', w)
      .attr('height', 10)
      .attr('fill', d3.rgb('blue').brighter())
    p = defs.append('pattern')
      .attr('id', "upperpattern-#{pb}")
      .call(patternArea)
    p.append('rect')
      .attr('x',10-w)
      .attr('y',0)
      .attr('width', w)
      .attr('height', 10)
      .attr('fill', d3.rgb('red').brighter().brighter())
  parts = svg.selectAll('.part')
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
  callback()

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
        features = []
        minSPA = 0
        maxSPA = 0
        for d in Session.get('map').features
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

        om = d3.scale.sqrt().domain([minSPA,maxSPA]).range([0,1])
        densityopacitymap = (d) -> om(d) + 0.3
        #console.log "working with #{minSPA} and #{maxSPA}: #{densityopacitymap(minSPA)} and #{densityopacitymap(maxSPA)}"
        d = d3.selectAll(".lower")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .attr('opacity', (d) -> densityopacitymap(d.properties.samplesPerArea) )
        d = d3.selectAll(".middle")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
        d.exit().remove()
        d.attr('fill', (d) ->
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = breakout(result[k].middle / result[k].total,percentBreakouts)
            "url(#middlepattern-#{val})"
          )
          .attr('opacity', (d) -> densityopacitymap(d.properties.samplesPerArea) )
        d = d3.selectAll(".upper")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
        d.exit().remove()
        d.attr('fill', (d) ->
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = breakout(result[k].upper / result[k].total,percentBreakouts)
            "url(#upperpattern-#{val})"
          )
          .attr('opacity', (d) -> densityopacitymap(d.properties.samplesPerArea) )
        $('#startupdialog').fadeOut()
    )

# hack for cakefile to read this as an npm module...
module?.exports =
  makeMap: makeMap
  populateMap: populateMap
  paintMap: paintMap
