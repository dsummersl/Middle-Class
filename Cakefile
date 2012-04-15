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

option '-t','--type [TYPE]', 'Type of map to generate (1percent = SPUMA, 5percent = PUMA)'

zeroFill = ( number, width ) ->
  width -= number.toString().length
  return new Array( width + (/\./.test( number ) ? 2 : 1) ).join( '0' ) + number if width > 0
  return number

dbconnect = ->
  mongoose = require('mongoose')
  db = mongoose.connect('mongodb://localhost/middleclass')
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
  return [db,Entry]

task 'server', 'database server', ->
  conn = dbconnect()
  db = conn[0]
  Entry = conn[1]
  express = require('express')
  app = express.createServer()

  groupSearch = (req,res,lowmarker,middlemarker,condition) ->
    grp = (doc,out) =>
      out.lower += doc.incomecount if doc.income <= out.lowmarker
      out.middle += doc.incomecount if doc.income <= out.middlemarker and doc.income > out.lowmarker
      out.upper += doc.incomecount if doc.income > out.middlemarker
    done = (err,doc) ->
      if err
        console.log "Error: #{err}"
        res.json {result: "failure", extra: err}
        return
      done = {}
      done["#{i.state}-#{i.puma}"] = i for i in doc
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

  app.get '/classes/all/:lm/:mu', (req,res) -> groupSearch(req,res,req.params.lm,req.params.mu,{})

  # get the counts for a specific puma: lm is the boundary between lower middle and mu is the boundary between middle and upper.
  # TODO these individual puma searches dont' work - they need to include the state in the parameters.
  finishSearch = (search,req,res) ->
    Entry.findOne {puma: req.params.puma}, (err,doc) ->
      if err or doc?.puma != req.params.puma
        console.log "Error: #{err}"
        res.json {result: "failure", extra: "#{err} (no puma)"}
        return
      search.select('puma','incomecount')
        .run (err,doc) ->
          if err
            console.log "Error: #{err}"
            res.json {result: "failure", extra: err}
            return
          total = 0
          total += parseInt(i.incomecount) for i in doc
          res.json {result: "success", puma: req.params.puma, total: total}

  app.get '/classes/:puma/lte/:mu', (req,res) ->
    counts = Entry.where('puma').equals(req.params.puma)
      .where('income').lte(req.params.mu)
    finishSearch(counts,req,res)
  app.get '/classes/:puma/gt/:lm', (req,res) ->
    counts = Entry.where('puma').equals(req.params.puma)
      .where('income').gt(req.params.lm)
    finishSearch(counts,req,res)
  app.get '/classes/:puma/:lm/:mu', (req,res) ->
    counts = Entry.where('puma').equals(req.params.puma)
      .where('income').gt(req.params.lm)
      .where('income').lte(req.params.mu)
    finishSearch(counts,req,res)

  app.use(express.static("#{__dirname}/public"))

  console.log "Started server on port 3333"
  app.listen(3333)

task 'processdata', 'move the data into mongoose', ->
  #exec 'r --no-save < bin/groupState.r', (error,stdout,stderr) ->
  exec 'echo no', (error,stdout,stderr) ->
    console.log "Generated stats, importing into db..."
    csv = require('ya-csv')
    reader = csv.createCsvFileReader('out.csv', {columnsFromHeader: true})
    cnt = 0
    conn = dbconnect()
    db = conn[0]
    Entry = conn[1]
    Entry.collection.drop()
    reader.addListener 'data', (data)=>
      #console.log "saving #{cnt}: #{data.PUMA} - #{data.School}"
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
      #db.disconnect()

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
    console.log "ogr2ogr -f 'GeoJSON' #{dir}-combined.geojson #{dir}-combined.shp"
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
