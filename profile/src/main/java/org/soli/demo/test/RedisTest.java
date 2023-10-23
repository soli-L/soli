package org.soli.demo.test;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.test.context.junit4.SpringRunner;

@SpringBootTest
@RunWith(SpringRunner.class)
public class RedisTest {

    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    @Test
    public void TestRedis() {


        String key = "hello";


        redisTemplate.opsForValue().set("hello", "你好");

        String res = redisTemplate.opsForValue().get(key);

        System.out.println(res);

    }
}
