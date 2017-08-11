class TeachersController < ApplicationController
  def create
    @teacher = Teacher.create teacher_params
    head :ok
  end

  def update
    @teacher = Teacher.find params[:id]
    @teacher.update_attributes teacher_params
    head :ok
  end

  def destroy
    @teacher = Teacher.find params[:id]
    @teacher.destroy
    head :ok
  end

  private

  def teacher_params
    params.require(:teacher).permit!
  end
end