class DepartmentsController < ApplicationController
  def create
    @department = Department.create department_params
    head :ok
  end

  def update
    @department = Department.find params[:id]
    @department.update_attributes department_params
    head :ok
  end

  def destroy
    @department = Department.find params[:id]
    @department.destroy
    head :ok
  end

  private

  def department_params
    params.require(:department).permit!
  end
end