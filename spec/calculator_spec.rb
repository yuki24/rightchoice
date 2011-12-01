require 'spec_helper'
require 'rightchoice/calculator'

describe Rightchoice::Calculator do
  before do
    multi_variation = Rightchoice::MultiVariations.find_or_create(:test_sample)
    variation1 = Rightchoice::Variation.find_or_create(:variation_name1, "foo", "bar")
    variation2 = Rightchoice::Variation.find_or_create(:variation_name2, "hoge", "fuga")
    multi_variation.variations << variation1
    multi_variation.variations << variation2
    multi_variation.save
  end

  describe "initialization" do
    it "should have 2 variations and 7 nodes" do
      calc = Rightchoice::Calculator.new(:test_sample)
      calc.variations.first.class.should == Rightchoice::Variation
      calc.variations.count.should == 2
      calc.root_node.size.should == 7
    end
  end
end
