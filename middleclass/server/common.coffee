
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

getGroup = (conn,lowmarker,middlemarker,age=null) ->
  # https://github.com/laverdet/node-fibers
  Future = require('fibers/future')
  lowmarker = breakout(lowmarker*1000,moneyMarkers)
  middlemarker = breakout(middlemarker*1000,moneyMarkers)
  age = breakout(age,ageMarkers) if age?
  console.log "group search #{lowmarker} and #{middlemarker}, age #{age}"
  # first see if there are any entries already
  cnd = {}
  cnd = { age: age } if age?
  groupedKey = "#{lowmarker}-#{middlemarker}-#{age}"
  find = Future.wrap(conn.Grouped.find,1)
  docs = find.call(conn.Grouped,{ params: groupedKey }).wait()
  console.log "groups found: #{docs.length}"
  if docs.length > 0
    done = {}
    done["#{i.state}-#{i.puma}"] = i for i in docs
    return done
  grp = (doc,out) =>
    out.lower += doc.incomecount if doc.income <= out.lowmarker
    out.middle += doc.incomecount if doc.income <= out.middlemarker and doc.income > out.lowmarker
    out.upper += doc.incomecount if doc.income > out.middlemarker
    out.lAmount += doc.income*doc.incomecount if doc.income <= out.lowmarker
    out.mAmount += doc.income*doc.incomecount if doc.income <= out.middlemarker and doc.income > out.lowmarker
    out.uAmount += doc.income*doc.incomecount if doc.income > out.middlemarker
  group = Future.wrap(conn.Entry.collection.group,6)
  doc = group.call(conn.Entry.collection,
    {state: true, puma:true},     # keys
    cnd,                          # condition
    {
      lower: 0, middle: 0, upper: 0,
      lowmarker: lowmarker, middlemarker: middlemarker,
      lAmount: 0, mAmount: 0, uAmount: 0
    },
    grp,                          # reduce
    null,                         # finalize
    null                          # command
  ).wait()
  console.log "found from entries: #{doc.length}"
  console.log "saving to groups as '#{groupedKey}'"
  done = {}
  done["#{i.state}-#{i.puma}"] = i for i in doc
  cnt = 0
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
    save = Future.wrap(g.save,0)
    save.call(g).wait()
  return done

module?.exports =
  dbconnect: dbconnect
  ageMarkers: ageMarkers
  moneyMarkers: moneyMarkers
  getGroup: getGroup
  breakout: breakout
