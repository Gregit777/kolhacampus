class KolHacampus.ProgramsController extends KolHacampus.ApplicationController
  routingKey: 'programs'

  index: ->
    programs = KolHacampus.Program.where {has_tracklists: true}, {name: 'asc'}
    if programs.get('length') < 50
      KolHacampus.Program.load (err, programs) =>
        @renderPrograms(programs)
      @render(false)
    else
      @renderPrograms(programs)

  renderPrograms: (programs) ->
    @set 'programs', programs
    @render()
    KolHacampus.get('layout').propagateToSubviews 'viewDidAppear'