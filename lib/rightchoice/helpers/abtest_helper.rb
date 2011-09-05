module Rightchoice
  # = Helpers
  module AbtestHelper
    def ab_test(experiment_name, *alternatives)
      experiment = Rightchoice::Experiment.find_or_create(experiment_name, *alternatives)
      if experiment.winner
        ret = experiment.winner.name
      else
        if forced_alternative = override(experiment.key, alternatives)
          ret = forced_alternative
        else
          begin_experiment(experiment, experiment.control.name) if exclude_visitor?

          if ab_user[experiment.key]
            ret = ab_user[experiment.key]
          else
            alternative = experiment.next_alternative
            alternative.increment_participation
            begin_experiment(experiment, alternative.name)
            ret = alternative.name
          end
        end
      end

      if block_given?
        if defined?(capture) # a block in a rails view
          block = Proc.new { yield(ret) }
          concat(capture(ret, &block))
          false
        else
           yield(ret)
        end
      else
        ret
      end
    end

    def finished(experiment_name, options = {:reset => true})
      return if exclude_visitor?
      experiment = Rightchoice::Experiment.find(experiment_name)
      if alternative_name = ab_user[experiment.key]
        alternative = Rightchoice::Alternative.find(alternative_name, experiment_name)
        alternative.increment_completion
        session[:split].delete(experiment_name) if options[:reset]
      end
    end

    def override(experiment_name, alternatives)
      return params[experiment_name] if defined?(params) && alternatives.include?(params[experiment_name])
    end

    def begin_experiment(experiment, alternative_name)
      ab_user[experiment.key] = alternative_name
    end

    def ab_user
      session[:split] ||= {}
    end

    def exclude_visitor?
      is_robot? or is_ignored_ip_address?
    end

    def is_robot?
      request.user_agent =~ Rightchoice.configuration.robot_regex
    end

    def is_ignored_ip_address?
      if Rightchoice.configuration.ignore_ip_addresses.any?
        Rightchoice.configuration.ignore_ip_addresses.include?(request.ip)
      else
        false
      end
    end
=begin
    extend ::ActiveSupport::Concern
    module InstanceMethods
      def ab_test
      end

      private

    end
=end
  end
end
