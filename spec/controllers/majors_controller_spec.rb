require 'spec_helper'

RSpec.describe MajorsController, type: :controller do
  let(:client) { double("Aws::Kinesis::Client") }
  before(:each) do
    allow(Aws::Kinesis::Client).to receive(:new) { client }
    allow(client).to receive(:put_record) { response }
    GammaRay::ActiveRecord.configuration.stream_name = "StreamName"
    GammaRay::ActiveRecord.configuration.bucket_name = "bucketname"
    GammaRay::ActiveRecord.configuration.turn_on = false
    Department.create(name: "College")
    GammaRay::ActiveRecord.configuration.turn_on = true
  end

  after(:all) do
    GammaRay::ActiveRecord.configuration.turn_on = false
  end

  let!(:major_params) { { major: {department_id: 1, name: "Computer Science"} } }
  let!(:version_params) { {
                            "type" => "major", 
                            "version" => 1, 
                            "department_id" => 1, 
                            "name" => "Computer Science", 
                            "occurred_at" => "10:00"
                        } }
  let!(:version2_params) { 
                          [{"type" => "major", 
                            "version" => 1, 
                            "department_id" => 1, 
                            "name" => "Computer Science", 
                            "occurred_at" => "10:00"},
                           {"type" => "major", 
                            "version" => 2, 
                            "major_id" => 1, 
                            "name" => "Comp Sci", 
                            "occurred_at" => "11:00"}] 
                          }
  let!(:version3_params) { 
                          [{"type" => "major", 
                            "version" => 1, 
                            "department_id" => 1, 
                            "name" => "Computer Science", 
                            "occurred_at" => "10:00"},
                           {"type" => "major", 
                            "version" => 3, 
                            "occurred_at" => "12:00"}] 
                          }

  describe "#create" do
    it "stores the proper information in gamma_ray_versions" do 
      post(:create, params_wrapper(major_params))
      major = assigns(:major)
      expect(major).to receive(:main_versions) { [version_params] }
      expect(major.gamma_ray_versions.length).to eq(1)
    end
  end

  describe "#update" do
    it "stores the proper update information in gamma_ray_versions" do
      m = Major.create(department_id: 1, name: "Computer Science")
      expect(m).to receive(:main_versions) { [version_params] }
      expect(m.gamma_ray_versions.length).to eq(1)
      put(:update, params_wrapper(id: m.id, major: {name: "Comp Sci"}))
      major = assigns(:major)
      expect(major).to receive(:main_versions) { [version2_params] }
      expect(major.gamma_ray_versions.length).to eq(2)
    end
  end

  describe "#destroy" do
    it "stores the proper delete information in gamma_ray_versions" do
      m = Major.create(department_id: 1, name: "Computer Science")
      expect(m).to receive(:main_versions) { [version_params] }
      expect(m.gamma_ray_versions.length).to eq(1)
      delete(:destroy, params_wrapper(id: m.id))
      major = assigns(:major)
      expect(major).to receive(:main_versions) { [version3_params] }
      expect(major.gamma_ray_versions.length).to eq(2)
    end
  end
end