require 'spec_helper'
require 'active_model'
require 'gamma_ray/active_record'
require 'gamma_ray/active_record/model'
require 'gamma_ray/client'
require 'gamma_ray/request'
require 'gamma_ray/response'
require 'json'

describe GammaRay::ActiveRecord::Model do
  describe '#filter_gamma_ray_properties' do
    let(:test_class) do
      # Make a fake ActiveRecord class
      Class.new do
        extend ActiveModel::Callbacks
        define_model_callbacks :create, :update, :destroy, :commit, :rollback
        include GammaRay::ActiveRecord::Model
        has_autolog
      end
    end

    let(:input) { { foo1: 'bar1', foo2: 'bar2', foo3: 'bar3' } }

    it 'return same input if no opts' do
      expect(test_class.new.send(:filter_gamma_ray_properties, input)).to eq input
    end
  end

  describe '#flush_gamma_ray_event' do
    let(:client) { double("Aws::Kinesis::Client") }

    before(:each) do
      allow(Aws::Kinesis::Client).to receive(:new) { client }
    end

    let(:test_class) do
      # Make a fake ActiveRecord class
      Class.new do
        extend ActiveModel::Callbacks
        define_model_callbacks :create, :update, :destroy, :commit, :rollback
        include GammaRay::ActiveRecord::Model
        has_autolog
        GammaRay::ActiveRecord.configuration.stream_name = "StreamName"
        GammaRay::ActiveRecord.configuration.bucket_name = "bucketname"
      end
    end

    let!(:input) { {event: "this event", stream_name: "other parameter"} }
    
    it 'correctly never sends gamma_ray_event to kinesis if no gamma_ray_event' do
      expect(GammaRay::Request).not_to receive(:post)
      test_class.new.send(:flush_gamma_ray_event)
    end

    it 'sends the correct gamma_ray_event to be put into kinesis' do
      expect_any_instance_of(GammaRay::Request).to receive(:post).with("StreamName",input)
      test_class.gamma_ray_event = input
      test_class.new.send(:flush_gamma_ray_event)
    end

    it 'doesn\'t add a gamma_ray_event to the kinesis queue' do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).not_to receive(:put_record) { response }
      test_class.new.send(:flush_gamma_ray_event)
    end

    it 'adds the new gamma_ray_event to the kinesis queue' do
      response = ::Aws::Kinesis::Types::PutRecordOutput.new
      expect(client).to receive(:put_record) { response }
      test_class.gamma_ray_event = input
      test_class.new.send(:flush_gamma_ray_event)
    end
  end

  describe '#local_mutated_versions' do
    shared_examples 'an immutable version' do
      before do
        # mock what immutability means - creating new resources in place of updating existing
        5.times do
          test_class.new(new_instance_params).save
        end
      end

      it 'works' do
        expect(test_class.last.send(:local_mutated_versions).count).to eq 5
      end
    end

    let(:uuid) { SecureRandom.uuid }

    describe 'with a "created_by" association' do
      let(:test_class) { ImmutableModelWithCreator }
      let(:new_instance_params) { { uuid: uuid, created_by: User.new } }

      it_behaves_like 'an immutable version'
    end

    describe 'with no "created_by" association' do
      let(:test_class) { ImmutableModelWithNoCreator }
      let(:new_instance_params) { { uuid: uuid } }

      it_behaves_like 'an immutable version'
    end
  end
end
