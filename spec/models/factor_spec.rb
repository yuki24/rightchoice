require 'spec_helper'
require 'rightchoice/models/factor'

describe Rightchoice::Factor do
  describe "initialization" do
    let(:factor) { Rightchoice::Factor.new(:test_name, "foo", "bar") }
    let(:valid_factor) { Rightchoice::Factor.new(:test_name, "foo", "bar", :choice => "foo") }
    let(:invalid_factor) { Rightchoice::Factor.new(:test_name, "foo", "bar", :choice => "") }

    context 'default params' do
      subject { factor }
      its(:name) { should == "test_name" }
      its(:alternatives) { should == ["foo", "bar"] }
    end

    context 'with option params' do
      subject { valid_factor }
      its(:name) { should == "test_name" }
      its(:alternatives) { should == ["foo", "bar"] }
      its(:choice) { should == "foo" }
    end

    context 'with invalid option params' do
      subject { invalid_factor }
      its(:alternatives) { should == ["foo", "bar"] }
      its(:choice) { should_not == "" }
    end

=begin
    describe "#find_or_create" do
      it "should create a new variation object" do
        Rightchoice::Factor.find_or_create(:test_name, "foo", "bar")
        Rightchoice::Factor.redis.hexists("all_tests", "test_name").should be_true

        expect {
          mv = Rightchoice::Factor.find_or_create(:test_name)
        }.to change{ Rightchoice::Factor.redis.hlen("all_tests") }.by(0)
        Rightchoice::Factor.redis.hget("all_tests", "test_name").should ==
          ["foo", "bar"].to_json
      end

      it "should create a new multi_variations object" do
        Rightchoice::Factor.redis.hexists("all_tests", "new_test").should be_false
        Rightchoice::Factor.find_or_create(:new_test, "foo", "bar")
        Rightchoice::Factor.redis.hexists("all_tests", "new_test").should be_true
        Rightchoice::Factor.redis.hget("all_tests", "new_test").should ==
          ["foo", "bar"].to_json
      end
    end
=end
  end
end
