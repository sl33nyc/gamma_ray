require 'spec_helper'

describe Major, type: :model do
  describe "creates, updates and destroys of majors should get writen to kinesis queue" do
    let(:client) { double("Aws::Kinesis::Client") }

    before(:each) do
      GammaRay::ActiveRecord.configuration.turn_on = true
      GammaRay::ActiveRecord.configuration.stream_name = "StreamName"
      GammaRay::ActiveRecord.configuration.bucket_name = "bucket name"
      allow(Aws::Kinesis::Client).to receive(:new) { client }
      GammaRay::ActiveRecord.configuration.turn_on = false
      Department.create(name: "College")
      GammaRay::ActiveRecord.configuration.turn_on = true
    end
    
    after(:all) do
      GammaRay::ActiveRecord.configuration.turn_on = false
    end

    let!(:major_params) { { department_id: 1, name: "Computer Science" } }

    let!(:major_params2) { { name: "Computer Engineering" } }

    it "puts the created major on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).once { response }
      my_major = Major.create(major_params)
    end

    it "puts the updated major on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).twice { response }
      my_major = Major.create(major_params)
      my_major.update(major_params2)
    end

    it "puts the deleted major on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).thrice { response }
      my_major = Major.create(major_params)
      my_major.update(major_params2)
      my_major.destroy
    end
   
    it "doesn't put major on the kinesis queue if no record" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to_not receive(:put_record) { response }
    end
  end
end