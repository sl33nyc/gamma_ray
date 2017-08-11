require 'spec_helper'

RSpec.describe TeachersController, type: :controller do
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

  let!(:teacher_params) { { teacher: {department_id: 1, name: "Alexander", kind: "real", tenured: 0} } }
  let!(:author_params) { {"name" => "Gabriel Kramer-Garcia", "id" => 123} }
  let!(:version_params) { {
                            "type" => "teacher", 
                            "version" => 1, 
                            "department_id" => 1, 
                            "name" => "Alexander", 
                            "kind" => "real",
                            "tenured" => 0,
                            "created_by" => author_params,
                            "occurred_at" => "10:00"
                        } }

  describe "#create" do
    it "recording the author works as expected" do 
      post(:create, params_wrapper(teacher_params))
      teacher = assigns(:teacher)
      expect(teacher).to receive(:main_versions) { [version_params] }
      expect(teacher.gamma_ray_versions.last["created_by"]).to eq(author_params)
    end

    let!(:my_summary) { double("Aws::S3::ObjectSummary") }
    let!(:my_output) { double("Aws::S3::Types::GetObjectOutput") }
    let!(:my_body) { double("IO") }

    it "main_versions works as expected" do 
      post(:create, params_wrapper(teacher_params))
      teacher = assigns(:teacher)
      expect_any_instance_of(Aws::S3::Bucket).to receive(:objects) { [my_summary] }
      expect(my_summary).to receive(:get) { my_output }
      expect(my_output).to receive(:body) { my_body }
      expect(my_body).to receive(:read) { ["hello"].to_json }
      expect(teacher.gamma_ray_versions.last).to eq("hello")
    end
  end
end