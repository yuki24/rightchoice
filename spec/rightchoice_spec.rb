require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Rightchoice do
  before { Rightchoice.redis.flushdb }

  it "can set a namespace through a url-like string" do
    Rightchoice.redis.should be_true
    Rightchoice.redis.namespace.should == :rightchoice
    Rightchoice.redis = 'localhost:6379/namespace'
    Rightchoice.redis.namespace.should == 'namespace'
  end

  it "works correctly with a Redis::Namespace param" do
    new_redis = Redis.new(:host => "localhost", :port => 6379)
    new_namespace = Redis::Namespace.new("namespace", :redis => new_redis)
    Rightchoice.redis = new_namespace
    Rightchoice.redis.should == new_namespace
  end

  it "works correctly with a Redis param" do
    new_redis = Redis.new(:host => "localhost", :port => 6379)
    Rightchoice.redis = new_redis
    Rightchoice.redis.class.should == Redis::Namespace
  end
end
