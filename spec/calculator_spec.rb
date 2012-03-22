require 'spec_helper'
require 'rightchoice/calculator'

describe Rightchoice::Calculator do
  before do
    200.times do |count|
      # initialization
      test = Rightchoice::MultivariateTest.find_or_create(:test_sample)
      factor1 = Rightchoice::Factor.new(:factor1, "foo", "bar")
      factor2 = Rightchoice::Factor.new(:factor2, "hoge", "fuga")
      test.factors << factor1
      test.factors << factor2
      test.save
      test.participate!

      # fake voting
      if factor1.choice == "foo" && factor2.choice == "hoge"
        (count % 2 == 0) ? test.vote! : nil
      elsif factor1.choice == "foo" && factor2.choice == "fuga"
        (count % 10 == 0) ? test.vote! : nil
      elsif factor1.choice == "bar" && factor2.choice == "hoge"
        (count % 15 == 0) ? test.vote! : nil
      elsif factor1.choice == "bar" && factor2.choice == "fuga"
        (count % 20 == 0) ? test.vote! : nil
      end
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
