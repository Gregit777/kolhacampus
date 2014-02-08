Date.prototype.to_utc = ->
  now_utc = new Date(@getUTCFullYear(), @getUTCMonth(), @getUTCDate(),  @getUTCHours(), @getUTCMinutes(), @getUTCSeconds())

Array.prototype.in_groups_of = (n) ->
  r = []
  for item, index in @
    if index % n is 0
      a = []
      r.push(a)
    a.push(item) if a
  r