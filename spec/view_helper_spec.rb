require 'spec_helper'
require 'rightchoice/view_helper'

describe Rightchoice::ViewHelper do
  include Rightchoice::ViewHelper

  def session
    @_session ||= {}
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
  end
end
