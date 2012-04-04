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

task 'test','Run unit tests', (o) ->
  exec 'NODE_PATH="app" ./node_modules/.bin/jasmine-node --coffee --matchall test/specs', execHandler

task 'make1percent', 'build an svg of super-PUMAs', ->
  exec 'kartograph svg kartograph/1percent.yaml; mv tmp.svg 1percent.svg; mv 1percent.svg public/svg', execHandler

task 'make5percent', 'build an svg of PUMAs', ->
  # Before you can do this you need to download the actual
  # shape files form the census. Do this:
  # mkdir 5percent
  # cd 5percent
  # sh ../bin/get5percent.sh
  # for i in *.zip; do unzip $i; done
  # cd ..
  exec 'kartograph svg kartograph/5percent.yaml; mv tmp.svg 5percent.svg; mv 5percent.svg public/svg', execHandler

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

task 'd3', 'Do something with d3', ->
  jsdom = require('jsdom')
  jsdom.env({
    html: 'public/sandbox.html'
    done: (errors,window) ->
      require('d3/index.js')
      console.log("d3 version = "+ d3.version)
  })
