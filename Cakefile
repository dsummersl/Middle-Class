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

task 'data1', 'Build some data with d3', ->
  d3 = require('./app/lib/d3.min')
  console.log "d3 version = "+ d3.version

task 'data2', 'Build some data with d3', ->
  ###
  jsdom = require('jsdom')
  jsdom.env({
    html: '<html><body></body></html>'
    src: [ fs.readFileSync('public/application.js') ]
    done: (errors,window) ->
      require = window.require
      d3 = require('lib/d3.min')
      console.log "d3 version = "+ d3.version
      console.log "d3 #{k} = #{v}" for k,v of d3
      #d3.select('nothing')
      console.log JSON.stringify(d3)
  })
  ###
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
