-- 插入精选应用数据 (Priority = 99)
-- 请确保 userId = 1 的用户存在，或者修改为存在的 userId

-- 1. 精选 HTML 项目
INSERT INTO app (id, appName, initPrompt, codeGenType, priority, userId, appStatus, createTime, updateTime, isDelete)
VALUES (1859000000000000001, '精选 HTML 落地页', '这是一个精选的单页 HTML 落地页示例，展示了精美的 UI 设计。', 'html', 99, 1, 0, NOW(), NOW(), 0);

-- 2. 精选多文件项目
INSERT INTO app (id, appName, initPrompt, codeGenType, priority, userId, appStatus, createTime, updateTime, isDelete)
VALUES (1859000000000000002, '精选多文件博客', '这是一个多文件结构的博客项目，包含独立的 HTML、CSS 和 JS 文件。', 'multi_file', 99, 1, 0, NOW(), NOW(), 0);

-- 3. 精选 Vue 项目
INSERT INTO app (id, appName, initPrompt, codeGenType, priority, userId, appStatus, createTime, updateTime, isDelete)
VALUES (1859000000000000003, '精选 Vue 任务管理', '这是一个基于 Vue 3 的任务管理系统，支持任务的增删改查。', 'vue_project', 99, 1, 0, NOW(), NOW(), 0);

