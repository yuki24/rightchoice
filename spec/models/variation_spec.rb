require 'spec_helper'
require 'rightchoice/models/variation'

describe Rightchoice::Variation do

  describe "initialization" do
    before :all do
      @variation = Rightchoice::Variation.new(:test_name, "foo", "bar")
      @valid_variation = Rightchoice::Variation.new(:test_name, "foo", "bar", :choice => "foo")
      @invalid_variation = Rightchoice::Variation.new(:test_name, "foo", "bar", :choice => "")
    end

    context 'default params' do
      subject { @variation }
      its(:name) { should == "test_name" }
      its(:alternatives) { should == ["foo", "bar"] }
    end

    context 'with option params' do
      subject { @valid_variation }
      its(:name) { should == "test_name" }
      its(:choice) { should == "foo" }
    end

    context 'with invalid option params' do
      subject { @invalid_variation }
      its(:choice) { should_not == "" }
    end
  end
end
