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

makeMap = (callback) ->
  d3.json "svg/5percent-combined.geojson", (json) ->
    Session.set('map',json)
    path = d3.geo.path()
    svg = d3.select('#map').append('svg')
    defs = svg.append('defs')
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
    callback()

paintMap = ->
  paintMapContext = new Meteor.deps.Context()
  paintMapContext.on_invalidate paintMap
  paintMapContext.run ->
    $('#startupdialog').fadeIn()
    Session.set('status',"Updating map...")
    Meteor.call('getGroup', Session.get('lowmarker'), Session.get('middlemarker'), Session.get('age'), (err, result) ->
      if err
        console.log "ERROR: #{err}"
      else
        Session.set('status',"Loading stats...")
        features = []
        for d in Session.get('map').features
          k = "#{d.properties.State}-#{d.properties.PUMA5}"
          if result[k]?
            features.push(d)
            result[k].total = result[k].lower + result[k].middle + result[k].upper

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
            val = result[k].lower / result[k].total
            #return lowscale(val)
          )
        d3.selectAll(".middle")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .transition()
          .delay(1000)
          .attr('fill',"url(#middlepattern)")
          .attr('opacity', (d) =>
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = result[k].middle / result[k].total
            #return middlescale(val)
          )
        d3.selectAll(".upper")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .transition()
          .delay(1000)
          .attr('fill', 'blue')
          .style('opacity', (d) =>
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = result[k].upper / result[k].total
            #return upperscale(val)
          )
        $('#startupdialog').fadeOut()
    )
