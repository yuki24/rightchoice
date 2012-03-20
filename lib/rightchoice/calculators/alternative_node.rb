module Rightchoice
  class AlternativeNode < Tree::TreeNode

    def participants_count
      redis.exists(redis_key) ? redis.hget(redis_key, "participants_count").to_i : nil
    end
    alias :participants :participants_count

    def votes_count
      redis.exists(redis_key) ? redis.hget(redis_key, "votes_count").to_i : nil
    end
    alias :votes       :votes_count
    alias :expectation :votes_count

    def dispersion
      expectation * (1 - (votes.to_f / participants)) if participants != 0
    end

    def probability
      votes_count.to_f / participants_count
    end

    def confidence_interval
      p = probability and n = participants_count
      (p-(1.65 * Math.sqrt((p*(1-p)) / n)))..(p+(1.65 * Math.sqrt((p*(1-p)) / n)))
    end

    def available?
      redis.exists(redis_key) ? (redis.hget(redis_key, "available") == "true") : nil
    end

    def confident?
      (expectation > 5) && (dispersion > 5)
    end

    def disable!
      redis.exists(redis_key) ? redis.hmset(redis_key, :available, false) : nil
    end

    def redis_key
      @redis_key ||= [self, *parentage].reverse.map(&:key_pair).join(".")
    end

    def key_pair
      is_root? ? name : "#{content}:#{name}"
    end

    private

    def redis
      Rightchoice.redis
    end
  end
end
