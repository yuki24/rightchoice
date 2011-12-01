require 'tree'
require 'rightchoice/calculators/alternative_node'

module Rightchoice
  class Calculator
    attr_accessor :variations, :root_node

    def initialize(multivariate_test)
      # @mv_test = MultiVariation.find(multivariate_test)
      # @mv_test.variations
      # @mv_test.variations.first.alternatives
      @variations = JSON(Rightchoice.redis.hget("all_mvtests", multivariate_test))
      @variations = @variations.map do |variation_name|
        Variation.new(variation_name, *JSON(Rightchoice.redis.hget("all_tests", variation_name)))
      end
      @root_node = AlternativeNode.new(multivariate_test, "Root")
      build_tree!
    end

    def max_participants
      leafs.map{|l| l.participants_count }.max
    end

    def disable_ineffective_nodes!
      leafs = sorted_leafs
      best_choice = leafs.pop
      leafs.each do |l|
        l.disable! if l.confidence_interval.last < best_choice.confidence_interval.first
      end
    end

    def build_tree!
      @variations.each do |variation|
        leafs.each do |leaf|
          variation.alternatives.each do |alternative|
            leaf << AlternativeNode.new(alternative, variation.name)
          end
        end
      end
    end

    def leafs
      [].tap do |leafs|
        @root_node.each_leaf{|leaf| leafs << leaf }
      end
    end

    private

    def sorted_leafs
      leafs.clone.tap do |ls|
        ls.sort! {|a,b| a.probability <=> b.probability }
      end
    end
  end
end
