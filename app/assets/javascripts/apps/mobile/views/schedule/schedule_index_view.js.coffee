class KolHacampus.ScheduleIndexView extends Batman.View

  changeDay: (el, ev) ->
    node = @get('node')
    tgt = ev.target
    @setup() if @index is undefined
    @days[@index].classList.remove('active')
    @programs[@index].classList.remove('active')
    @index = parseInt(tgt.getAttribute('data-index'), 10)
    @days[@index].classList.add('active')
    @programs[@index].classList.add('active')
    @container.scrollTop = 0

  setup: ->
    node = @get('node')
    @container = node.querySelector('.scroll-container')
    @days = node.querySelectorAll('.weekday')
    @programs = node.querySelectorAll('.daily-programs')
    @index = parseInt(node.querySelector('.active[data-index]').getAttribute('data-index'), 10)
