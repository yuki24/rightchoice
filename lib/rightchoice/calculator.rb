require 'tree'
require 'rightchoice/calculators/alternative_node'

module Rightchoice
  class Calculator
    attr_accessor :factors, :root_node

    def initialize(multivariate_test)
      @mv_test = MultivariateTest.find(multivariate_test)
      @root_node = AlternativeNode.new(multivariate_test, "Root")
      build_tree!
    end

    def factors
      @factors ||= @mv_test.factors
    end

    def max_participants
      leafs.map{|l| l.participants_count }.max
    end

    def finished?
      leafs.map{|l| l.available? ? 1 : 0 }.reduce(:+) == 1
    end

    def disable_ineffective_nodes!
      ls = sorted_leafs
      best_choice = ls.pop
      leafs.each do |l|
        l.disable! if l.confidence_interval.last < best_choice.confidence_interval.first
      end
    end

    def build_tree!
      factors.each do |factor|
        leafs.each do |leaf|
          factor.alternatives.each do |alt|
            leaf << AlternativeNode.new(alt, factor.name)
          end
        end
      end
    end

    def leafs
      [].tap do |l|
        @root_node.each_leaf{|leaf| l << leaf }
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
