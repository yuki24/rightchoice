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
      @variations = @variations.map do |variation|
        Variation.new(variation, *JSON(Rightchoice.redis.hget("all_tests", variation)))
      end
      @root_node = AlternativeNode.new(multivariate_test, "Root")
      build_tree!
    end

    def max_participants
      leafs = [] and @root_node.each_leaf{|leaf| leafs << leaf }
      leafs.map{|l| l.participants_count }.max
    end

    def build_tree!
      @variations.each do |variation|
        leafs = [] and @root_node.each_leaf{|leaf| leafs << leaf }

        leafs.each do |leaf|
          variation.alternatives.each do |alternative|
            leaf << AlternativeNode.new(alternative, variation.name)
          end
        end
      end
    end

  end
end
