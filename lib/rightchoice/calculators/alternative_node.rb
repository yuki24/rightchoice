module Rightchoice
  class AlternativeNode < Tree::TreeNode

    def participants_count
      redis.exists(redis_key) ? redis.hget(redis_key, "participants_count").to_i : nil
    end
    alias :participants :participants_count

    def votes_count
      redis.exists(redis_key) ? (redis.hget(redis_key, "votes_count").to_i * normalization_range) : nil
    end
    alias :votes :votes_count

    def normalized_to(participants)
      @_scale ||= participants
    end

    def expectation
      votes_count
    end

    def dispersion
      expectation * (1 - (votes.to_f / (participants * range))) if participants != 0
    end

    def probability
      votes_count.to_f / participants_count
    end

    def confidence_interval
      p = probability and n = participants_count
      (p-(1.96 * Math.sqrt((p*(1-p)) / n)))..(p+(1.96 * Math.sqrt((p*(1-p)) / n)))
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
      if self.is_leaf?
        @redis_key ||=
          begin
            key = ""
            target_node = self
            while(target_node.parent) do
              key.insert(0, ".#{target_node.key_pair}")
              target_node = target_node.parent
            end
            "#{target_node.name}#{key}"
          end
      end
    end

    def key_pair
      "#{content}:#{name}"
    end

    private

    def normalization_range
      @_scale ? (@_scale.to_f / participants_count) : 1
    end
    alias :range :normalization_range

    def redis
      Rightchoice.redis
    end
  end
end
