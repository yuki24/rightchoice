require 'spec_helper'
require 'rightchoice/calculator'

describe Rightchoice::Calculator do
  before do
    test = Rightchoice::MultivariateTest.find_or_create(:test_sample)
    factor1 = Rightchoice::Factor.new(:factor1, "foo", "bar")
    factor2 = Rightchoice::Factor.new(:factor2, "hoge", "fuga")
    test.factors << factor1
    test.factors << factor2
    test.save

    {
      "test_sample.factor1:foo.factor2:hoge" => 90,
      "test_sample.factor1:foo.factor2:fuga" => 30,
      "test_sample.factor1:bar.factor2:hoge" => 20,
      "test_sample.factor1:bar.factor2:fuga" => 10,
    }.each do |key, val|
      Rightchoice.redis.mapped_hmset(key,
        available: true, participants_count: 100, votes_count: val)
    end
  end

  describe "initialization" do
    it "should have 2 factors and 7 nodes" do
      calc = Rightchoice::Calculator.new(:test_sample)
      calc.factors.first.class.should == Rightchoice::Factor
      calc.factors.count.should == 2
      calc.root_node.size.should == 7
    end
  end

  describe "calculate statistical numbers" do
    let(:calc) { Rightchoice::Calculator.new(:test_sample) }

    it "should disable ineffective combinations" do
      calc.disable_ineffective_nodes!

      calc.root_node["foo"]["hoge"].available?.should be_true
      calc.root_node["foo"]["fuga"].available?.should be_false
      calc.root_node["bar"]["hoge"].available?.should be_false
      calc.root_node["bar"]["fuga"].available?.should be_false
      calc.finished?.should be_true
    end
  end
end
