require 'spec_helper'

RSpec.describe StudentsController, type: :controller do
  let(:client) { double("Aws::Kinesis::Client") }
  before(:each) do
    allow(Aws::Kinesis::Client).to receive(:new) { client }
    allow(client).to receive(:put_record) { response }
    GammaRay::ActiveRecord.configuration.stream_name = "StreamName"
    GammaRay::ActiveRecord.configuration.bucket_name = "bucketname"
    GammaRay::ActiveRecord.configuration.turn_on = false
    Department.create(name: "College")
    Major.create(department_id: 1, name: "Computer Science")
    GammaRay::ActiveRecord.configuration.turn_on = true
  end

  after(:all) do
    GammaRay::ActiveRecord.configuration.turn_on = false
  end

  let!(:student_params) { { student: {major_id: 1, name: "Steven", grade: 5} } }
  let!(:version_params) { {
                            "type" => "student", 
                            "version" => 1, 
                            "major_id" => 1, 
                            "name" => "Steven", 
                            "grade" => 5,
                            "occurred_at" => "10:00"
                        } }
  let!(:major_params) { {
                            "type" => "major", 
                            "version" => 1,
                            "name" => "Economics",
                            "department_id" => 1, 
                            "occurred_at" => "12:00"
                         } }

  describe "#create" do
    it "related_objects works as expected" do 
      post(:create, params_wrapper(student_params))
      student = assigns(:student)
      expect_any_instance_of(Major).to receive(:main_versions) { [major_params] }
      expect(student).to receive(:main_versions) { [version_params] }
      expect(student.gamma_ray_versions.length).to eq(2)
    end
  end
end