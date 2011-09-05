require 'spec_helper'

describe Rightchoice::Track do
  describe "AB test" do
    before :all do
      @track = Rightchoice::Track.new :foo, :version => 0
    end

    it "should return the selected version" do
      @track.alternative.should == 0
    end

    it "should return the status of the track" do
      @track.finished?.should be_false
    end

    it "should finish tracking" do
      @track.finish!.should be_true
      @track.finished?.should be_true
    end
  end
end
