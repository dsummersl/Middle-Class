# Given an integer v and an array of integers, round to the nearest value listed in the 'markers' array
round = (v,markers) ->
  bucket = null
  previous = markers[0]
  for a in markers[1..] when bucket == null
    halfmark = previous + (a-previous)/2
    bucket = previous if v >= previous and v < halfmark
    bucket = a if v <= a and v >= halfmark
    previous = a
  return markers[0] if bucket == null
  return bucket

# Breakout finds the first marker in the array markers thats greater than 'v'
breakout = (v,markers) ->
  bucket = 0
  bucket = a for a in markers when a >= v and bucket == 0
  return bucket

module?.exports =
  round: round
  breakout: breakout
