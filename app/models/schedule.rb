class Schedule < ActiveRecord::Base

  # Serializations
  serialize :configuration

  # Callbacks
  after_initialize :after_initialize

  def self.active
    where("now() between start_date and end_date or is_default = 1").order("is_default asc").limit(1).first
  end

  def programs
    ids = configuration.values.collect {|hours| hours.values }.flatten.uniq
    r = Program.where("id in (#{ids.join(',')})").select('id, name')
    o = {}
    r.each do |program|
      o[program.id.to_s] ||= program
    end
    c = {}
    configuration.each do |hour, weekdays|
      weekdays.each do |weekday, program_id|
        h = hour.to_s
        prog = o[program_id]
        users = prog.nil? ? {} : prog.users.map{|user| user.attributes.keep_if{|k,v| [:id, :first_name, :last_name].include?(k.to_sym)}}
        c[h] ||= {}
        c[h][weekday.to_s] = prog.nil? ? {} : prog.attributes.merge({:users => users})
      end
    end
    c
  end

  def resolved_start_time(time)
    hour = time.hour
    wday = time.wday + 1
    program_id = configuration[hour.to_s][wday.to_s]
    prev_program_id = program_id
    while program_id == prev_program_id
      time -= 1.hour
      hour = time.hour
      wday = time.wday + 1
      prev_program_id = configuration[hour.to_s][wday.to_s]
    end
    time += 1.hour
    Time.local(time.year, time.month, time.day, time.hour, 0, 0)
  end

  def current_program
    time = resolved_start_time(Time.now)
    program_id = configuration[time.hour.to_s][(time.wday + 1).to_s]
    Program.find program_id
  end

  def previous_program(time)
    hour = time.hour
    wday = time.wday + 1
    program_id = configuration[hour.to_s][wday.to_s]
    prev_program_id = program_id
    while program_id == prev_program_id
      time -= 1.hour
      hour = time.hour
      wday = time.wday + 1
      prev_program_id = configuration[hour.to_s][wday.to_s]
    end
    [prev_program_id, time]
  end

  private

  def after_initialize
    self.start_date = self.end_date = Time.now if new_record?
  end

end
