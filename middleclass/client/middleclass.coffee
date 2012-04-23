questions = [ {
    question: "How would you defind low/middle?"
    questiondesc: "Val"
    questiondefault: 25
    questionhandler: (v) ->
      console.log "1 got val #{v}"
      f = Session.get('filters')
      f.lowmarker = v
      Session.set('filters',f)
  },{
    question: "How would you defind middle/upper?"
    questiondesc: "Val"
    questiondefault: 65
    questionhandler: (v) ->
      console.log "2 got val #{v}"
  }
]

Session.set('questionNumber', 0)
Session.set('map', null)
Session.set('status', "Loading map...")
Session.set('filters', {
  lowmarker: 25
  middlemarker: 65
})

Template.description.filterdesc = ->
  filters = Session.get('filters')
  return "middle class is $#{filters.lowmarker}k-$#{filters.middlemarker}k"

Template.filterpopup.question = -> questions[Session.get('questionNumber')].question
Template.filterpopup.questiondesc = -> questions[Session.get('questionNumber')].questiondesc
Template.filterpopup.questiondefault = -> questions[Session.get('questionNumber')].questiondefault
Template.filterpopup.nextbutton = "Okay"

Template.progresspopup.message = -> Session.get('status')

Template.map.buttonstep = "Start"
#console.log "buttonstep = #{Session.get('questionNumber')}"
#return "step on me"
#step = Session.get('questionNumber')
#return "Start" if step == 0
#return "Step #{step}" if step > 0

Meteor.startup ->
  # TODO I can't use templates and the modal stuff b/c the template completely rerenders my template for the popup thereby
  # losing some of the already set classes applied to the modes.
  $('#classesdialog').fadeOut()
  $('#optionsbutton').click -> $('#classesdialog').fadeIn()
  $('#changebutton').click ->
    $('#classesdialog').fadeOut()
    questions[Session.get('questionNumber')].questionhandler($('#filterpopupval').val())
    Session.set('questionNumber',Session.get('questionNumber')+1)
    console.log "q = #{Session.get('questionNumber')}"

  makeMap ->
    new VisibleOnMovementItem('#optionsbutton',3000)
    paintMap()
# vim: set et,sw=2,ts=2:
