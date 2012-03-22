require 'spec_helper'
require 'rightchoice/calculator'

describe Rightchoice::AlternativeNode do
  describe "initialization" do
    before :all do
      # initialization
      test = Rightchoice::MultivariateTest.find_or_create(:test_sample)
      test.factors << Rightchoice::Factor.new(:factor1, "foo", "bar")
      test.factors << Rightchoice::Factor.new(:factor2, "hoge", "fuga")
      test.factors << Rightchoice::Factor.new(:factor3, "miko", "roid")
      test.save
    end

    let(:calc) { Rightchoice::Calculator.new(:test_sample) }

    def keys
      [
       "test_sample.factor1:foo.factor2:hoge.factor3:miko",
       "test_sample.factor1:foo.factor2:hoge.factor3:roid",
       "test_sample.factor1:foo.factor2:fuga.factor3:miko",
       "test_sample.factor1:foo.factor2:fuga.factor3:roid",
       "test_sample.factor1:bar.factor2:hoge.factor3:miko",
       "test_sample.factor1:bar.factor2:hoge.factor3:roid",
       "test_sample.factor1:bar.factor2:fuga.factor3:miko",
       "test_sample.factor1:bar.factor2:fuga.factor3:roid"
      ]
    end

    it "should have 2 variations and 7 nodes" do
      count = 0 # no methods like each_leaf_with_index so doing it myself. dirty.
      calc.root_node.each_leaf do |leaf|
        leaf.redis_key.should == keys[count]
        count = count + 1
      end
    end
  end

  describe "statistical numbers" do
    before :all do
      test = Rightchoice::MultivariateTest.find_or_create(:test_name)
      test.factors << Rightchoice::Factor.new(:factor1, "foo", "bar", :choice => "foo")
      test.factors << Rightchoice::Factor.new(:factor2, "hoge", "fuga", :choice => "hoge")
      test.save
      500.times { test.participate! }
      50.times { test.vote! }
    end

    let(:calc) { Rightchoice::Calculator.new(:test_name) }

    context "from calculator" do
      subject { calc.root_node["foo"]["hoge"] }
      its(:expectation) { should == 50 }
      its(:dispersion) { should == 45.0 }
      its(:probability) { should == 0.1 }
      its(:confidence_interval) { should == (0.07786292702275209..0.12213707297724792) }
      its(:confident?) { should be_true }
      its(:available?) { should be_true }
    end

    describe "availability" do
      it "should disable its node" do
        calc.root_node["foo"]["hoge"].available?.should be_true
        calc.root_node["foo"]["hoge"].disable!
        calc.root_node["foo"]["hoge"].available?.should be_false
      end
    end
  end
end
