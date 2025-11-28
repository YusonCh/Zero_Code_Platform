package com.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.cache.CacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;
import org.springframework.lang.NonNull;

import java.time.Duration;
import java.util.Objects;

/**
 * Redis 缓存管理器配置
 */
@Configuration
public class RedisCacheManagerConfig {

    private final RedisConnectionFactory redisConnectionFactory;

    public RedisCacheManagerConfig(@NonNull RedisConnectionFactory redisConnectionFactory) {
        this.redisConnectionFactory = redisConnectionFactory;
    }

    @Bean
    public CacheManager cacheManager() {
        // 确保 redisConnectionFactory 不为 null
        RedisConnectionFactory factory = Objects.requireNonNull(redisConnectionFactory, 
                "RedisConnectionFactory must not be null");
        
        // 配置 ObjectMapper 支持 Java8 时间类型
        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.registerModule(new JavaTimeModule());

        // 默认配置
        Duration defaultTtl = Objects.requireNonNull(Duration.ofMinutes(30));
        RedisCacheConfiguration defaultConfig = RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(defaultTtl) // 默认 30 分钟过期
                .disableCachingNullValues() // 禁用 null 值缓存
                // key 使用 String 序列化器
                .serializeKeysWith(RedisSerializationContext.SerializationPair
                        .fromSerializer(new StringRedisSerializer()));
//                // value 使用 JSON 序列化器（支持复杂对象）但是要注意开启后需要给序列化增加默认类型配置，否则无法反序列化
//                .serializeValuesWith(RedisSerializationContext.SerializationPair
//                        .fromSerializer(new GenericJackson2JsonRedisSerializer(objectMapper)));

        Duration goodAppPageTtl = Objects.requireNonNull(Duration.ofMinutes(5));
        return RedisCacheManager.builder(factory)
                .cacheDefaults(defaultConfig)
                // 针对 good_app_page 配置5分钟过期
                .withCacheConfiguration("good_app_page",
                        defaultConfig.entryTtl(goodAppPageTtl))
                .build();
    }
} 