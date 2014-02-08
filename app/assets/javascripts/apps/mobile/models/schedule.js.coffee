class KolHacampus.Schedule extends KolHacampus.BaseModel
  @resourceName: 'schedule'
  @storageKey: 'schedule'

  @persist Batman.MemoryStorage

  @encode 'description', 'configuration', 'tz_offset'

  # Resolve program start time based on given time stamp
  # @param {Long} time timestamp to resolve start time by
  # @return {Date} program start time
  resolveStartTime: (time) ->
    prev_program_id = @getProgramIdInTime(time)
    prog_id = @getProgramIdInTime(time)
    while prev_program_id is prog_id
      time = new Date(time.getTime() - (3600 * 1000))
      hour = time.getHours()
      wday = time.getDay() + 1
      prev_program_id = parseInt(@get('configuration')[hour][wday], 10)

    t = new Date(time.getTime() + 3600 * 1000)
    new Date(t.getFullYear(), t.getMonth(), t.getDate(), t.getHours())

  # Get current program's start time
  # @return {Date} program start time
  getCurrentTime: ->
    utc = new Date().to_utc()
    now = new Date(utc.getTime() + @get('tz_offset') * 1000)
    @resolveStartTime(now)

  # Get current program ID
  currentProgramId: ->
    time = @getCurrentTime()
    @getProgramIdInTime(time)

  # Get the ID of a program scheduled for a given time
  # @param {Long} time timestamp to resolve start time by
  getProgramIdInTime: (time) ->
    hour = time.getHours()
    wday = time.getDay() + 1
    parseInt(@get('configuration')[hour][wday], 10)

  # Get ID and start time of previous program in relation to given start time
  # @param {Long} time timestamp to resolve current program by
  # @return {Array[program ID, start time]} previous program ID and its start time
  prev: (time)->
    prev_program_id = @getProgramIdInTime(time)
    prog_id = @getProgramIdInTime(time)
    while prev_program_id == prog_id
      utc = new Date(time.getTime()).to_utc()
      time = new Date(utc.getTime() + (@get('tz_offset') - 3600) * 1000)
      hour = time.getHours()
      wday = time.getDay() + 1
      prev_program_id = parseInt(@get('configuration')[hour][wday], 10)

    [prev_program_id, time]

  # Get ID and start time of next program in relation to given start time
  # @param {Long} time timestamp to resolve current program by
  # @return {Array[program ID, start time]} next program ID and its start time
  next: (time)->
    next_program_id = @getProgramIdInTime(time)
    prog_id = @getProgramIdInTime(time)
    while next_program_id == prog_id
      utc = new Date(time.getTime()).to_utc()
      time = new Date(utc.getTime() + (data.tz_offset + 3600) * 1000)
      hour = time.getHours()
      wday = time.getDay() + 1
      next_program_id = parseInt(@get('configuration')[hour][wday], 10);

    [next_program_id, time]

  byWeekday: ->
    config = @get('configuration')
    weekday_config = {}
    result = new Batman.Set
    for hour, days of config
      for day, program_id of days
        weekday_config[day] or= {}
        weekday_config[day][hour] = parseInt(program_id, 10)

    for day, hours of weekday_config
      programs = new Batman.Set
      for hour, program_id of hours
        prog = KolHacampus.Program.get('loaded.indexedByUnique.id').get(program_id)
        program = new Batman.Object
          name: prog.get('name')
          hour: moment().hour(hour).format('HH:00')

        programs.add program

      obj = new Batman.Object
        day: moment().day(day - 1).format('ddd')
        programs: programs

      result.add obj

    result