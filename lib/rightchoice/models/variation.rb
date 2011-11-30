module Rightchoice
  class Variation
    attr_accessor :name, :alternatives
    attr_reader :child, :parent

    def initialize(variation_name, *alternatives)
      options = alternatives.pop if alternatives.last.is_a?(Hash)
      @name = variation_name.to_s
      @alternatives = alternatives

      if options
        @choice = @alternatives.detect{|name| name == options[:choice] }
        redis.hset("all_tests", variation_name.to_s, @alternatives.to_json) if options[:persist] == true
      end
    end

    def choice
      @choice ||= random_select
    end

    def child=(variation)
      # some validations should be add
      # - variations can not have themeselves as a child
      # - child can not be a parent
      unless self.end?
        @child = variation
        variation.add_parent(self)
        variation
      end
    end

    def parent=(variation)
      # some validations should be add
      # - variations can not have themeselves as a parent
      # - parent can not be a child
      unless self.root?
        @parent = variation
        variation.add_child(self)
        variation
      end
    end

    def add_parent(variation)
      @parent = variation
    end

    def add_child(variation)
      @child = variation
    end

    def root!
      @_root = true
    end

    def end!
      @_end = true
    end

    def root?
      @_root == true
    end

    def end?
      @_end == true
    end

    class << self
      def find_or_create(variation_name, *alternatives)
        unless redis.hexists("all_tests", variation_name.to_s)
          new(variation_name, *alternatives, :persist => true)
        else
          new(variation_name, *alternatives)
        end
      end
    end

    private

    def self.redis
      @@_redis ||= Rightchoice.redis
    end

    def redis
      @_redis ||= Rightchoice.redis
    end

    def random_select
      alternatives.sample
    end
  end
end
