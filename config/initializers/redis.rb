require 'redis'
REDIS_HOST = ENV['REDIS_HOST'] || '127.0.0.1'
REDIS_PORT = ENV['REDIS_PORT'] || '6379'
Redis.current = Redis.new(host: REDIS_HOST, port: REDIS_PORT.to_i)
