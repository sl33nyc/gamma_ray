require 'spec_helper'

RSpec.describe DepartmentsController, type: :controller do
  let(:client) { double("Aws::Kinesis::Client") }
  before(:each) do
    allow(Aws::Kinesis::Client).to receive(:new) { client }
    allow(client).to receive(:put_record) { response }
    GammaRay::ActiveRecord.configuration.stream_name = "StreamName"
    GammaRay::ActiveRecord.configuration.bucket_name = "bucketname"
    GammaRay::ActiveRecord.configuration.turn_on = false
    GammaRay::ActiveRecord.configuration.turn_on = true
  end

  after(:all) do
    GammaRay::ActiveRecord.configuration.turn_on = false
  end

  let!(:department_params) { { department: {name: "Engineering"} } }
  let!(:version_params) { {
                            "type" => "department", 
                            "version" => 1,  
                            "name" => "Engineering", 
                            "occurred_at" => "10:00"
                        } }
  let!(:version2_params) { 
                          [{"type" => "department", 
                            "version" => 1,  
                            "name" => "Engineering", 
                            "occurred_at" => "10:00"},
                           {"type" => "department", 
                            "version" => 2, 
                            "name" => "SEAS", 
                            "occurred_at" => "11:00"}] 
                          }
  let!(:version3_params) { 
                          [{"type" => "department", 
                            "version" => 1,  
                            "name" => "Engineering", 
                            "occurred_at" => "10:00"},
                           {"type" => "department", 
                            "version" => 3, 
                            "occurred_at" => "12:00"}] 
                          }

  describe "#create" do
    it "stores the proper information in gamma_ray_versions" do 
      post(:create, params_wrapper(department_params))
      department = assigns(:department)
      expect(department).to receive(:main_versions) { [version_params] }
      expect(department.gamma_ray_versions.length).to eq(1)
    end
  end

  describe "#update" do
    it "stores the proper update information in gamma_ray_versions" do
      d = Department.create(name: "Engineering")
      expect(d).to receive(:main_versions) { [version_params] }
      expect(d.gamma_ray_versions.length).to eq(1)
      put(:update, params_wrapper(id: d.id, department: {name: "SEAS"}))
      department = assigns(:department)
      expect(department).to receive(:main_versions) { [version2_params] }
      expect(department.gamma_ray_versions.length).to eq(2)
    end
  end

  describe "#destroy" do
    it "stores the proper delete information in gamma_ray_versions" do
      d = Department.create(name: "Engineering")
      expect(d).to receive(:main_versions) { [version_params] }
      expect(d.gamma_ray_versions.length).to eq(1)
      delete(:destroy, params_wrapper(id: d.id))
      department = assigns(:department)
      expect(department).to receive(:main_versions) { [version3_params] }
      expect(department.gamma_ray_versions.length).to eq(2)
    end
  end
end