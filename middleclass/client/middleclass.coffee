questions = [ {
    question: "How would you defind low/middle?"
    questiondesc: "?"
    questiondefault: 25
    questionhandler: (v) -> Session.set('lowmarker',v)
  },{
    question: "How would you defind middle/upper?"
    questiondesc: "?"
    questiondefault: 65
    questionhandler: (v) -> Session.set('middlemarker',v)
  },{
    question: "How old are you?"
    questiondesc: "?"
    questiondefault: 35
    questionhandler: (v) -> Session.set('age',v)
  }
]

Session.set('questionNumber', 0)
Session.set('map', null)
Session.set('status', "Loading map...")
Session.set('lowmarker',0)
Session.set('middlemarker',250)
Session.set('age',null)

Meteor.startup ->
  # TODO I can't use templates and the modal stuff b/c the template completely rerenders my template for the popup thereby
  # losing some of the already set classes applied to the modes.
  $('#classesdialog').fadeOut()
  $('#optionsbutton').click ->
    $('#question').text(questions[Session.get('questionNumber')].question)
    #$('#questiondesc').text(questions[Session.get('questionNumber')].questiondesc)
    $('#filterpopupval').attr('value',questions[Session.get('questionNumber')].questiondefault)
    $('#classesdialog').fadeIn()
  $('#changebutton').click ->
    $('#classesdialog').fadeOut()
    questions[Session.get('questionNumber')].questionhandler($('#filterpopupval').val())
    Session.set('questionNumber',Session.get('questionNumber')+1)
    console.log "q = #{Session.get('questionNumber')}"
  ContextWatcher -> $('#startupdialogmessage').text(Session.get('status'))
  ContextWatcher ->
    if Session.get('age')
      $('#filterdesc').text("When the middle class earns $#{Session.get('lowmarker')}k-$#{Session.get('middlemarker')}k, age #{Session.get('age')}")
    else
      $('#filterdesc').text("When the middle class earns $#{Session.get('lowmarker')}k-$#{Session.get('middlemarker')}k")
  ContextWatcher -> if Session.get('questionNumber') >= questions.length then $('#optionsbutton').attr('disabled','disabled') else $('#optionsbutton').removeAttr('disabled')
  ContextWatcher ->
    #printStackTrace() if printStackTrace?
    step = Session.get('questionNumber')
    $('#optionsbutton').text("Start") if step == 0
    $('#optionsbutton').text("Step #{step}") if step > 0

  makeMap ->
    new VisibleOnMovementItem('#optionsbutton',3000)
    paintMap()
# vim: set et,sw=2,ts=2:
