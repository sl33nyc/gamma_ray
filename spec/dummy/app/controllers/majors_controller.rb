class MajorsController < ApplicationController
  def create
    @major = Major.create major_params
    head :ok
  end

  def update
    @major = Major.find params[:id]
    @major.update_attributes major_params
    head :ok
  end

  def destroy
    @major = Major.find params[:id]
    @major.destroy
    head :ok
  end

  private

  def major_params
    params.require(:major).permit!
  end
end