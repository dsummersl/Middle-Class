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
    # width: each circle is radius 5, and I want to show 3 whole ones on the top layer
    # width = 3 * 5 + .5 + 1 + 1 + .5 = 15 + 3 = 18
    # height: two rows, no space between the rows:
    # height = 2 * 5 + 1 = 11
    patternArea = (d) ->
      d.attr('patternUnits', 'userSpaceOnUse')
      .attr('x',0)
      .attr('y',0)
      .attr('width',2.25)
      .attr('height',1.375)
      .attr('viewBox','0 0 18 11')
    p = defs.append('pattern')
      .attr('id', 'lowerpattern')
      .call(patternArea)
    p.append('circle')
      .attr('cx',3)
      .attr('cy',3)
      .attr('r', 2.5)
      .attr('fill', '#ec9')
    p.append('circle')
      .attr('cx',11.5)
      .attr('cy',8)
      .attr('r', 2.5)
      .attr('fill', '#ec9')
    p = defs.append('pattern')
      .attr('id', 'middlepattern')
      .call(patternArea)
    p.append('circle')
      .attr('cx',9)
      .attr('cy',3)
      .attr('r', 2.5)
      .attr('fill', 'green')
    p.append('circle')
      .attr('cx',0)
      .attr('cy',8)
      .attr('r', 2.5)
      .attr('fill', 'green')
    p.append('circle')
      .attr('cx',18)
      .attr('cy',8)
      .attr('r', 2.5)
      .attr('fill', 'green')
    p = defs.append('pattern')
      .attr('id', 'upperpattern')
      .call(patternArea)
    p.append('circle')
      .attr('cx',15)
      .attr('cy',3)
      .attr('r', 2.5)
      .attr('fill', 'red')
    p.append('circle')
      .attr('cx',6)
      .attr('cy',8)
      .attr('r', 2.5)
      .attr('fill', 'red')
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

        #TODO 22-01905 -- is combined with xxx b/c of population displacement
        d3.selectAll(".lower")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .transition()
          .delay(1000)
          .attr('fill',"url(#lowerpattern)")
          .attr('opacity', (d) =>
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = result[k].lower / result[k].total
          )
        d3.selectAll(".middle")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .transition()
          .delay(1000)
          .attr('fill',"url(#middlepattern)")
          .attr('opacity', (d) =>
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = result[k].middle / result[k].total
          )
        d3.selectAll(".upper")
          .data(features, (d) -> "#{d.properties.State}-#{d.properties.PUMA5}-#{d.properties.PERIMETER}")
          .transition()
          .delay(1000)
          .attr('fill',"url(#upperpattern)")
          .style('opacity', (d) =>
            k = "#{d.properties.State}-#{d.properties.PUMA5}"
            val = result[k].upper / result[k].total
          )
        $('#startupdialog').fadeOut()
    )
