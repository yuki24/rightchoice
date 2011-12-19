module Rightchoice
  class MultiVariations
    attr_accessor :multivariate_name, :variations
    attr_reader :votes_count, :participants_count

    def initialize(multivariate_name, options={})
      @multivariate_name = multivariate_name.to_s
      @variations = Rightchoice::VariationList.new
      @variations.mvtest = self
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
      @combinations = selections.to_a.map{|a| a.join(":") }.join(".")
      "#{name}.#{@combinations}"
    end

    def confident?
      (expectation > 5) && (dispersion > 5)
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
      variations.each(&:flush_choice!)
    end

    def save
      if !redis.exists(redis_key)
        redis.mapped_hmset(redis_key,
                    :available => @available,
                    :participants_count => 0,
                    :votes_count => 0)
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

    # def destroy
    #
    # end

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

    def self.find_or_create(testname)
      redis.hset("all_mvtests", testname.to_s, "[]") unless redis.hexists("all_mvtests", testname.to_s)
      new(testname.to_s)
    end

    def self.all
      redis.hkeys("all_mvtests")
    end

    def update_variations!
      redis.hset("all_mvtests", name, @variations.map(&:name).to_json)
    end

    private

    def self.redis
      Rightchoice.redis
    end

    def redis
      Rightchoice.redis
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

  class VariationList < Array
    attr_accessor :mvtest

    def <<(variation)
      self.empty? ? variation.root! : self.last.child = variation
      super(variation) and mvtest.update_variations!
      variation
    end

    def find(variation_name)
      self.detect { |v| v.name == variation_name.to_s }
    end
  end
end
