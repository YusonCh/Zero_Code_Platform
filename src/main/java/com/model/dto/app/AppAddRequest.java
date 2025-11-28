package com.model.dto.app;

import lombok.Data;

import java.io.Serializable;

/**
 * 应用创建请求
 */
@Data
public class AppAddRequest implements Serializable {

    /**
     * 应用初始化的 prompt
     */
    private String initPrompt;

    /**
     * 代码生成类型（可选，如果未传入则由 AI 自动选择）
     */
    private String codeGenType;

    private static final long serialVersionUID = 1L;
} 