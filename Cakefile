fs = require 'fs'
exec = require('child_process').exec

# TODO make a chain-able command for exec that also echos the command itself.
execHandler = (error,stdout,stderr) ->
  console.log stdout
  console.log stderr
  #console.log error if error != null

task 'copyDependencies', 'For whatever reason spine sucks at using NPM modules - we use package.json for dependencies, but app/lib/ for the actual libs. Use this command to keep those in sync', ->
  exec 'npm install .', execHandler
  exec 'cp node_modules/d3/d3.min.js app/lib', execHandler
  exec 'cp node_modules/d3/d3.csv.min.js app/lib', execHandler
