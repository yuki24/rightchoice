require 'spec_helper'
require 'rightchoice/models/multi_variations'

describe Rightchoice::MultiVariations do
  before(:each) { Rightchoice.redis.flushall }

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
      @variation1 = Rightchoice::Variation.new(:variation_name1, "foo", "bar", :choice => "foo")
      @variation2 = Rightchoice::Variation.new(:variation_name2, "hoge", "fuga", :choice => "hoge")
    end

    it "should have 1 variation" do
      @multi_variation.variations << @variation1
      @multi_variation.variations.count.should be 1
      @multi_variation.variations.find(:variation_name1).should == @variation1
      @multi_variation.variations.find(:variation_name2).should be_nil
    end

    it "should have 2 variations" do
      @multi_variation.variations << @variation2
      @multi_variation.variations.count.should be 2
      @multi_variation.variations.find(:variation_name2).should == @variation2
    end
  end

  context "getters" do
    subject { @multi_variation }
    its(:selections) { should == {"variation_name1" => "foo", "variation_name2" => "hoge"} }
    its(:redis_key) { should == "test_name.variation_name1:foo.variation_name2:hoge" }
  end

  context "statistical numbers" do
    before :all do
      @multi_variation.save
      1000.times { @multi_variation.participate! }
      100.times { @multi_variation.vote! }
    end

    subject { @multi_variation }
    its(:expectation) { should == 100 }
    its(:dispersion) { should == 90 }
    its(:confident?) { should be_true }
  end

  describe 'availability check' do
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

=begin
  describe 'deletion' do
    before :all do
      @multi_variation = Rightchoice::Experiment.new('basket_text', 'Basket', "Cart")
    end

    it 'should delete itself' do
      @multi_variation.save
      @multi_variation.delete
      Rightchoice.redis.exists('basket_text').should be false
      lambda { Rightchoice::Experiment.find('link_color') }.should raise_error
    end
    
    it "should increment the version" do
      @multi_variation = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'red', 'green')
      @multi_variation.version.should eql(0)
      @multi_variation.delete
      @multi_variation.version.should eql(1)
    end
  end

  describe 'new record?' do
    before :all do
      @multi_variation = Rightchoice::Experiment.new('basket_text', 'Basket', "Cart")
    end

    it "should know if it hasn't been saved yet" do
      @multi_variation.new_record?.should be_true
    end

    it "should know if it has been saved yet" do
      @multi_variation.save
      @multi_variation.new_record?.should be_false
    end
  end

  it "should return an existing experiment" do
    experiment = Rightchoice::Experiment.new('basket_text', 'Basket', "Cart")
    experiment.save
    Rightchoice::Experiment.find('basket_text').name.should eql('basket_text')
  end

  describe 'control' do
    it 'should be the first alternative' do
      experiment = Rightchoice::Experiment.new('basket_text', 'Basket', "Cart")
      experiment.save
      experiment.control.name.should eql('Basket')
    end
  end

  describe 'winner' do
    it "should have no winner initially" do
      experiment = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'red')
      experiment.winner.should be_nil
    end

    it "should allow you to specify a winner" do
      experiment = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'red')
      experiment.winner = 'red'

      experiment = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'red')
      experiment.winner.name.should == 'red'
    end
  end

  describe 'reset' do
    it 'should reset all alternatives' do
      experiment = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'red', 'green')
      green = Rightchoice::Alternative.find('green', 'link_color')
      experiment.winner = 'green'

      experiment.next_alternative.name.should eql('green')
      green.increment_participation

      experiment.reset

      reset_green = Rightchoice::Alternative.find('green', 'link_color')
      reset_green.participant_count.should eql(0)
      reset_green.completed_count.should eql(0)
    end

    it 'should reset the winner' do
      experiment = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'red', 'green')
      green = Rightchoice::Alternative.find('green', 'link_color')
      experiment.winner = 'green'

      experiment.next_alternative.name.should eql('green')
      green.increment_participation

      experiment.reset

      experiment.winner.should be_nil
    end

    it "should increment the version" do
      experiment = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'red', 'green')
      experiment.version.should eql(0)
      experiment.reset
      experiment.version.should eql(1)
    end
  end

  describe 'next_alternative' do
    it "should return a random alternative from those with the least participants" do
      experiment = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'red', 'green')

      Rightchoice::Alternative.find('blue', 'link_color').increment_participation
      Rightchoice::Alternative.find('red', 'link_color').increment_participation

      experiment.next_alternative.name.should eql('green')
    end

    it "should always return the winner if one exists" do
      experiment = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'red', 'green')
      green = Rightchoice::Alternative.find('green', 'link_color')
      experiment.winner = 'green'

      experiment.next_alternative.name.should eql('green')
      green.increment_participation

      experiment = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'red', 'green')
      experiment.next_alternative.name.should eql('green')
    end
  end

  describe 'changing an existing experiment' do
    it "should reset an experiment if it is loaded with different alternatives" do
      experiment = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'red', 'green')
      blue = Rightchoice::Alternative.find('blue', 'link_color')
      blue.participant_count = 5
      blue.save
      same_experiment = Rightchoice::Experiment.find_or_create('link_color', 'blue', 'yellow', 'orange')
      same_experiment.alternatives.map(&:name).should eql(['blue', 'yellow', 'orange'])
      new_blue = Rightchoice::Alternative.find('blue', 'link_color')
      new_blue.participant_count.should eql(0)
    end
  end

  describe 'alternatives passed as non-strings' do
    it "should throw an exception if an alternative is passed that is not a string" do
      lambda { Rightchoice::Experiment.find_or_create('link_color', :blue, :red) }.should raise_error
      lambda { Rightchoice::Experiment.find_or_create('link_enabled', true, false) }.should raise_error
    end
  end
=end
end
