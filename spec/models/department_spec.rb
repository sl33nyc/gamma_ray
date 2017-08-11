require 'spec_helper'

describe Department, type: :model do
  describe "creates, updates and destroys of departments should get writen to kinesis queue" do
    let(:client) { double("Aws::Kinesis::Client") }

    before(:each) do
      GammaRay::ActiveRecord.configuration.turn_on = true
      GammaRay::ActiveRecord.configuration.stream_name = "StreamName"
      GammaRay::ActiveRecord.configuration.bucket_name = "bucket name"
      allow(Aws::Kinesis::Client).to receive(:new) { client }
    end
    
    after(:all) do
      GammaRay::ActiveRecord.configuration.turn_on = false
    end

    let!(:department_params) { { name: "College" } }

    let!(:department_params2) { { name: "Barnard" } }
    
    it "puts the new department on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).once { response }
      my_department = Department.create(department_params)
    end

    it "puts the updated department on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).twice { response }
      my_department = Department.create(department_params)
      my_department.update(department_params2)
    end

    it "puts the deleted department on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).thrice { response }
      my_department = Department.create(department_params)
      my_department.update(department_params2)
      my_department.destroy
    end
   
    it "doesn't put department on the kinesis queue if no record" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to_not receive(:put_record) { response }
    end
  end
end