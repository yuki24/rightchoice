module Rightchoice
  class Variation
    attr_accessor :name, :alternatives

    def initialize(variation_name, *alternatives)
      options = alternatives.pop if alternatives.last.is_a?(Hash)
      @name = variation_name.to_s
      @alternatives = alternatives

      if options
        @choice = @alternatives.detect{|name| name == options[:choice] }
      end
    end

    def choice
      @choice ||= random_select
    end

    private

    def random_select
      alternatives.sample
    end
  end
end
