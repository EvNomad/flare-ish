class RedisLock
  def initialize(provider_time_slot_id, ttl_seconds = 600)
    @key = "lock:#{provider_time_slot_id}"
    @ttl_seconds = ttl_seconds
    @redis = REDIS
  end
  
  def acquire(metadata)
    @redis.set(@key, metadata.to_json, ex: @ttl_seconds, nx: true)
  end
  
  def release
    @redis.del(@key)
  end
  
  def exists?
    @redis.exists?(@key)
  end
  
  def get_metadata
    data = @redis.get(@key)
    data ? JSON.parse(data, symbolize_names: true) : nil
  end
  
  def belongs_to?(account_id)
    metadata = get_metadata
    metadata && metadata[:account_id] == account_id
  end
  
  def extend_ttl
    @redis.expire(@key, @ttl_seconds)
  end
end
