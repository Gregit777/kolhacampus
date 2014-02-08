Batman.mixin Batman.Filters,
  formatDate: (date) ->
    moment(date).format("DD MMM YYYY")

  withIndex: (input) ->
    return input unless input
    index = -1
    input.forEach (data) -> data.set("viewIndex", index += 1)
    input

  gt: (input, value) -> input > value