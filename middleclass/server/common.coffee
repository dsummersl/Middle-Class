try
  round = require('../common').round
catch e
  console.log "no require"

dbconnect = (dburl=__meteor_bootstrap__?.mongo_url)->
  #db = mongoose.connect('mongodb://localhost/middleclass')
  mongoose = require('mongoose')
  db = mongoose.connect(dburl)
  EntrySchema = new mongoose.Schema()
  EntrySchema.add
    puma: String
    state: Number
    sex: Boolean
    age: { type: Number, index: true }
    school: { type: Number, index: true }
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

ageMarkers = [17,24,30,34,39,49,59,150]
schoolMarkers = [9, 11, 12, 13, 14, 16]
moneyMarkers = (x*5000 for x in [0..20])
moneyMarkers.push(100000000) # infinity
console.log "moneyMarkers = #{moneyMarkers}"

###
# bb .N/A (less than 3 years old)
           01 .No schooling completed
           02 .Nursery school to grade 4
           03 .Grade 5 or grade 6
           04 .Grade 7 or grade 8
           05 .Grade 9
           06 .Grade 10
           07 .Grade 11
           08 .12th grade, no diploma
           09 .High school graduate
           10 .Some college, but less than 1 year
           11 .One or more years of college, no degree
           12 .Associate's degree
           13 .Bachelor's degree
           14 .Master's degree
           15 .Professional school degree
           16 .Doctorate degree
###

getGroup = (conn,lowmarker,middlemarker,age=null,school=null) ->
  # https://github.com/laverdet/node-fibers
  Future = require('fibers/future')
  lowmarker = round(lowmarker*1000,moneyMarkers)
  middlemarker = round(middlemarker*1000,moneyMarkers)
  age = round(age,ageMarkers) if age?
  console.log "group search #{lowmarker} and #{middlemarker}, age #{age}, school #{school}"
  # first see if there are any entries already
  cnd = {}
  cnd = { age: parseInt(age) } if age?
  cnd = { age: parseInt(age), school: parseInt(school) } if school?
  groupedKey = "#{lowmarker}-#{middlemarker}-#{age}-#{school}"
  find = Future.wrap(conn.Grouped.find,1)
  docs = find.call(conn.Grouped,{ params: groupedKey }).wait()
  console.log "groups found: #{docs.length}"
  if docs.length > 0
    done = {}
    done["#{i.state}-#{i.puma}"] = i for i in docs
    return done
  console.log "group conditions = #{JSON.stringify(cnd)}"
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
