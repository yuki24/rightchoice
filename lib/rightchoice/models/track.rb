module Rightchoice
  class Track
    attr_accessor :name

    def initialize(name, options={})
      @alternatives = {}

      case options
      when Integer
        @alternatives[:ab_test] = options
      when Hash
        @alternatives = options
      else
        raise AugumentError.new, "invalid augument given."
      end

      @finished = false
    end

    def alternative(experiment_name=nil)
      @alternatives[(experiment_name || @alternatives.keys.first)]
    end

    def finish!
      @finished = true
    end

    def finished?
      @finished
    end
  end
end
