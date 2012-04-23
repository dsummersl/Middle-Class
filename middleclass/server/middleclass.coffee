dbconnect = ->
  db = mongoose.connect('mongodb://localhost/middleclass')
  #db = mongoose.connect(__meteor_bootstrap__.mongo_url)
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
    lAmount: Number
    mAmount: Number
    uAmount: Number
  Grouped = mongoose.model('Grouped', GroupedSchema)
  return [db,Entry,Grouped]

promise = __meteor_bootstrap__.require('fibers-promise')
mongoose = __meteor_bootstrap__.require('mongoose')
# TODO I'd like to just use the bootstrap URL:
#db = mongoose.connect(__meteor_bootstrap__.mongo_url)
conn = dbconnect()
db = conn[0]
Entry = conn[1]
Grouped = conn[2]
Entry.count({}, (err,doc) -> console.log "entry count: #{doc}")
Grouped.count({}, (err,doc) -> console.log "grouped count: #{doc}")

Meteor.methods
  getGroup: (lowmarker,middlemarker) ->
    console.log "group search #{lowmarker} and #{middlemarker}"
    # first see if there are any entries already
    results = promise()
    Grouped.find({ params: "#{lowmarker}-#{middlemarker}" }, (err,docs) =>
      if err
        results.set(new Meteor.Error(500, err))
        return
      console.log "groups found: #{docs.length}"
      if docs.length > 0
        done = {}
        done["#{i.state}-#{i.puma}"] = i for i in docs
        results.set(done)
        return
      grp = (doc,out) =>
        out.lower += doc.incomecount if doc.income <= out.lowmarker
        out.middle += doc.incomecount if doc.income <= out.middlemarker and doc.income > out.lowmarker
        out.upper += doc.incomecount if doc.income > out.middlemarker
        out.lAmount += doc.income*doc.incomecount if doc.income <= out.lowmarker
        out.mAmount += doc.income*doc.incomecount if doc.income <= out.middlemarker and doc.income > out.lowmarker
        out.uAmount += doc.income*doc.incomecount if doc.income > out.middlemarker
      done = (err,doc) =>
        if err
          results.set(new Meteor.Error(500, err))
          return
        console.log "found from entries: #{doc.length}"
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
            lAmount: d.lAmount
            mAmount: d.mAmount
            uAmount: d.uAmount
          g.save (err) -> console.log "Error saving..." if err
        results.set(done)
      Entry.collection.group(
        {state: true, puma:true},     # keys
        {},                           # condition
        {
          lower: 0, middle: 0, upper: 0,
          lowmarker: lowmarker, middlemarker: middlemarker,
          lAmount: 0, mAmount: 0, uAmount: 0
        },
        grp,                          # reduce
        null,                         # finalize
        null,                         # command
        done                          # callback
      )
    )
    finalVal = results.get()
    if finalVal instanceof Meteor.Error
      throw finalVal
    return finalVal
# vim: set et,sw=2,ts=2:
