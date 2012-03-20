require 'spec_helper'
require 'rightchoice/models/multivariate_test'

describe Rightchoice::MultivariateTest do
  before(:all) { Rightchoice.redis.flushdb }
  let(:multivariate_test) { Rightchoice::MultivariateTest.find_or_create(:test_name) }
  let(:factor1) { Rightchoice::Factor.new(:factor1, "foo", "bar", :choice => "foo") }
  let(:factor2) { Rightchoice::Factor.new(:factor2, "hoge", "fuga", :choice => "hoge") }

  describe "initialization" do
    context 'default params' do
      subject { multivariate_test }
      its(:name) { should == "test_name" }
    end

    it "should not have any factors" do
      multivariate_test.factors.count.should be 0
    end
  end

  describe "addition of factors and selection" do
    it "should have 1 factors" do
      expect {
        multivariate_test.factors << factor1
        multivariate_test.factors << factor2
        multivariate_test.save

        multivariate_test.factors.count.should be 2
        multivariate_test.factors.find(:factor1).should == factor1
        multivariate_test.factors.find(:factor2).should == factor2
      }.to change {
        Rightchoice.redis.hkeys(multivariate_test.name)
      }.from([]).to(["factor1", "factor2"])

      Rightchoice.redis.hget(multivariate_test.name, factor1.name).should == ["foo", "bar"].to_json
    end

    context "getters" do
      before :all do
        multivariate_test.factors << factor1
        multivariate_test.factors << factor2
      end

      subject { multivariate_test }
      its(:selections) { should == {"factor1" => "foo", "factor2" => "hoge"} }
      its(:redis_key) { should == "test_name.factor1:foo.factor2:hoge" }
    end
  end
=begin
  context "statistical numbers" do
    before :all do
      1000.times { multivariate_test.participate! }
      100.times { multivariate_test.vote! }
    end

    subject { multivariate_test }
    its(:expectation) { should == 100 }
    its(:dispersion) { should == 90 }
    its(:confident?) { should be_true }
  end
=end
  describe 'availability' do
    it "should save a multivariate test" do
      multivariate_test.participate!
      Rightchoice.redis.del(multivariate_test.redis_key)

      multivariate_test.participate!
      Rightchoice.redis.hget(multivariate_test.redis_key, "participants_count").should == "1"
      Rightchoice.redis.hget(multivariate_test.redis_key, "votes_count").should == "0"
    end

    context "for available combinations" do
      subject { multivariate_test }
      its(:available?) { should be_true }
    end

    context "for unavailable combinations" do
      before { multivariate_test.disable! }
      subject { multivariate_test }
      its(:available?) { should be_false }
    end
  end

  describe "finders" do
    describe ".all" do
      context "listing all MultivariateTest instances" do
        before :all do
          Rightchoice.redis.flushdb
          (1..100).each do |i|
            Rightchoice::MultivariateTest.find_or_create("test#{i}")
          end
        end

        subject { Rightchoice::MultivariateTest.all }
        its(:count) { should == 100 }
        its(:first) { should be_a(Rightchoice::MultivariateTest) }
      end
    end

    describe ".find" do
      it "should raise an exception" do
        expect {
          Rightchoice::MultivariateTest.find("no_test")
        }.to raise_exception(Rightchoice::TestNotFound)
      end

      context "correct find" do
        subject { Rightchoice::MultivariateTest.find("test1") }
        it { should be_a(Rightchoice::MultivariateTest) }
        its(:factors) { should be_a(Rightchoice::FactorList) }
      end
    end

    describe "#find_or_create" do
      it "should create a new multi_variations object" do
        Rightchoice::MultivariateTest.find_or_create(:test_name)
        expect {
          Rightchoice::MultivariateTest.find_or_create(:test_name)
        }.to change{ Rightchoice.redis.hlen("all_mvtests") }.by(0)
      end

      it "should create a new MultivariateTest object" do
        expect {
          Rightchoice::MultivariateTest.find_or_create(:another_test)
        }.to change{ Rightchoice.redis.hlen("all_mvtests") }.by(1)

        Rightchoice.redis.hexists("all_mvtests", "another_test").should be_true
      end
    end
  end

  describe "methods to reflesh" do
    describe "#flush_choices!" do
      before(:all) do
        multivariate_test.factors << factor1
        multivariate_test.factors << factor2
      end

      it "should flush all the choices" do
        selections = multivariate_test.selections
        multivariate_test.flush_choices!
        multivariate_test.selections.should_not == selections
      end
    end
  end
end
