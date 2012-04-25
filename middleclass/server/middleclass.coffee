require = __meteor_bootstrap__.require if __meteor_bootstrap__?

exec = require('child_process').exec
promise = require('fibers-promise')

console.log "db: "+ __meteor_bootstrap__.mongo_url

conn = dbconnect()

Meteor.methods
  getGroup: (lowmarker,middlemarker,age=null) -> getGroup(conn,lowmarker,middlemarker,age)

Meteor.startup ->
  # check to see if there are any records...if not, then load my dump.
  conn.Entry.count({}, (err,doc) ->
    console.log "entry count: #{doc}"
    if !err and doc == 0
      console.log "no data: loading data..."
      # TODO should really wait until these are both done.
      #conn.Grouped.remove({}, (err,doc) -> console.log "err removing Grouped" if err)
      #conn.Entry.remove({}, (err,doc) -> console.log "err removing Entry" if err)
      cmd = "tar zxvf lib/dump.tgz ; mongorestore --host #{__meteor_bootstrap__.mongo_url.replace(/^mongodb:\/\//,"").replace(/\/meteor$/,"")} dump ; rm -rf dump"
      console.log "restoring a dump: #{cmd}"
      exec cmd, (error,stdout,stderr) ->
        console.log stdout
        console.log stderr
  )
  conn.Grouped.count({}, (err,doc) -> console.log "grouped count: #{doc}")
# vim: set et,sw=2,ts=2:
