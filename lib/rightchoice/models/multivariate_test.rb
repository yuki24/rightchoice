require 'rightchoice/exceptions'
require 'rightchoice/models/factor'

module Rightchoice
  class MultivariateTest
    attr_accessor :multivariate_name, :factors
    attr_reader :votes_count, :participants_count

    def initialize(multivariate_name, options={})
      @multivariate_name = multivariate_name.to_s
      @factors = Rightchoice::FactorList.new
      @factors.mvtest = self
      @selections = {}
      @available = true
      @participants_count = (options[:participants_count] || 0)
      @votes_count = (options[:votes_count] || 0)
    end

    def name
      multivariate_name
    end

    def selections
      @selections.tap do |s|
        factors.each {|f| s.store(f.name, f.choice) }
      end
    end

    def redis_key
      @combinations = selections.to_a.map{|a| a.join(":") }.join(".")
      "#{name}.#{@combinations}"
    end

    def already_participated?
      @already_participated
    end

    def already_voted?
      @already_voted
    end

    def flush_choices!
      @selections = {}
      @already_voted = @already_participated = nil
      factors.each(&:flush_choice!)
    end

    def save
      store_metadata!
      if !redis.exists(redis_key)
        redis.mapped_hmset(redis_key,
          available: @available, participants_count: 0, votes_count: 0)
      end
    end

    def participate!
      save unless redis.exists(redis_key)
      redis.hincrby(redis_key, :participants_count, 1)
      @participants_count = @participants_count + 1
      @already_participated = true
    end

    def vote!
      save unless redis.exists(redis_key)
      redis.hincrby(redis_key, :votes_count, 1)
      @votes_count = @votes_count + 1
      @already_voted = true
    end

    def disable!
      redis.hmset(redis_key, :available, false)
    end

    def store_metadata!
      push_to_index!
      update_factors! if @factors.changed?
    end

    def available?
      redis.exists(redis_key) ? (redis.hget(redis_key, "available") == "true") : true
    end

    def self.find(testname)
      raise TestNotFound.new(testname) unless redis.hexists("all_mvtests", testname.to_s)

      test = MultivariateTest.new(testname)
      redis.hgetall(testname).each do |factor_name, alts|
        test.factors << Rightchoice::Factor.new(factor_name, *JSON.parse(alts))
      end
      test
    end

    def self.find_or_create(testname)
      find(testname.to_s)
    rescue TestNotFound => e
      test = new(testname)
      test.store_metadata!
      test
    end

    def self.all
      redis.hkeys("all_mvtests").map!{ |testname| find(testname) }
    end

    private

    def self.redis
      Rightchoice.redis
    end

    def redis
      Rightchoice.redis
    end

    def push_to_index!
      redis.hsetnx("all_mvtests", name, Time.now.to_i)
    end

    def update_factors!
      @factors.changed = false
      redis.mapped_hmset(name, factors.to_hash)
    end
  end

  class FactorList < Array
    attr_accessor :mvtest
    attr_writer :changed

    def <<(factor)
      super(factor) and @changed = true
      self
    end

    def changed?
      @changed == true
    end

    def to_hash
      {}.tap do |hash|
        each {|factor| hash[factor.name] = factor.alternatives.to_json }
      end
    end

    def find(factor_name)
      self.detect { |v| v.name == factor_name.to_s }
    end
  end
end
