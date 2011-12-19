require 'spec_helper'
require 'rightchoice/calculator'

describe Rightchoice::Calculator do
  before do
    300.times do |count|
      # initialization
      multi_variation = Rightchoice::MultiVariations.find_or_create(:test_sample)
      variation1 = Rightchoice::Variation.find_or_create(:variation_name1, "foo", "bar")
      variation2 = Rightchoice::Variation.find_or_create(:variation_name2, "hoge", "fuga")
      multi_variation.variations << variation1
      multi_variation.variations << variation2
      multi_variation.save
      multi_variation.participate!

      # fake voting
      if variation1.choice == "foo" && variation2.choice == "hoge"
        (count % 2 == 0) ? multi_variation.vote! : nil
      elsif variation1.choice == "foo" && variation2.choice == "fuga"
        (count % 10 == 0) ? multi_variation.vote! : nil
      elsif variation1.choice == "bar" && variation2.choice == "hoge"
        (count % 15 == 0) ? multi_variation.vote! : nil
      elsif variation1.choice == "bar" && variation2.choice == "fuga"
        (count % 20 == 0) ? multi_variation.vote! : nil
      end
    end
  end

  describe "initialization" do
    it "should have 2 variations and 7 nodes" do
      calc = Rightchoice::Calculator.new(:test_sample)
      calc.variations.first.class.should == Rightchoice::Variation
      calc.variations.count.should == 2
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
    end
  end
end
