
dbconnect = ->
  mongoose = require('mongoose')
  #db = mongoose.connect('mongodb://localhost/middleclass')
  db = mongoose.connect(__meteor_bootstrap__.mongo_url)
  EntrySchema = new mongoose.Schema()
  EntrySchema.add
    puma: String
    state: Number
    sex: Boolean
    age: { type: Number, index: true }
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
  return {db: db,Entry: Entry,Grouped: Grouped}

# TODO delete - not used...
zeroFill = ( number, width ) ->
  width -= number.toString().length
  return new Array( width + (/\./.test( number ) ? 2 : 1) ).join( '0' ) + number if width > 0
  return number

# Given an integer v and an array of integers, find the smallest integer in the
# array that is larger than v.
breakout = (v,markers) ->
  bucket = 0
  bucket = a for a in markers when a >= v and bucket == 0
  return bucket

ageMarkers = [17,24,30,34,39,49,59,150]
moneyMarkers = (x*5000 for x in [1..20])
moneyMarkers.push(100000000) # infinity

###
hasGroup = (groupId) ->
  results = promise()
  Grouped.count { params: "#{lowmarker}-#{middlemarker}-#{age}" }, (err,doc) => results.set(not err and doc > 0)
  return results.get()
###

getGroup = (conn,lowmarker,middlemarker,age=null) ->
  promise = require('fibers-promise')
  lowmarker = breakout(lowmarker*1000,moneyMarkers)
  middlemarker = breakout(middlemarker*1000,moneyMarkers)
  age = breakout(age,ageMarkers) if age?
  console.log "group search #{lowmarker} and #{middlemarker}, age #{age}"
  # first see if there are any entries already
  cnd = {}
  cnd = { age: age } if age?
  results = promise()
  groupedKey = "#{lowmarker}-#{middlemarker}-#{age}"
  conn.Grouped.find({ params: groupedKey }, (err,docs) =>
    if err
      #results.set(new Meteor.Error(500, err))
      results.set("err: "+ err)
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
        #results.set(new Meteor.Error(500, err))
        results.set("err: "+ err)
        return
      console.log "found from entries: #{doc.length}"
      console.log "saving to groups as '#{groupedKey}'"
      done = {}
      done["#{i.state}-#{i.puma}"] = i for i in doc
      cnt = 0
      processed = 0
      for d in doc
        cnt++
        g = new conn.Grouped
          params: groupedKey
          puma: d.puma
          state: d.state
          lower: d.lower
          middle: d.middle
          upper: d.upper
          lAmount: d.lAmount
          mAmount: d.mAmount
          uAmount: d.uAmount
        g.save (err) ->
          processed++
          console.log "Error saving..." if err
          if processed == cnt
            console.log "done"
            results.set(done)
    conn.Entry.collection.group(
      {state: true, puma:true},     # keys
      cnd,                          # condition
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
  #if finalVal instanceof Meteor.Error
  #  throw finalVal
  return finalVal

module?.exports =
  dbconnect: dbconnect
  ageMarkers: ageMarkers
  moneyMarkers: moneyMarkers
  getGroup: getGroup
  breakout: breakout
