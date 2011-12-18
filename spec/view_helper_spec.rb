require 'spec_helper'
require 'rightchoice/view_helper'

describe Rightchoice::ViewHelper do
  include Rightchoice::ViewHelper

  def session
    @_session ||= {}
  end

  def flush_session!
    Rightchoice.redis.flushall
    @_session = {}
  end

  describe "selecting variation" do
    it "should select without block" do
      alt = select_variation(:landing_page, :button_msg, "sign up", "join us", "learn more")
      ["sign up", "join us", "learn more"].should include(alt)

      Rightchoice::Variation.should_not_receive(:new).with(:button_msg, "sign up", "join us", "learn more")
      alt = select_variation(:landing_page, :button_msg, "sign up", "join us", "learn more")
      ["sign up", "join us", "learn more"].should include(alt)
    end

    it "should select and pass it to the given block" do
      select_variation(:landing_page, :button_color, "red", "green", "blue") do |alt|
        ["red", "green", "blue"].should include(alt)
      end

      Rightchoice::Variation.should_not_receive(:new).with(:button_color, "red", "green", "blue")
      select_variation(:landing_page, :button_color, "red", "green", "blue") do |alt|
        ["red", "green", "blue"].should include(alt)
      end
    end

    it "should select multiple variations" do
      alt = select_variation(:landing_page, :button_msg, "sign up", "join us", "learn more")
      ["sign up", "join us", "learn more"].should include(alt)

      select_variation(:landing_page, :button_color, "red", "green", "blue") do |alt|
        ["red", "green", "blue"].should include(alt)
      end
    end
  end

  describe "check availability" do
    # TODO: any better ways to test those examples?
    before(:each) do
      flush_session!

      # 1: suppose 1 user comes to the page and "sign up" and "red" are selected.
      select_variation(:landing_page, :button_msg, "sign up", "join us", "learn more", :choice => "sign up")
      select_variation(:landing_page, :button_color, "red", "green", "blue", :choice => "red")
    end

    it "should return false if there is no tests" do
      available?(:no_test_like_this).should be_false
    end

    it "should check if the combination of the multivariate test is available or not" do
      available?(:landing_page).should be_true

      # 2: then the calculation runs.
      fake_voting!
      Rightchoice::Calculator.new(:landing_page).disable_ineffective_nodes!

      # 3: after that, the combination should not be available.
      available?(:landing_page).should be_false
    end

    it "should reselect the combination" do
      # 2-3: same as above
      fake_voting!
      Rightchoice::Calculator.new(:landing_page).disable_ineffective_nodes!
      available?(:landing_page).should be_false

      # 4: select the combination over.
      reselect!(:landing_page)
      available?(:landing_page).should be_true

      # then make sure the new combination is not the same as before.
      alt = []
      alt << select_variation(:landing_page, :button_msg, "sign up", "join us", "learn more")
      alt << select_variation(:landing_page, :button_color, "red", "green", "blue")
      alt.should_not == ["sign up", "red"]
    end

    def fake_voting!
      3000.times do |count|
        # initialization
        multi_variation = Rightchoice::MultiVariations.find_or_create(:landing_page)
        variation1 = Rightchoice::Variation.find_or_create(:button_msg, "sign up", "join us", "learn more")
        variation2 = Rightchoice::Variation.find_or_create(:button_color, "red", "green", "blue")
        multi_variation.variations << variation1
        multi_variation.variations << variation2
        multi_variation.save
        multi_variation.participate!

        # fake voting
        if variation1.choice == "sign up" && variation2.choice == "red"
          (count % 100 == 0) ? multi_variation.vote! : nil
        elsif variation1.choice == "sign up" && variation2.choice == "green"
          (count % 80 == 0) ? multi_variation.vote! : nil
        elsif variation1.choice == "sign up" && variation2.choice == "blue"
          (count % 60 == 0) ? multi_variation.vote! : nil
        elsif variation1.choice == "join us" && variation2.choice == "red"
          (count % 50 == 0) ? multi_variation.vote! : nil
        elsif variation1.choice == "join us" && variation2.choice == "green"
          (count % 40 == 0) ? multi_variation.vote! : nil
        elsif variation1.choice == "join us" && variation2.choice == "blue"
          (count % 30 == 0) ? multi_variation.vote! : nil
        elsif variation1.choice == "learn more" && variation2.choice == "red"
          (count % 20 == 0) ? multi_variation.vote! : nil
        elsif variation1.choice == "learn more" && variation2.choice == "green"
          (count % 5 == 0) ? multi_variation.vote! : nil
        elsif variation1.choice == "learn more" && variation2.choice == "blue"
          (count % 2 == 0) ? multi_variation.vote! : nil
        end
      end
    end
  end
end
