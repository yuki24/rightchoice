require 'sinatra/base'
require 'rightchoice'
require 'bigdecimal'

module Rightchoice
  class Dashboard < Sinatra::Base
    dir = File.dirname(File.expand_path(__FILE__))

    set :views,  "#{dir}/dashboard/views"
    set :public_folder, "#{dir}/dashboard/public"
    set :static, true
    set :method_override, true

    helpers do
      def url(*path_parts)
        [ path_prefix, path_parts ].join("/").squeeze('/')
      end

      def equation_for_graph(expectation, dispersion)
        "(1/Math.sqrt(2 * Math.PI * #{dispersion})) * Math.exp(Math.pow(x-#{expectation},2)/-(2 * #{dispersion}))"
      end

      def path_prefix
        request.env['SCRIPT_NAME']
      end
    end

    # shows all the multivariate tests
    get '/' do
      @multi_variations = Rightchoice::MultiVariations.all

      # we want something like this?
      # @multi_variations.each do |test|
      #   test.variations.each do |variation|
      #     variation.alternatives
      #   end
      # end
      erb :index
    end

    # shows the detail of the multivariate test
    get '/multivariate_tests/:multivariate_test' do
      @calculator = Rightchoice::Calculator.new(params[:multivariate_test])
      erb :show
    end

    # manually calculates 
    post '/multivariate_tests/:multivariate_test/calculate' do
      Rightchoice::Calculator.new(params[:multivariate_test]).disable_ineffective_nodes!
      redirect url("/multivariate_tests/#{params[:multivariate_test]}")
    end

    get '/flushall' do
      Rightchoice.redis.flushall
      redirect url("/")
    end
  end
end
