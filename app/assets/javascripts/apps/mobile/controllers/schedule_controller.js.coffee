class KolHacampus.ScheduleController extends KolHacampus.ApplicationController
  routingKey: 'schedule'

  index: ->
    programs = KolHacampus.Program.where {active: true}, {name: 'asc'}
    if programs.get('length') < 50
      KolHacampus.Program.load =>
        @renderSchedule()
      @render(false)
    else
      @renderSchedule()

  renderSchedule: ->
    schedule = KolHacampus.get('schedule')
    now = schedule.getCurrentTime()
    @set 'today', now.getDay()
    @set 'weekdays', schedule.byWeekday()
    @render()