module Rightchoice
  module ViewHelper

    def select_variation(test_name, variation_name, *alternatives)
      if participated_before?(test_name)
        choice = multivariate_test(test_name).variations.find(variation_name).choice
      else
        variation = Rightchoice::Variation.find_or_create(variation_name, *alternatives)
        multivariate_test(test_name).variations << variation
        choice = variation.choice
      end

      if block_given?
        if defined?(capture)
          block = Proc.new { yield(choice) }
          concat(capture(choice, &block))
        else
          yield(choice)
        end
      else
        choice
      end
    end

    private

    def participated_before?(test_name)
      !multivariate_tests[test_name].nil?
    end

    def multivariate_test(name)
      multivariate_tests[name] ||= Rightchoice::MultiVariations.find_or_create(name)
    end

    def multivariate_tests
      session[:multivariate_tests] ||= {}
    end

  end
end
