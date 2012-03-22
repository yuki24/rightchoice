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
  end
end
