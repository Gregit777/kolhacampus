class Api::Mobile::V1::ProgramsController < ApiController

  def index
    @programs = Program.active.order(name: :asc)
  end

  def show
    @program = Program.find params[:id]
  end

end
