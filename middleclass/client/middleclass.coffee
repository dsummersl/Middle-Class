# TODO dunno why this doesn't import correctly
maxMoney = 100000000
ageMarkers = [17,24,30,34,39,49,59,150]
schoolMarkers = [9, 11, 12, 13, 14, 16]
# TODO change this to 300k
#moneyMarkers = (x*5000 for x in [0..60])
moneyMarkers = (x*5000 for x in [0..20])
moneyMarkers.push(maxMoney) # infinity

tomoney = (v) ->
  mm = v / 1000
  if mm > 1000
    mm = mm / 1000
    return "$#{mm}M"
  else
    return "$#{mm}k"

moneySelections = ([i,tomoney(i)] for i in moneyMarkers)
ageSelections = []
for v,i in ageMarkers
  if i == 0
    ageSelections.push [v,"less than #{v+1}"]
  else
    ageSelections.push [v,"between #{ageMarkers[i-1]+1} and #{v}"]

schoolMaps =
  9: "up to high school"
  11: "some college"
  12: "an Associate's degree"
  13: "a Bachelor's degree"
  14: "a Master's degree"
  16: "a Doctorate"

schoolSelections = []
for k,v of schoolMaps
  schoolSelections.push [k,v]

questions = [ {
    question: "Where would you set the boundary between lower and middle income?"
    values: moneySelections
    questiondefault: 25000
    questionhandler: (v) ->
      Session.set('lowmarker',v)
      removeables = i for i in moneySelections when i[0] <= v
      moneySelections.splice(i,1)  for i in removeables
      questions[1].values = moneySelections
  },{
    question: "Where would you set the boundary between middle and upper income?"
    values: moneySelections
    # TODO should prevent people from selecting values <= lowerIncome
    # Ando also change the question default if they picked a higher value
    questiondefault: 65000
    questionhandler: (v) -> Session.set('middlemarker',v)
  },{
    question: "How old are you?"
    values: ageSelections
    questiondefault: 34
    questionhandler: (v) -> Session.set('age',v)
  },{
    question: "How far have you gone in school?"
    values: schoolSelections
    questiondefault: 9
    questionhandler: (v) -> Session.set('school',v)
  }
]

Session.set('questionNumber', 0)
Session.set('map', null) # the geojson data
Session.set('pumatotals', null) # a map of puma/state -> total surveys at that area
Session.set('lastsearch', null) # last data dump
Session.set('status', "Loading map...")
Session.set('lowmarker',0)
Session.set('middlemarker',maxMoney)
Session.set('age',null)
Session.set('school',null)

Meteor.startup ->
  $('#optionsbutton').click ->
    $('#question').text(questions[Session.get('questionNumber')].question)
    $('#filterpopupval option').remove()
    $('#filterpopupval').append("<option value='#{i[0]}'>#{i[1]}</option>") for i in questions[Session.get('questionNumber')].values
    $("#filterpopupval option[value='#{questions[Session.get('questionNumber')].questiondefault}']").attr('selected','')
    $('#classesdialog').removeClass('hidden')
    $('#classesdialog').fadeIn()
  $('#changebutton').click ->
    $('#classesdialog').fadeOut()
    questions[Session.get('questionNumber')].questionhandler($('#filterpopupval').val())
    Session.set('questionNumber',Session.get('questionNumber')+1)
  ContextWatcher -> $('#startupdialogmessage').text(Session.get('status'))
  ContextWatcher ->
    if Session.get('middlemarker') == maxMoney && Session.get('lowmarker') == 0
      text = "When the middle class is everyone."
    else if Session.get('middlemarker') == maxMoney && Session.get('lowmarker') == 0
      text = "When the middle class earns more than #{tomoney(Session.get('lowmarker'))}"
    else
      text = "When the middle class earns #{tomoney(Session.get('lowmarker'))}-#{tomoney(Session.get('middlemarker'))}"
    text = "#{text}, age #{Session.get('age')}" if Session.get('age')
    text = "#{text}, with #{schoolMaps[Session.get('school')]}" if Session.get('school') and Session.get('school') > 9
    text = "#{text}, #{schoolMaps[Session.get('school')]}" if Session.get('school') and Session.get('school') == 9
    $('#filterdesc').text(text)
  ContextWatcher -> if Session.get('questionNumber') >= questions.length then $('#optionsbutton').attr('disabled','disabled') else $('#optionsbutton').removeAttr('disabled')
  ContextWatcher ->
    #printStackTrace() if printStackTrace?
    step = Session.get('questionNumber')
    $('#optionsbutton').text("Start") if step == 0
    $('#optionsbutton').text("Next") if step > 0 && step < questions.length
    $('#optionsbutton').text("Done") if step == questions.length
    $('#optionsbutton').addClass('hidden') if step == questions.length

  # TODO the first paintMap will make a redundant call
  Meteor.call('getGroup', Session.get('lowmarker'), Session.get('middlemarker'), Session.get('age'), Session.get('school'), (err, result) ->
    makeMap result, ->
      new VisibleOnMovementItem('#optionsbutton',3000)
      paintMap()
  )

# vim: set et,sw=2,ts=2:
