require 'spec_helper'

describe Teacher, type: :model do
  describe "creates, updates and destroys of teachers should get writen to kinesis queue" do
    let(:client) { double("Aws::Kinesis::Client") }

    before(:each) do
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

  	let!(:teacher_params) { { department_id: 1, name: "Richard", kind: "real", tenured: 1 } }

    let!(:teacher_params2) { { department_id: 2, name: "Richie" } }
    
    it "puts the new teacher on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).once { response }
      my_teacher = Teacher.create(teacher_params)
    end

    it "puts the updated teacher on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).twice { response }
      my_teacher = Teacher.create(teacher_params)
      my_teacher.update(teacher_params2)
    end

    it "puts the new teacher on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).thrice { response }
      my_teacher = Teacher.create(teacher_params)
      my_teacher.update(teacher_params2)
      my_teacher.destroy
    end
   
    it "doesn't put teacher on the kinesis queue if no record" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to_not receive(:put_record) { response }
    end
  end
end