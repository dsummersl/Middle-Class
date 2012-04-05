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

task 'map1', 'build commands to build map', ->
  # Before you can do this you need to download the actual
  # shape files form the census. Do this:
  # mkdir 5percent
  # cd 5percent
  # sh ../bin/get5percent.sh
  # for i in *.zip; do unzip $i; done
  # cd ..
  dir = '1percent'
  fs.readdir dir, (err,list) =>
    cmds = []
    first = false
    for i in list
      if /shp$/.test(i)
        if !first
          first = true
          cmds.push "ogr2ogr combined.shp #{dir}/#{i}"
        else
          cmds.push "ogr2ogr -update -append combined.shp #{dir}/#{i} -nln combined"
    console.log i for i in cmds
task 'map2', 'convert map to geojson', ->
  exec 'ogr2ogr -f "GeoJSON" combined.json combined.shp', execHandler

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
