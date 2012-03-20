require 'active_support/concern'

module Rightchoice
  module ViewHelper
    extend ActiveSupport::Concern

    included do
      before_filter :check_availability!
      after_filter :participate!
    end

    module InstanceMethods
      def select_variation(test_name, factor_name, *alternatives)
        session[:_rightchoice_testname] = test_name
        if participated_before?(test_name, factor_name)
          choice = multivariate_test(test_name).factors.find(factor_name).choice
        else
          factor = Rightchoice::Factor.new(factor_name, *alternatives)
          multivariate_test(test_name).factors << factor
          choice = factor.choice
        end

        if block_given?
          # if defined?(capture)
          #   block = Proc.new { yield(choice) }
          #   concat(capture(choice, &block))
          # else
            yield(choice)
          # end
        else
          choice
        end
      end

      def finish!(test_name)
        multivariate_test(test_name).vote! unless multivariate_test(test_name).already_voted?
      end

      # before filter
      def check_availability!
        multivariate_tests.each do |test_name, mv|
          reselect!(test_name) unless available?(test_name)
        end
      end

      # after filter
      def participate!
        testname = session[:_rightchoice_testname]
        if testname && !multivariate_test(testname).already_participated?
          multivariate_test(testname).participate!
          if Rightchoice.redis.hget(multivariate_test(testname).redis_key, "participants_count") == "100"
            Rightchoice::Calculator.new(testname).disable_ineffective_nodes!
          end
        end
      end

      private

      def available?(test_name)
        multivariate_tests[test_name] && multivariate_tests[test_name].available?
      end

      def reselect!(test_name)
        multivariate_test(test_name).flush_choices! while(!available?(test_name))
      end

      def has_multivariate_test?(test_name)
        !multivariate_tests[test_name].nil?
      end

      def has_variation?(test_name, factor_name)
        has_multivariate_test?(test_name) && !multivariate_test(test_name).factors.find(factor_name).nil?
      end
      alias :participated_before? :has_variation?

      def multivariate_test(name)
        multivariate_tests[name] ||= Rightchoice::MultivariateTest.find_or_create(name)
      end

      def multivariate_tests
        session[:multivariate_tests] ||= {}
      end
    end
  end
end
