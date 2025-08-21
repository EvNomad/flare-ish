class RedisLock
  def self.acquire(key, value, ttl: 30)
    REDIS.set(key, value, nx: true, ex: ttl)
  end

  def self.get(key) = REDIS.get(key)

  def self.release(key) = REDIS.del(key)

  def self.with_lock(key, value, ttl: 30)
    if acquire(key, value, ttl: ttl)
  end
end
