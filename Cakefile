fs = require 'fs'
exec = require('child_process').exec
spawn = require('child_process').spawn
mongoose = require('mongoose')
common = require('./middleclass/server/common')
extras = require('./middleclass/client/extras')
require('fibers')

# Support functions {{{
execHandler = (error,stdout,stderr) ->
  console.log stdout
  console.log stderr
  #console.log error if error != null

importCSV = (conn,file,callback) ->
  cmd = "rm out.csv ; time cake -p '#{file}' cookCSV > out.csv"
  console.log "invoking command: '#{cmd}'"
  exec cmd, (error,stdout,stderr) ->
    console.log "Generated #{file}, importing into db..."
    console.log stderr
    csv = require('ya-csv')
    reader = csv.createCsvFileReader('out.csv', {columnsFromHeader: true})
    cnt = 0
    processed = 0
    alldone = false
    reader.addListener 'data', (data)=>
      console.log "saving #{processed}/#{cnt}" if cnt % 1000 == 0
      # TODO don't remove those that have been split up:
      conn.Entry.collection.remove({ state: parseInt(data.State) }) if cnt == 0
      entry = new conn.Entry
        puma: data.PUMA
        state: data.State
        sex: (data.Sex == "1")
        age: data.Age
        school: data.School
        income: data.Income
        incomecount: parseInt(data.IncomeCount)
      cnt++
      entry.save (err) ->
        console.log "Error saving: #{JSON.stringify(data)}" if err
        processed++
        if processed == cnt and alldone
          console.log "DONE #{processed}/#{cnt}"
          callback()
    reader.addListener 'end', () => alldone = true
# }}}

option '-p','--param [EXTRA]', 'Extra Param - see task'

task 'cookCSV', 'take the raw CSV and turn it into cooked down CSV suitable for mongodb imports with manualprocess', (options) ->
  csv = require('ya-csv')
  reader = csv.createCsvFileReader( options.param, {columnsFromHeader: true})
  cooked = {}
  cnt = 0
  console.log "State,PUMA,Sex,Age,School,Income,IncomeCount"
  reader.addListener 'data', (d) ->
    # INTP = interest income
    # RETP = retirement income
    # PINCP = personal income
    # OIP = other income
    # PAP = public assistance
    # PERNP = total personal earnings
    # SEMP = self employment income
    # SSIP = supplementary security income
    # SSP = social security income
    # WAGP = wages and salary the last 12 months
    #console.log "INTP #{d.INTP} RETP #{d.RETP} PINCP #{d.PINCP} OIP #{d.OIP} PAP #{d.PAP} PERNP #{d.PERNP} SEMP #{d.SEMP} SSIP #{d.SSIP} SSP #{d.SSP} WAGP #{d.WAGP}"
    # I don't need to include these other columns b/c they are all wrapped up into the PINCP values
    adj = d.ADJINC / 1000000
    total = d.PINCP*adj
    key = "#{d.ST},#{d.PUMA},#{d.SEX},#{common.breakout(d.AGEP,common.ageMarkers)},#{d.SCHL},#{common.breakout(total,common.moneyMarkers)}"
    cooked[key] = 0 if not cooked[key]
    cooked[key] += 1
    cnt++
    console.error "read: #{cnt}" if cnt % 100000 == 0
  reader.addListener 'end', () ->
    for k,v of cooked
      console.log "#{k},#{v}"

task 'manualprocess', 'given a csv file, manually convert it to CSV and import it to mongo.', (options) ->
  conn = common.dbconnect('mongodb://127.0.0.1:3002/meteor')
  importCSV(conn,options.param, ->
    conn.db.disconnect()
  )

# mongodump --host 127.0.0.1:3002 -d meteor
# tar zcvf dump.tgz dump
# mv dump.tgz lib
# rm -rf dump
#
# tar zxvf lib/dump.tgz
# mongorestore --host localhost:3002 dump

task 'buildGroups', 'Once the dbs are built, use this command to build extra caches', ->
  Fiber( () ->
    console.log "starting"
    conn = common.dbconnect('mongodb://127.0.0.1:3002/meteor')
    for l in common.moneyMarkers
      for m in common.moneyMarkers when m > l
        result = common.getGroup(conn,l/1000,m/1000,null)
        lCnt = 0
        mCnt = 0
        uCnt = 0
        lSum = 0
        mSum = 0
        uSum = 0
        for k,v of result
          lCnt += v.lower
          mCnt += v.middle
          uCnt += v.upper
          lSum += v.lAmount
          mSum += v.mAmount
          uSum += v.uAmount
        console.log "#{l}-#{m}: #{lCnt},#{mCnt},#{uCnt}  #{lSum},#{mSum},#{uSum} #{lSum/lCnt},#{mSum/mCnt},#{uSum/uCnt}"
    conn.db.disconnect()
  ).run()

task 'processdata', 'move the census data into mongodb (data should be in /Volumes/My Book/data external drive)', (options) ->
  conn = common.dbconnect('mongodb://127.0.0.1:3002/meteor')
  dir = '/Volumes/My Book/data/'
  fs.readdir dir, (err,list) =>
    fn = (listIndex,done) =>
      # TODO if its the last thing in the list, then make a note to disconnect from the db when you're done.
      return if listIndex >= list.length
      file = list[listIndex]
      console.log "i = #{listIndex} #{file}"
      if /csv$/.test(file)
        importCSV(conn,"#{dir}#{file}", ->
          done(listIndex+1,done)
        )
      else
        done(listIndex+1,done)
    fn(0,fn)

task 'mapcommands', 'Build the commands to build map.', (options) ->
  # TODO states to remove: 72 (puerto rico)?
  if options.param not in ['1percent','5percent']
    console.log "You need to specify a type: 1percent or 5percent"
    return
  # Before you can do this you need to download the actual
  # shape files form the census. Do this:
  # mkdir 5percent
  # cd 5percent
  # sh ../bin/get5percent.sh
  # for i in *.zip; do unzip $i; done
  # cd ..
  dir = options.param
  fs.readdir dir, (err,list) =>
    cmds = []
    first = true
    for i in list
      if /shp$/.test(i)
        num = parseInt(i.replace(/^p5/,'').replace(/_.*$/,'').replace(/^0*/,''))
        cmds.push "echo 'processing #{i} - #{num}'"
        cmds.push "rm t.geojson"
        cmds.push "ogr2ogr -f 'GeoJSON' t.geojson #{dir}/#{i}"
        cmds.push "sed 's/properties\": { \"AREA/properties\": { \"State\": #{num}, \"AREA/' t.geojson > tt.geojson"
        if first
          first = false
          cmds.push "rm #{dir}-combined.*"
          cmds.push "ogr2ogr -f 'ESRI Shapefile' #{dir}-combined.shp tt.geojson"
        else
          cmds.push "rm t.shp"
          cmds.push "ogr2ogr -f 'ESRI Shapefile' t.shp tt.geojson"
          cmds.push "ogr2ogr -update -append #{dir}-combined.shp t.shp -nln #{dir}-combined"
    console.log i for i in cmds
    # simplify as much as possible (high a double as posible) w/o losing clarity (this makes the
    # file go from 21megs to 2 megs):
    console.log "ogr2ogr -f 'GeoJSON' -simplify 0.02 #{dir}-combined.geojson #{dir}-combined.shp"
    console.log "ogr2ogr -f 'GeoJSON' -simplify 0.001 #{dir}-huge.geojson #{dir}-combined.shp"
    console.log "rm #{dir}-combined.shp"
    console.log "mv #{dir}-combined.geojson middleclass/public/svg"
    console.log "mv #{dir}-huge.geojson middleclass/public/svg"

task 'makecitymaps', 'render all map SVGs used to make final viz.', ->
  require 'd3/index.js'

  Fiber( () ->
    conn = common.dbconnect('mongodb://127.0.0.1:3002/meteor')
    maps = [
      #[25,100,null,null],
      #[25,100,10,null],
      #[25,100,30,9],
      #[25,100,30,13],
      #[25,100,50,9],
      #[25,100,50,13],
      [25,100,70,9]
      #[25,100,70,13]
    ]
    # use the big one for the final viz
    puma = JSON.parse(fs.readFileSync("middleclass/public/svg/5percent-huge.geojson"))
    #puma = JSON.parse(fs.readFileSync("middleclass/public/svg/5percent-combined.geojson"))
    for m in maps
      console.log "rendering #{m}"
      d3.select('#maptemplate').remove()
      d3.select('body').append('div').attr('id','maptemplate')
      extras.doMakeMap('#maptemplate',puma)
      result = common.getGroup(conn,m[0],m[1],m[2],m[3])
      extras.doPaintMap(result,puma,d3.select('#maptemplate'))
      html = d3.select("svg")
        .attr("title", "Map Rendering")
        .attr("version", 1.1)
        .attr("xmlns", "http://www.w3.org/2000/svg")
        .attr("xmlns:xlink", "http://www.w3.org/1999/xlink")
        .node().parentNode.innerHTML
      fs.writeFile("map-#{m[0]}-#{m[1]}-#{m[2]}-#{m[3]}.svg",html)
    conn.db.disconnect()
  ).run()

task 'makedetailmap', 'render my map to a file - use -param to specify the svg map', (options) ->
  require 'd3/index.js'

  if not options.param?
    console.log "You need to specify a map file with -param"
    return

  svg = d3.select('body').append('svg')
  svg.selectAll('g')
    .data([
      [285,175,'Salt Lake City',options.param]
    ])
    .enter()
    .append('g')
    .html((d) -> fs.readFileSync(d[3],"utf8"))
    .call( (d) ->
      svg = d.select('svg')
      svg.attr('width',''+ 35*4)
        .attr('height',''+ 35*4)
      defs = svg.select('defs')
      scale = 5
      defs.append('svg:clipPath')
        .attr('id','firstbox')
        .append('rect')
        .attr('id','firstbox-box')
        .attr('x',804)
        .attr('y',110)
        .attr('width',35)
        .attr('height',35)
        .style('fill','none')
      svg.select('g')
        .style('clip-path','url(#firstbox)')
        .attr('transform', 'scale(5) translate(-802,-108)')
        .append('use')
        .attr('xlink:href','#firstbox-box')
    )
    ###
    [370,202,'Denver','map.svg'],
    [268,303,'Pheonix','map.svg']
    [510,216,'Kansas City'],
    [178,275,'Los Angeles'],
    [143,203,'San Francisco'],
    [180,30,'Seattle'],
    [480,325,'Dallas'],
    [505,378,'Houston'],
    [524,114,'Minneapolis'],
    [586,140,'Milwaukee'],
    [593,160,'Chicago'],
    [565,220,'St. Louis'],
    [649,142,'Detroit'],
    [656,194,'Columbus'],
    [620,261,'Nashville'],
    [658,293,'Atlanta'],
    [715,385,'Orlando'],
    [737,418,'Miami'],
    [712,257,'Charlotte'],
    [746,189,'Washington DC'],
    [777,150,'New York',6],
    [804,110,'Boston']
    ###

  html = d3.select("svg svg")
    .attr("title", "Map Rendering")
    .attr("version", 1.1)
    .attr("xmlns", "http://www.w3.org/2000/svg")
    .attr("xmlns:xlink", "http://www.w3.org/1999/xlink")
    .node().parentNode.innerHTML
  fs.writeFile("out.svg",html)
  console.log "done writing"

# vim: set fdm=marker:
