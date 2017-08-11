require 'spec_helper'

describe Student, type: :model do
  describe "creates, updates and destroys of students should get writen to kinesis queue" do
    let(:client) { double("Aws::Kinesis::Client") }

    before(:each) do
      GammaRay::ActiveRecord.configuration.stream_name = "StreamName"
      GammaRay::ActiveRecord.configuration.bucket_name = "bucket name"
      allow(Aws::Kinesis::Client).to receive(:new) { client }
      GammaRay::ActiveRecord.configuration.turn_on = false
      Department.create(name: "College")
      Major.create(department_id: 1, name: "Computer Science")
      GammaRay::ActiveRecord.configuration.turn_on = true
    end
    
    after(:all) do
      GammaRay::ActiveRecord.configuration.turn_on = false
    end

  	let!(:student_params) { { major_id: 1, name: "Steven", grade: 5 } }

    let!(:student_params2) { { major_id: 2 } }
    
    it "puts the new student on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).once { response }
      my_student = Student.create(student_params)
    end

    it "puts the updated student on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).twice { response }
      my_student = Student.create(student_params)
      my_student.update(student_params2)
    end

    it "puts the deleted student on the kinesis queue" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record).thrice { response }
      my_student = Student.create(student_params)
      my_student.update(student_params2)
      my_student.destroy
    end
    
    it "doesn't put student on the kinesis queue if no record" do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to_not receive(:put_record) { response }
    end
  end
end