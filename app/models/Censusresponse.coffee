Spine = require('spine')

class Censusresponse extends Spine.Model
  @configure 'Censusresponse', 'puma','sex','age','school','income','incomecount'
  
module.exports = Censusresponse
