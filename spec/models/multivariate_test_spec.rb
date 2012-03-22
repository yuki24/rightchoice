require 'spec_helper'
require 'rightchoice/models/multivariate_test'

describe Rightchoice::MultivariateTest do
  before(:all) { Rightchoice.redis.flushdb }
  let(:test) { Rightchoice::MultivariateTest.find_or_create(:test_name) }
  let(:factor1) { Rightchoice::Factor.new(:factor1, "foo", "bar", choice: "foo") }
  let(:factor2) { Rightchoice::Factor.new(:factor2, "hoge", "fuga", choice: "hoge") }

  describe "initialization" do
    context "default params" do
      subject { test }
      its(:name) { should == "test_name" }
      its(:factors) { should be_empty }
    end

    context "with factors" do
      before :all do
        test.factors << factor1
        test.factors << factor2
      end

      subject { test }
      its(:selections) { should == {"factor1" => "foo", "factor2" => "hoge"} }
      its(:redis_key) { should == "test_name.factor1:foo.factor2:hoge" }

      describe "factor lists" do
        subject { test.factors }
        its(:count) { should == 2 }
        it { should include(factor1) }
        it { should include(factor2) }
      end
    end
  end

  describe "addition of factors and selection" do
    it "should have 1 factors" do
      expect {
        test.factors << factor1
        test.factors << factor2
        test.save
      }.to change {
        Rightchoice.redis.hkeys(test.name)
      }.from([]).to(["factor1", "factor2"])

      Rightchoice.redis.hget(test.name, factor1.name).should == ["foo", "bar"].to_json
    end

  end

  describe 'availability' do
    it "should save a multivariate test" do
      test.participate!
      Rightchoice.redis.del(test.redis_key)

      test.participate!
      Rightchoice.redis.hget(test.redis_key, "participants_count").should == "1"
      Rightchoice.redis.hget(test.redis_key, "votes_count").should == "0"
    end

    context "for available combinations" do
      subject { test }
      its(:available?) { should be_true }
    end

    context "for unavailable combinations" do
      before { test.disable! }
      subject { test }
      its(:available?) { should be_false }
    end
  end

  describe "finders" do
    describe ".all" do
      context "listing all MultivariateTest instances" do
        before :all do
          Rightchoice.redis.flushdb
          1.upto(5){|i| Rightchoice::MultivariateTest.find_or_create("test#{i}") }
        end

        subject { Rightchoice::MultivariateTest.all }
        it { should be_a(Array) }
        its(:count) { should == 5 }
        its(:first) { should be_a(Rightchoice::MultivariateTest) }
      end
    end

    describe ".find" do
      context "correct find" do
        subject { Rightchoice::MultivariateTest.find("test1") }
        it { should be_a(Rightchoice::MultivariateTest) }
        its(:name) { should == "test1" }
      end

      it "should raise an exception" do
        expect {
          Rightchoice::MultivariateTest.find("no_test")
        }.to raise_exception(Rightchoice::TestNotFound)
      end
    end

    describe ".find_or_create" do
      before { test }

      it "should find a new MultivariateTest object" do
        expect {
          Rightchoice::MultivariateTest.find_or_create(:test_name)
        }.to change{ Rightchoice::MultivariateTest.all.count }.by(0)
      end

      it "should create a new MultivariateTest object" do
        expect {
          Rightchoice::MultivariateTest.find_or_create(:another_test)
        }.to change{ Rightchoice::MultivariateTest.all.count }.by(1)

        Rightchoice::MultivariateTest.all.should
          include(Rightchoice::MultivariateTest.find("another_test"))
      end
    end
  end

  describe "methods to reflesh" do
    describe "#flush_choices!" do
      before(:all) do
        test.factors << factor1
        test.factors << factor2
        test.disable!
      end

      it "should flush all the choices" do
        selections = test.selections
        begin
          test.flush_choices!
        end while(!test.available?)

        test.selections.should_not == selections
      end
    end
  end
end
