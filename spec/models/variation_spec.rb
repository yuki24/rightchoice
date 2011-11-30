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

    describe "#find_or_create" do
      it "should create a new variation object" do
        Rightchoice::Variation.find_or_create(:test_name, "foo", "bar")
        Rightchoice::Variation.redis.hexists("all_tests", "test_name").should be_true

        expect {
          mv = Rightchoice::Variation.find_or_create(:test_name)
        }.to change{ Rightchoice::Variation.redis.hlen("all_tests") }.by(0)
        Rightchoice::Variation.redis.hget("all_tests", "test_name").should ==
          ["foo", "bar"].to_json
      end

      it "should create a new multi_variations object" do
        Rightchoice::Variation.redis.hexists("all_tests", "new_test").should be_false
        Rightchoice::Variation.find_or_create(:new_test, "foo", "bar")
        Rightchoice::Variation.redis.hexists("all_tests", "new_test").should be_true
        Rightchoice::Variation.redis.hget("all_tests", "new_test").should ==
          ["foo", "bar"].to_json
      end
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
