questions = [ {
    question: "How would you defind low/middle?"
    questiondesc: "?"
    questiondefault: 25
    questionhandler: (v) -> Session.set('lowmarker',v*1000)
  },{
    question: "How would you defind middle/upper?"
    questiondesc: "?"
    questiondefault: 65
    questionhandler: (v) -> Session.set('middlemarker',v*1000)
  },{
    question: "How old are you?"
    questiondesc: "?"
    questiondefault: 35
    questionhandler: (v) -> Session.set('age',v)
  },{
    question: "School?"
    questiondesc: "?"
    # TODO this needs to be a combobox
    questiondefault: 9
    questionhandler: (v) -> Session.set('school',v)
  }
]

# TODO dunno why this doesn't import correctly
maxMoney = 100000000
#maxMoney = 85000

Session.set('questionNumber', 0)
Session.set('map', null) # the geojson data
Session.set('pumatotals', null) # a map of puma/state -> total surveys at that area
Session.set('lastsearch', null) # last data dump
Session.set('status', "Loading map...")
Session.set('lowmarker',0)
Session.set('middlemarker',maxMoney)
Session.set('age',null)
Session.set('school',null)

schoolMaps =
  9: "high school"
  11: "some college"
  12: "associate's degree"
  13: "bachelor's degree"
  14: "master's degree"
  16: "doctorate with"

Meteor.startup ->
  $('#optionsbutton').click ->
    $('#question').text(questions[Session.get('questionNumber')].question)
    #$('#questiondesc').text(questions[Session.get('questionNumber')].questiondesc)
    $('#filterpopupval').attr('value',questions[Session.get('questionNumber')].questiondefault)
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
      text = "When the middle class earns more than $#{Session.get('lowmarker')/1000}k"
    else
      mm = Session.get('middlemarker') / 1000
      if mm > 1000
        mm = mm / 1000
        mm = "#{mm}M"
      else
        mm = "#{mm}k"
      text = "When the middle class earns $#{Session.get('lowmarker')/1000}k-$#{mm}"
    text = "#{text}, age #{Session.get('age')}" if Session.get('age')
    text = "#{text}, and #{Session.get('school')}" if Session.get('school')
    $('#filterdesc').text(text)
  ContextWatcher -> if Session.get('questionNumber') >= questions.length then $('#optionsbutton').attr('disabled','disabled') else $('#optionsbutton').removeAttr('disabled')
  ContextWatcher ->
    #printStackTrace() if printStackTrace?
    step = Session.get('questionNumber')
    $('#optionsbutton').text("Start") if step == 0
    $('#optionsbutton').text("Next") if step > 0 && step < questions.length
    $('#optionsbutton').text("Done") if step == questions.length

  # TODO the first paintMap will make a redundant call
  Meteor.call('getGroup', Session.get('lowmarker'), Session.get('middlemarker'), Session.get('age'), Session.get('school'), (err, result) ->
    makeMap result, ->
      new VisibleOnMovementItem('#optionsbutton',3000)
      paintMap()
  )

# vim: set et,sw=2,ts=2:
