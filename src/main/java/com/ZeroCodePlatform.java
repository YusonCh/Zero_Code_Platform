package com;

import dev.langchain4j.community.store.embedding.redis.spring.RedisEmbeddingStoreAutoConfiguration;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.ComponentScan;

@EnableCaching
@SpringBootApplication(exclude = {RedisEmbeddingStoreAutoConfiguration.class})
@ComponentScan(basePackages = {"com", "com.zerocodeplatform"})
public class ZeroCodePlatform {

    public static void main(String[] args) {
        SpringApplication.run(ZeroCodePlatform.class, args);
    }

}
