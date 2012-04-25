require = __meteor_bootstrap__.require if __meteor_bootstrap__?
promise = require('fibers-promise')

# TODO I'd like to just use the bootstrap URL:
#db = mongoose.connect(__meteor_bootstrap__.mongo_url)
conn = dbconnect()
conn.Entry.count({}, (err,doc) -> console.log "entry count: #{doc}")
conn.Grouped.count({}, (err,doc) -> console.log "grouped count: #{doc}")

Meteor.methods
  getGroup: (lowmarker,middlemarker,age=null) -> getGroup(conn,lowmarker,middlemarker,age)

# vim: set et,sw=2,ts=2:
