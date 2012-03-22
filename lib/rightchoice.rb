require 'json'
require 'redis/namespace'
require 'rightchoice/dashboard'
require 'rightchoice/models/multivariate_test'
require 'rightchoice/calculator'
require 'rightchoice/railtie'

module Rightchoice
  extend self

  # Accepts:
  #   1. A 'hostname:port' String
  #   2. A 'hostname:port:db' String (to select the Redis db)
  #   3. A 'hostname:port/namespace' String (to set the Redis namespace)
  #   4. A Redis URL String 'redis://host:port'
  #   5. An instance of `Redis`, `Redis::Client`, `Redis::DistRedis`,
  #      or `Redis::Namespace`.
  def redis=(server)
    case server
    when String
      if server =~ /redis\:\/\//
        redis = Redis.connect(url: server, thread_safe: true)
      else
        server, namespace = server.split('/', 2)
        host, port, db = server.split(':')
        redis = Redis.new(host: host, port: port, thread_safe: true, db: db)
      end
      namespace ||= :rightchoice

      @redis = Redis::Namespace.new(namespace, redis: redis)
    when Redis::Namespace
      @redis = server
    else
      @redis = Redis::Namespace.new(:rightchoice, redis: server)
    end
  end

  # Returns the current Redis connection. If none has been created, will
  # create a new one.
  def redis
    return @redis if @redis
    self.redis = Redis.respond_to?(:connect) ? Redis.connect : "localhost:6379"
  end

  def redis_id
    # support 1.x versions of redis-rb
    if redis.respond_to?(:server)
      redis.server
    elsif redis.respond_to?(:nodes) # distributed
      redis.nodes.map { |n| n.id }.join(', ')
    else
      redis.client.id
    end
  end

end
