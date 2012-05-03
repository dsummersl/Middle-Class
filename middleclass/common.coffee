# Given an integer v and an array of integers, find the smallest integer in the
# array that is larger than v.
round = (v,markers) ->
  bucket = null
  previous = markers[0]
  for a in markers[1..] when bucket == null
    halfmark = previous + (a-previous)/2
    bucket = previous if v >= previous and v < halfmark
    bucket = a if v <= a and v >= halfmark
    previous = a
  return bucket


module?.exports =
  round: round
