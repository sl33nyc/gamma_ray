class StudentsController < ApplicationController
  def create
    @student = Student.create student_params
    head :ok
  end

  def update
    @student = Student.find params[:id]
    @student.update_attributes student_params
    head :ok
  end

  def destroy
    @student = Student.find params[:id]
    @student.destroy
    head :ok
  end

  private

  def student_params
    params.require(:student).permit!
  end
end