fs = require 'fs'
exec = require('child_process').exec
spawn = require('child_process').spawn
mongoose = require('mongoose')
common = require('./middleclass/server/common')

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

option '-p','--param [EXTRA]', 'Extra Param - see task'

task 'cookCSV', 'take the raw CSV and turn it into cooked down CSV suitable for mongodb imports with manualprocess', (options) ->
  csv = require('ya-csv')
  reader = csv.createCsvFileReader( options.param, {columnsFromHeader: true})
  cooked = {}
  cnt = 0
  console.log "State,PUMA,Sex,Age,School,Income,IncomeCount"
  reader.addListener 'data', (d) ->
    key = "#{d.ST},#{d.PUMA},#{d.SEX},#{common.breakout(d.AGEP,common.ageMarkers)},#{d.SCHL},#{common.breakout(d.PINCP,common.moneyMarkers)}"
    cooked[key] = 0 if not cooked[key]
    cooked[key] += 1
    cnt++
    console.error "read: #{cnt}" if cnt % 100000 == 0
  reader.addListener 'end', () ->
    for k,v of cooked
      console.log "#{k},#{v}"

task 'manualprocess', 'given a csv file, manually convert it to CSV and import it to mongo.', (options) ->
  conn = common.dbconnect()
  importCSV(conn,options.param, ->
    conn.db.disconnect()
  )

# mongodump ---host 127.0.0.1:3002 -d meteor
# tar zcvf dump.tgz dump
# mv dump.tgz lib
# rm -rf dump
#
# tar zxvf lib/dump.tgz
# mongorestore --host localhost:3002 dump

task 'buildGroups', 'Once the dbs are built, use this command to build extra caches', ->
  require('fibers')
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
  # Strangely I had a couple problems importing these files:
  #  - iowa...had one fewer income bracket than every other state.
  #  - texas...had the largest CSV file. I had to split it in half in order for R to process the thing (its about a gig)
  #    wc ss10ptx.csv
  #    split -l 587063 ss10ptx.csv ss10ptxsplit.csv
  #    manually put the first line onto the second split file.
  conn = common.dbconnect()
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
  if options.type not in ['1percent','5percent']
    console.log "You need to specify a type: 1percent or 5percent"
    return
  # Before you can do this you need to download the actual
  # shape files form the census. Do this:
  # mkdir 5percent
  # cd 5percent
  # sh ../bin/get5percent.sh
  # for i in *.zip; do unzip $i; done
  # cd ..
  dir = options.type
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
    console.log "rm #{dir}-combined.shp"
    console.log "mv #{dir}-combined.geojson public/svg"

###
task 'data1', 'Build some data with d3', ->
  d3 = require('./app/lib/d3.min')
  console.log "d3 version = "+ d3.version

task 'data2', 'Build some data with d3', ->
  hem = spawn 'hem', ['server']
  phantom = require('phantom')
  phantom.create (ph) ->
    ph.createPage (page) ->
      page.open 'http://localhost:9294/sandbox.html', (status) ->
        page.evaluate (-> window), (window) ->
          require = window.require
          require('lib/d3.v2')
          console.log("d3 version = "+ d3.version)
          ph.exit()
          hem.kill()

task 'testold', 'Build some data with d3', ->
  jsdom = require('jsdom')
  jsdom.defaultDocumentFeatures = {
    FetchExternalResources   : ['script'],
    ProcessExternalResources : true,
    MutationEvents           : true,
    QuerySelector            : true
  }
  jsdom.env({
    html: 'test/public/index.html'
    scripts: [ fs.readFileSync('node_modules/jqueryify/index.js') ]
    done: (errors,window) ->
      console.log "looking..."
      #console.log "Suites: "+ window.$('.runner .description').text()
      console.log "Suites: "+ window.$('*').text()
  })
###

task 'd3test', 'render my map to a file.', ->
  require 'd3/index.js'
  extras = require('./middleclass/client/extras')

  #try
  puma = JSON.parse(fs.readFileSync("middleclass/public/svg/5percent-combined.geojson"))
  console.log "puma = #{(f.properties.PUMA5 for f in puma.features).length}"
  extras.populateMap('body',puma)
  html = d3.select("svg")
    .attr("title", "Map Rendering")
    .attr("version", 1.1)
    .attr("xmlns", "http://www.w3.org/2000/svg")
    .node().parentNode.innerHTML
  fs.writeFile("out.svg",html)
  #catch e
  #  console.log "error #{e}"
