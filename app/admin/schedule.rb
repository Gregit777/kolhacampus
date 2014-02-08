ActiveAdmin.register Schedule do

  menu parent: 'Programs & Schedules'

  index do
    column :title
    column :start_date
    column :end_date
    default_actions
  end

  form :partial => 'form'

  controller do

    def new
      @programs = Program.active.select('id, name').collect{|prog| [prog.name, prog.id]}
      super
    end

    def edit
      @programs = Program.active.select('id, name').collect{|prog| [prog.name, prog.id]}
      super
    end

    def update
      if params[:commit].downcase == 'duplicate'
        schedule = Schedule.find params[:id]
        unless schedule.nil?
          new_schedule = schedule.dup
          new_schedule.save
          flash.notice = 'Duplicated Schedule'
          redirect_to edit_admin_schedule_url(new_schedule)
        else
          redirect_to admin_schedules_url
        end
      else
        super
      end
    end
  end
end
