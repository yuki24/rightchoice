module Rightchoice
  # A general Rightchoice exception
  class Error < StandardError; end

  class TestNotFound < Error
    attr_reader :test_name
    attr_writer :default_message

    def initialize(test_name = nil)
      @test_name = test_name
      @default_message = "The test #{test_name} not found."
    end

    def to_s
      @default_message
    end
  end
end
