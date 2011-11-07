module Rightchoice
  class MultiVariations
    attr_accessor :multivariate_name, :variations

    def initialize(multivariate_name, options={})
      @multivariate_name = multivariate_name.to_s
      @variations = []
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
        variations.each {|v| s.store(v.name, v.choice) }
      end
    end

    def expectation
      @votes_count
    end

    def dispersion
      (expectation * (1 - (@votes_count.to_f / @participants_count))) if @participants_count != 0
    end

    def redis_key
      @combinations ||= selections.to_a.map{|a| a.join(":") }.join(".")
      "#{name}.#{@combinations}"
    end

    def confident?
      (expectation > 5) && (dispersion > 5)
    end

    def save
      if !redis.exists(redis_key)
        redis.mapped_hmset(redis_key,
                    :available => @available,
                    :participants_count => @participants_count,
                    :votes_count => @votes_count)
      end
    end

    def participate!
      if redis.exists(redis_key)
        redis.hincrby(redis_key, :participants_count, 1)
        @participants_count = @participants_count + 1
      end
    end

    def vote!
      if redis.exists(redis_key)
        redis.hincrby(redis_key, :votes_count, 1)
        @votes_count = @votes_count + 1
      end
    end

    def disable!
      redis.hmset(redis_key, :available, false)
    end

    def destroy
    end

    def self.find_by_testname_and_key(testname, redis_key)
      if exists?(testname, redis_key)
        # get the values @available, @participants_count, @votes_count from redis

        Rightchoice::MultiVariations
          .new(:available => available,
               :paricipants_count => participants_count,
               :votes_count => votes_count,).tap do |v|
#          v.
        end
      end
    end

    def available?
      redis.exists(redis_key) ? (redis.hget(redis_key, "available") == "true") : true
    end

    def self.available?(testname, combination)
      if exists?(testname, combination)
        redis.hget("#{testname}.#{combination}", "available") == "true"
      else
        # return false or raise error?
      end
    end

    def self.vote!(testname, combination)
      if available?(testname, combination)
        redis.hincrby("#{testname}.#{combination}", :votes_count, 1)
      else
        # raise CombinationNotFound, "The combination doesn't exist."
      end
    end

    def self.exists?(testname, combination)
      redis.exists("#{testname}.#{combination}")
    end

    private

    def redis
      @_redis ||= Rightchoice.redis
    end

    def self.variations_by_selections!(selections)
      # Variation.new(:variation_name2, "hoge", "fuga", :select => "hoge")
    end

    # MultiVariation.selections_by_key!("name.variation1:foo.variation2:hoge")
    #  => {"variation1" => "foo", "variation2" => "hoge"}
    def self.selections_by_key!(redis_key)
      Hash[*redis_key.tr(".",":").split(":")[1..-1]]
    end
  end
end
