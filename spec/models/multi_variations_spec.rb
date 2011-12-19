require 'spec_helper'
require 'rightchoice/models/multi_variations'

describe Rightchoice::MultiVariations do
  before(:all) { Rightchoice.redis.flushall }

  before :all do
    @multi_variation = Rightchoice::MultiVariations.find_or_create(:test_name)
  end

  describe "initialization" do
    context 'default params' do
      subject { @multi_variation }
      its(:name) { should == "test_name" }
    end

    it "should not have any variations" do
      @multi_variation.variations.count.should be 0
    end

    describe "#find_or_create" do
      it "should create a new multi_variations object" do
        Rightchoice::MultiVariations.find_or_create(:test_name)
        Rightchoice::MultiVariations.redis.hexists("all_mvtests", "test_name").should be_true

        expect {
          mv = Rightchoice::MultiVariations.find_or_create(:test_name)
        }.to change{ Rightchoice::MultiVariations.redis.hlen("all_mvtests") }.by(0)
      end

      it "should create a new multi_variations object" do
        Rightchoice::MultiVariations.redis.hexists("all_mvtests", "new_testname").should be_false
        Rightchoice::MultiVariations.find_or_create("new_testname")
        Rightchoice::MultiVariations.redis.hexists("all_mvtests", "new_testname").should be_true
      end
    end
  end

  describe "addition of variates and selection" do
    before do
      Rightchoice::MultiVariations.find_or_create(:test_name)
      @variation1 = Rightchoice::Variation.find_or_create(:variation_name1, "foo", "bar", :choice => "foo")
      @variation2 = Rightchoice::Variation.find_or_create(:variation_name2, "hoge", "fuga", :choice => "hoge")
    end

    it "should have 1 variation" do
      expect {
        @multi_variation.variations << @variation1
        @multi_variation.variations.count.should be 1
        @multi_variation.variations.find(:variation_name1).should == @variation1
        @multi_variation.variations.find(:variation_name2).should be_nil
      }.to change {
        Rightchoice::MultiVariations.redis.hget("all_mvtests", "test_name")
      }.from([].to_json).to(["variation_name1"].to_json)
    end

    it "should have 2 variations" do
      expect {
        @multi_variation.variations << @variation2
        @multi_variation.variations.count.should be 2
        @multi_variation.variations.find(:variation_name2).should == @variation2
      }.to change {
        Rightchoice::MultiVariations.redis.hget("all_mvtests", "test_name")
      }.from(["variation_name1"].to_json).to(["variation_name1", "variation_name2"].to_json)
    end
  end

  context "getters" do
    subject { @multi_variation }
    its(:selections) { should == {"variation_name1" => "foo", "variation_name2" => "hoge"} }
    its(:redis_key) { should == "test_name.variation_name1:foo.variation_name2:hoge" }
  end

  context "statistical numbers" do
    before :all do
      1000.times { @multi_variation.participate! }
      100.times { @multi_variation.vote! }
    end

    subject { @multi_variation }
    its(:expectation) { should == 100 }
    its(:dispersion) { should == 90 }
    its(:confident?) { should be_true }
  end

  describe 'availability' do
    it "should save a multivariate test" do
      @multi_variation.participate!
      Rightchoice.redis.del(@multi_variation.redis_key)

      @multi_variation.participate!
      Rightchoice.redis.hget(@multi_variation.redis_key, "participants_count").should == "1"
      Rightchoice.redis.hget(@multi_variation.redis_key, "votes_count").should == "0"
    end

    context "for available variations" do
      subject { @multi_variation }
      its(:available?) { should be_true }
    end

    context "for unavailable variations" do
      before { @multi_variation.disable! }

      subject { @multi_variation }
      its(:available?) { should be_false }
    end
  end

  describe "finders" do
    before :all do
      Rightchoice.redis.flushall
      100.times{|i| Rightchoice::MultiVariations.find_or_create("test#{i}") }
    end

    let(:tests){ Rightchoice::MultiVariations.all }

    it "should return 100 multivariate tests" do
      tests.count.should == 100
      tests.first.class.should == String
      tests.first.should == "test0"
    end
  end

  describe "methods to reflesh" do
    describe "#flush_choices!" do
      it "should flush all the choices" do
        selections = @multi_variation.selections

        @multi_variation.flush_choices!
        @multi_variation.selections.should_not == selections
      end
    end
  end
end
