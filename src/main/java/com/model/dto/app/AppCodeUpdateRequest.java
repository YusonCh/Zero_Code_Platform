package com.model.dto.app;

import lombok.Data;

import java.io.Serializable;

/**
 * 更新应用代码请求
 */
@Data
public class AppCodeUpdateRequest implements Serializable {

    /**
     * 应用 ID
     */
    private Long id;

    /**
     * 代码内容（通常是单个文件的内容，如 HTML）
     */
    private String codeContent;

    private static final long serialVersionUID = 1L;
}

