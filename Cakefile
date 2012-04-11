fs = require 'fs'
exec = require('child_process').exec
spawn = require('child_process').spawn

# TODO make a chain-able command for exec that also echos the command itself.
execHandler = (error,stdout,stderr) ->
  console.log stdout
  console.log stderr
  #console.log error if error != null

task 'copyDependencies', 'For whatever reason spine sucks at using NPM modules - we use package.json for dependencies, but app/lib/ for the actual libs. Use this command to keep those in sync', ->
  exec 'npm install .', execHandler
  exec 'cp node_modules/d3/d3.v2.js app/lib', execHandler

option '-t','--type [TYPE]', 'Type of map to generate (1percent = SPUMA, 5percent = PUMA)'

task 'mkdata', 'use R to convert the source CSV files', ->
  exec 'r --no-save < bin/groupState.r ; mv out.csv public/data/nc.csv', execHandler

###
# http://127.0.0.1:28017/middleclass/entries/
# Wanna do something like this via HTTP:
# db.entries.find({puma:"300", age: "(40,50]", school: "11"})
###

task 'setupdatabase', 'setup the couchdb database', ->
  cradle = require('cradle')
  console.log "cradle..."
  db = new(cradle.Connection)().database('middleclass')
  db.exists( (err,exists) ->
    if err
      console.log "Error: #{err}"
      return
    #db.destroy() if exists
    #db.create()
    # http://localhost:5984/middleclass/_design/spineapp/_view/count
    db.save('_design/spineapp',
      # count up all the rows of data
      count:
        map: (doc) -> emit(doc._id)
        reduce: (key,values,rereduce) ->
          return sum(values) if rereduce
          return values.length
      # group puma by different monetary amounts.
    )
  )

task 'processdata', 'move the data into mongoose', ->
  csv = require('ya-csv')
  cradle = require('cradle')
  console.log "cradle..."
  db = new(cradle.Connection)().database('middleclass')
  db.exists( (err,exists) ->
    console.log "Error: #{err}" if err
    console.log "db exists!" if exists
    db.create() if not exists

    reader = csv.createCsvFileReader('public/data/nc.csv', {columnsFromHeader: true})
    cnt = 0
    reader.addListener 'data', (data)=>
      #console.log "saving #{cnt}: #{data.PUMA} - #{data.School}"
      cnt++
      db.save({
        puma: data.PUMA
        state: 'nc'
        sex: (data.Sex == "1")
        age: data.Age
        school: data.School
        income: data.Income
        incomecount: data.IncomeCount
      }, (err,res) ->
        console.log "Error saving..." if err
      )
    reader.addListener 'end', () =>
      console.log "DONE"
  )

task 'mapcommands', 'build commands to build map', (options) ->
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
    first = false
    for i in list
      if /shp$/.test(i)
        if !first
          first = true
          cmds.push "ogr2ogr #{dir}-combined.shp #{dir}/#{i}"
        else
          cmds.push "ogr2ogr -update -append #{dir}-combined.shp #{dir}/#{i} -nln #{dir}-combined"
    console.log i for i in cmds
    console.log "ogr2ogr -f 'GeoJSON' #{dir}-combined.json #{dir}-combined.shp"
    console.log "rm #{dir}-combined.shp"
    console.log "mv #{dir}-combined.json public/svg"

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

  #console.log "total parts = #{json}"
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
