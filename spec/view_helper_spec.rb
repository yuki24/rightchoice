require 'spec_helper'
require 'rightchoice/view_helper'

describe Rightchoice::ViewHelper do
  def self.before_filter(f) nil; end
  def self.after_filter(f) nil; end
  include Rightchoice::ViewHelper

  def session
    @_session ||= {}
  end

  def flush_session!
    Rightchoice.redis.flushdb
    @_session = {}
  end

  describe "selecting variation and voting up" do
    it "should select without block" do
      alt = select_variation(:land_page, :btn_msg, "sign up", "join us", "learn more")
      ["sign up", "join us", "learn more"].should include(alt)

      Rightchoice::Factor.should_not_receive(:new).with(:btn_msg, "sign up", "join us", "learn more")
      alt = select_variation(:land_page, :btn_msg, "sign up", "join us", "learn more")
      ["sign up", "join us", "learn more"].should include(alt)
    end

    it "should select and pass it to the given block" do
      select_variation(:land_page, :btn_color, "red", "green", "blue") do |alt|
        ["red", "green", "blue"].should include(alt)
      end

      Rightchoice::Factor.should_not_receive(:new).with(:btn_color, "red", "green", "blue")
      select_variation(:land_page, :btn_color, "red", "green", "blue") do |alt|
        ["red", "green", "blue"].should include(alt)
      end
    end

    it "should select multiple variations" do
      alt = select_variation(:land_page, :btn_msg, "sign up", "join us", "learn more")
      ["sign up", "join us", "learn more"].should include(alt)

      select_variation(:land_page, :btn_color, "red", "green", "blue") do |alt|
        ["red", "green", "blue"].should include(alt)
      end
    end

    it "should vote up" do
      select_variation(:land_page, :btn_msg, "sign up", "join us", "learn more")
      select_variation(:land_page, :btn_color, "red", "green", "blue")

      expect {
        finish!(:land_page)
      }.to change(multivariate_test(:land_page), :votes_count).by(1)

      expect {
        finish!(:land_page)
      }.to change(multivariate_test(:land_page), :votes_count).by(0)
    end
  end

  describe "automatic optimization" do
    # TODO: any better ways to test those examples?
    before(:each) do
      flush_session!

      # 1: suppose 1 user comes to the page and "sign up" and "red" are selected.
      select_variation(:land_page, :btn_msg, "sign up", "join us", "learn more", choice: "sign up")
      select_variation(:land_page, :btn_color, "red", "green", "blue", choice: "red")
    end

    it "should return false if there is no tests" do
      available?(:no_test_like_this).should be_false
    end

    it "should check if the combination of the multivariate test is available or not" do
      available?(:land_page).should be_true

      # 2: then the calculation runs.
      fake_voting!
      Rightchoice::Calculator.new(:land_page).disable_ineffective_nodes!

      # 3: after that, the combination should not be available.
      available?(:land_page).should be_false
    end

    it "should reselect the combination" do
      # 2-3: same as above
      fake_voting!
      participate!
      Rightchoice::Calculator.new(:land_page).disable_ineffective_nodes!
      available?(:land_page).should be_false

      # 4: select the combination over.
      reselect!(:land_page)
      multivariate_test(:land_page).available?.should be_true
      multivariate_test(:land_page).already_participated?.should be_false
      multivariate_test(:land_page).already_voted?.should be_false

      # then make sure the new combination is not the same as before.
      alt = []
      alt << select_variation(:land_page, :btn_msg, "sign up", "join us", "learn more")
      alt << select_variation(:land_page, :btn_color, "red", "green", "blue")
      alt.should_not == ["sign up", "red"]
    end

    def fake_voting!
      test = Rightchoice::MultivariateTest.find_or_create(:land_page)
      factor1 = Rightchoice::Factor.new(:btn_msg, "sign up", "join us", "learn more")
      factor2 = Rightchoice::Factor.new(:btn_color, "red", "green", "blue")
      test.factors << factor1
      test.factors << factor2
      test.save

      {
        "land_page.btn_msg:sign up.btn_color:red" => 10,
        "land_page.btn_msg:sign up.btn_color:green" => 90,
        "land_page.btn_msg:sign up.btn_color:blue" => 90,
        "land_page.btn_msg:join us.btn_color:red" => 90,
        "land_page.btn_msg:join us.btn_color:green" => 90,
        "land_page.btn_msg:join us.btn_color:blue" => 90,
        "land_page.btn_msg:learn more.btn_color:red" => 90,
        "land_page.btn_msg:learn more.btn_color:green" => 90,
        "land_page.btn_msg:learn more.btn_color:blue" => 90
      }.each do |key, val|
        Rightchoice.redis.mapped_hmset(key,
          available: true, participants_count: 100, votes_count: val)
      end
    end
  end

  describe "filters" do
    describe "before filter #check_availability" do
      it "should not do anything if there is no test" do
        self.should_receive(:multivariate_tests).and_return({})
        self.should_not_receive(:available?).with(:land_page)
        self.should_not_receive(:reselect!)
        check_availability!
      end

      it "should check the availability but not reselect" do
        select_variation(:land_page, :btn_msg, "sign up", "join us", "learn more")
        select_variation(:land_page, :btn_color, "red", "green", "blue")

        self.should_receive(:available?).with(:land_page).and_return(true)
        self.should_not_receive(:reselect!)
        check_availability!
      end

      it "should reselect another combination" do
        select_variation(:land_page, :btn_msg, "sign up", "join us", "learn more")
        select_variation(:land_page, :btn_color, "red", "green", "blue")

        self.should_receive(:available?).with(:land_page).and_return(false)
        self.should_receive(:reselect!).with(:land_page)
        check_availability!
      end
    end

    describe "after filter #participate!" do
      it "should add a participant" do
        select_variation(:land_page, :btn_msg, "sign up", "join us", "learn more")
        select_variation(:land_page, :btn_color, "red", "green", "blue")

        expect {
          participate!
        }.to change(multivariate_test(:land_page), :participants_count).by(1)

        expect {
          participate!
        }.to change(multivariate_test(:land_page), :participants_count).by(0)
      end

      it "should not add participants when there is no multivariate test" do
        session[:_rightchoice_testname] = nil
        expect {
          participate!
        }.to change(multivariate_test(:land_page), :participants_count).by(0)
      end

      it "should start calculating when the number of participants hits 100" do
        Rightchoice::Calculator.any_instance.should_receive(:disable_ineffective_nodes!)

        200.times do
          @_session = {}
          select_variation(:test_page, :btn_msg, "sign up", "join us")
          participate!
        end
      end
    end
  end
end
