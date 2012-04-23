$('#startuptext').text("Loading map...")

questions = [ {
    question: "How would you defind low/middle?"
    questiondesc: "Val"
    questiondefault: 25
    questionhandler: (v) ->
      console.log "got val #{v}"
  },{
    question: "How would you defind middle/upper?"
    questiondesc: "Val"
    questiondefault: 65
    questionhandler: (v) ->
      console.log "got val #{v}"
  }
]

Session.set('questionNumber', 0)
Session.set('lowmarker', 25)
Session.set('middlemarker', 65)
Session.set('map', null)

Template.description.filterdesc = "..."

Template.popups.question = questions[Session.get('questionNumber')].question
Template.popups.questiondesc = questions[Session.get('questionNumber')].questiondesc
Template.popups.questiondefault = questions[Session.get('questionNumber')].questiondefault

console.log "templates setup"

Meteor.startup ->
  console.log "startup"

  $('#cancelbutton').click -> $('#classesdialog').modal('hide')
  $('#changebutton').click ->
    $('#classesdialog').modal('hide')
    Session.set('lowmarker', $('#lowmarker').val())
    Session.set('middlemarker',$('#middlemarker').val())
    # TODO I don't want things computing until BOTH
    # of these properties have changed...this 'set' should be
    # atomic

  console.log "calling make map"
  makeMap ->
    console.log "callback of make map"
    $('#startupdialog').fadeOut()
    new VisibleOnMovementItem('#optionsbutton',1500)
    paintMap()
# vim: set et,sw=2,ts=2:
