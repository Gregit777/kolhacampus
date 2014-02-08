class KolHacampus.ProgramsIndexView extends KolHacampus.ScrollableView

  onProgramClick: (program, el, ev, view) ->
    tag = ev.target.tagName.toLowerCase()
    if tag is 'img'
      @showProgramDetails(program)
    else
      route = "/programs/#{program.get('id')}/tracklists"
      Batman.redirect route

  showProgramDetails: (program) ->
    layout = KolHacampus.get('layout')
    layout.setKeypath 'program', program
    layout.fire 'changePlayerSubview', 'program'
    layout.fire 'togglePlayerContainer'