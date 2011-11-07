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
      its(:alternatives) { should == ["foo", "bar"] }
      its(:choice) { should == "foo" }
    end

    context 'with invalid option params' do
      subject { @invalid_variation }
      its(:alternatives) { should == ["foo", "bar"] }
      its(:choice) { should_not == "" }
    end
  end

  describe "listing" do
    before :all do
      @v1 = Rightchoice::Variation.new(:name1, "foo", "bar")
      @v2 = Rightchoice::Variation.new(:name2, "foo", "bar")
      @v3 = Rightchoice::Variation.new(:name3, "foo", "bar")
      @v4 = Rightchoice::Variation.new(:name4, "foo", "bar")
    end

    it "should set v2 as a child to v1" do
      @v1.root!
      @v1.child = @v2
      @v2.child = @v3
      @v3.child = @v4
      @v4.end!

      @v1.root?.should == true
      @v1.child.should == @v2
      @v2.parent.should == @v1
      @v2.child.should == @v3
      @v3.parent.should == @v2
      @v2.child.should == @v3
      @v3.parent.should == @v2
      @v4.end?.should == true
    end
  end
end
