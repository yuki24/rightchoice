require 'spec_helper'
require 'rightchoice/calculator'

describe Rightchoice::AlternativeNode do
  describe "initialization" do
    before :all do
      # initialization
      multi_variation = Rightchoice::MultiVariations.find_or_create(:test_sample)
      variation1 = Rightchoice::Variation.find_or_create(:variation_name1, "foo", "bar")
      variation2 = Rightchoice::Variation.find_or_create(:variation_name2, "hoge", "fuga")
      variation3 = Rightchoice::Variation.find_or_create(:variation_name3, "miko", "roid")
      multi_variation.variations << variation1
      multi_variation.variations << variation2
      multi_variation.variations << variation3
      multi_variation.save
    end

    let(:calc) { Rightchoice::Calculator.new(:test_sample) }

    it "should have 2 variations and 7 nodes" do
      count = 0 # no methods like each_leaf_with_index so doing it myself. dirty.
      calc.root_node.each_leaf do |leaf|
        leaf.redis_key.should == keys[count]
        count = count + 1
      end
    end

    def keys
      [
       "test_sample.variation_name1:foo.variation_name2:hoge.variation_name3:miko",
       "test_sample.variation_name1:foo.variation_name2:hoge.variation_name3:roid",
       "test_sample.variation_name1:foo.variation_name2:fuga.variation_name3:miko",
       "test_sample.variation_name1:foo.variation_name2:fuga.variation_name3:roid",
       "test_sample.variation_name1:bar.variation_name2:hoge.variation_name3:miko",
       "test_sample.variation_name1:bar.variation_name2:hoge.variation_name3:roid",
       "test_sample.variation_name1:bar.variation_name2:fuga.variation_name3:miko",
       "test_sample.variation_name1:bar.variation_name2:fuga.variation_name3:roid"
      ]
    end
  end

  describe "statistical numbers" do
    before :all do
      multi_variation = Rightchoice::MultiVariations.find_or_create(:test_name)
      variation1 = Rightchoice::Variation.find_or_create(:variation_name1, "foo", "bar", :choice => "foo")
      variation2 = Rightchoice::Variation.find_or_create(:variation_name2, "hoge", "fuga", :choice => "hoge")
      multi_variation.variations << variation1
      multi_variation.variations << variation2
      multi_variation.save
      1000.times { multi_variation.participate! }
      100.times { multi_variation.vote! }
    end

    let(:calc) { Rightchoice::Calculator.new(:test_name) }

    context "from calculator" do
      subject { calc.root_node["foo"]["hoge"] }
      its(:expectation) { should == 100 }
      its(:dispersion) { should == 90 }
      its(:probability) { should == 0.1 }
      its(:confidence_interval) { should == (0.08140580735820993..0.11859419264179008) }
      its(:confident?) { should be_true }
      its(:available?) { should be_true }
    end

    it "should normalize numbers" do
      calc.root_node["foo"]["hoge"].normalized_to(900)
      calc.root_node["foo"]["hoge"].expectation.should == 90
      calc.root_node["foo"]["hoge"].dispersion.should == 81
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
