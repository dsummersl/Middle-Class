fs = require 'fs'
exec = require('child_process').exec
spawn = require('child_process').spawn

execHandler = (error,stdout,stderr) ->
  console.log stdout
  console.log stderr
  #console.log error if error != null

task 'copyDependencies', 'For whatever reason spine sucks at using NPM modules - we use package.json for dependencies, but app/lib/ for the actual libs. Use this command to keep those in sync', ->
  exec 'npm install .', execHandler
  exec 'cp node_modules/d3/d3.v2.js app/lib', execHandler

option '-p','--param [EXTRA]', 'Extra Param - see task'
#option '-p','--param [EXTRA]', 'Type of map to generate (1percent = SPUMA, 5percent = PUMA)'

zeroFill = ( number, width ) ->
  width -= number.toString().length
  return new Array( width + (/\./.test( number ) ? 2 : 1) ).join( '0' ) + number if width > 0
  return number

dbconnect = ->
  mongoose = require('mongoose')
  db = mongoose.connect('mongodb://localhost/middleclass')
  # TODO add a new schema with the results - store the mapreduce results
  EntrySchema = new mongoose.Schema()
  EntrySchema.add
    puma: { type: String, index: true }
    state: { type: Number, index: true }
    sex: Boolean
    age: Number
    school: Number
    income: Number
    incomecount: Number
  Entry = mongoose.model('Entry', EntrySchema)
  GroupedSchema = new mongoose.Schema()
  GroupedSchema.add
    params: { type: String, index: true }
    puma: String
    state: Number
    lower: Number
    middle: Number
    upper: Number
  Grouped = mongoose.model('Grouped', GroupedSchema)
  return [db,Entry,Grouped]

task 'server', 'database server', ->
  conn = dbconnect()
  db = conn[0]
  Entry = conn[1]
  Grouped = conn[2]
  express = require('express')
  app = express.createServer()

  groupSearch = (req,res,lowmarker,middlemarker,condition) ->
    # first see if there are any entries already
    Grouped.find({ params: "#{lowmarker}-#{middlemarker}" }, (err,docs) =>
      if err
        console.log "Error: #{err}"
        res.json {result: "failure", extra: err}
        return
      if docs.length > 0
        done = {}
        done["#{i.state}-#{i.puma}"] = i for i in docs
        res.json { result: "success", pumas: done }
        return
      grp = (doc,out) =>
        out.lower += doc.incomecount if doc.income <= out.lowmarker
        out.middle += doc.incomecount if doc.income <= out.middlemarker and doc.income > out.lowmarker
        out.upper += doc.incomecount if doc.income > out.middlemarker
      done = (err,doc) =>
        if err
          console.log "Error: #{err}"
          res.json {result: "failure", extra: err}
          return
        done = {}
        done["#{i.state}-#{i.puma}"] = i for i in doc
        for d in doc
          g = new Grouped
            params: "#{d.lowmarker}-#{d.middlemarker}"
            puma: d.puma
            state: d.state
            lower: d.lower
            middle: d.middle
            upper: d.upper
          g.save (err) -> console.log "Error saving..." if err
        res.json { result: "success", pumas: done }
      Entry.collection.group(
        {state: true, puma:true},     # keys
        condition,                    # condition
        {lower: 0, middle: 0, upper: 0, lowmarker: lowmarker, middlemarker: middlemarker },# initial
        grp,                          # reduce
        null,                         # finalize
        null,                         # command
        done                          # callback
      )
    )

  app.get '/classes/all/:lm/:mu', (req,res) -> groupSearch(req,res,req.params.lm,req.params.mu,{})
  # TODO this specific filter be returning blanks
  app.get '/classes/:state/:puma/:lm/:mu', (req,res) -> groupSearch(req,res,req.params.lm,req.params.mu,{ $and: [state: req.params.state, puma: req.params.puma ]})

  app.use(express.static("#{__dirname}/public"))

  console.log "Started server on port 3333"
  app.listen(3333)

task 'manualprocess', '', ->
  conn = dbconnect()
  db = conn[0]
  Entry = conn[1]
  Grouped = conn[2]
  csv = require('ya-csv')
  reader = csv.createCsvFileReader('out.csv', {columnsFromHeader: true})
  cnt = 0
  reader.addListener 'data', (data)=>
    console.log "saving #{cnt}: #{data.State}-#{data.PUMA}" if cnt % 1000 == 0
    Entry.collection.remove({ state: parseInt(data.State) }) if cnt == 0
    Grouped.collection.remove({ state: parseInt(data.State) }) if cnt == 0
    entry = new Entry
      puma: zeroFill(data.PUMA,6)
      state: parseInt(data.State)
      sex: (data.Sex == "1")
      age: parseInt(data.Age)
      school: parseInt(data.School)
      income: parseInt(data.Income)
      incomecount: parseInt(data.IncomeCount)
    cnt++
    entry.save (err) ->
      console.log "Error saving..." if err
      cnt--
  reader.addListener 'end', () =>
    console.log "DONE"
    done(listIndex+1,done)
    #db.disconnect()

task 'processdata', 'move the census data into mongodb (data should be in /Volumes/My Book/data external drive)', (options) ->
  # Strangely I had a couple problems importing these files:
  #  - iowa...had one fewer income bracket than every other state.
  #  - texas...had the largest CSV file. I had to split it in half in order for R to process the thing (its about a gig)
  #    wc ss10ptx.csv
  #    split -l 587063 ss10ptx.csv ss10ptxsplit.csv
  #    manually put the first line onto the second split file.
  conn = dbconnect()
  db = conn[0]
  Entry = conn[1]
  fs.readdir '/Volumes/My Book/data/', (err,list) =>
    fn = (listIndex,done) =>
      console.log "i = #{listIndex}"
      return if listIndex >= list.length
      file = list[listIndex]
      if /csv$/.test(file) && /pia.csv$/.test(file)
        console.log "r --no-save --args /Volumes/My\\ Book/data/#{file} < bin/groupState.r"
        exec "r --no-save --args /Volumes/My\\ Book/data/#{file} < bin/groupState.r", (error,stdout,stderr) ->
          console.log "Generated #{file}, importing into db..."
          csv = require('ya-csv')
          reader = csv.createCsvFileReader('out.csv', {columnsFromHeader: true})
          cnt = 0
          reader.addListener 'data', (data)=>
            console.log "saving #{cnt}: #{data.State}-#{data.PUMA}" if cnt % 1000 == 0
            # TODO don't remove those that have been split up:
            Entry.collection.remove({ state: parseInt(data.State) }) if cnt == 0
            entry = new Entry
              puma: zeroFill(data.PUMA,6)
              state: parseInt(data.State)
              sex: (data.Sex == "1")
              age: parseInt(data.Age)
              school: parseInt(data.School)
              income: parseInt(data.Income)
              incomecount: parseInt(data.IncomeCount)
            cnt++
            entry.save (err) ->
              console.log "Error saving..." if err
              cnt--
          reader.addListener 'end', () =>
            console.log "DONE"
            done(listIndex+1,done)
            #db.disconnect()
      else
        done(listIndex+1,done)
    fn(0,fn)

task 'mapcommands', 'build commands to build map', (options) ->
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

task 'd3test', '', ->
  require 'd3/index.js'
  puma = JSON.parse(fs.readFileSync("public/svg/5percent-combined.geojson"))
  spuma = JSON.parse(fs.readFileSync("public/svg/1percent-combined.geojson"))

  console.log "puma = #{(f.properties.PUMA5 for f in puma.features).length}"
  console.log "spuma = #{(f.properties.PUMA1 for f in spuma.features).length}"

  try
    console.log "a = #{d3.select('svg').length}"
    path = d3.geo.path()
    svg = d3.select('#adiv').append('svg')
    pumaparts = svg.append('g')
      .attr('id', 'pumaparts')
      .attr('class','puma')
    pumaparts.select('#pumaparts').selectAll('path')
      .data(puma.features)
      .enter()
      .append('path')
      .attr('d',path)
      .call( (d) ->
        console.log "puma does it intersect?"
      )
    spumaparts = svg.append('g')
      .attr('id', 'spumaparts')
      .attr('class','spuma')
    spumaparts.select('#spumaparts').selectAll('path')
      .data(spuma.features)
      .enter()
      .append('path')
      .attr('d',path)
      .call( (d) ->
        console.log "spuma does it intersect?"
      )
  catch e
    console.log "error #{e}"
