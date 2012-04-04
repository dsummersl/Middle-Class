require = window.require if window?

describe 'About', ->
  About = require('controllers/about')
  
  it 'can noop', ->
		expect(5).toEqual(3)
    
