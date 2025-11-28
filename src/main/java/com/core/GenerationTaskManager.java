package com.core;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 简单的任务去重管理器，避免同一应用并发触发多次代码生成。
 */
@Component
@Slf4j
public class GenerationTaskManager {

    private final Map<Long, Long> runningTasks = new ConcurrentHashMap<>();

    /**
     * 尝试为指定 appId 开始任务，如果已经存在则返回 false。
     *
     * @param appId 应用 ID
     * @return 是否成功占用任务槽位
     */
    public boolean tryStart(long appId) {
        Long previous = runningTasks.putIfAbsent(appId, System.currentTimeMillis());
        if (previous == null) {
            log.debug("开始执行应用 {} 的生成任务", appId);
            return true;
        }
        log.warn("应用 {} 已有生成任务在运行，开始时间：{}", appId, previous);
        return false;
    }

    /**
     * 结束指定 appId 的任务。
     *
     * @param appId 应用 ID
     */
    public void finish(long appId) {
        Long startTime = runningTasks.remove(appId);
        if (startTime != null) {
            long duration = System.currentTimeMillis() - startTime;
            log.debug("应用 {} 的生成任务结束，耗时 {} ms", appId, duration);
        }
    }

    /**
     * 当前应用是否已有任务在运行。
     */
    public boolean isRunning(long appId) {
        return runningTasks.containsKey(appId);
    }
}

