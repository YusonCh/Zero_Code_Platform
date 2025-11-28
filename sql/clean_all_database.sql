# 完全清理数据库脚本
# 此脚本将删除所有表的所有数据，包括用户数据

-- 切换库
use zero_code_platform;

-- 关闭外键检查（如果有外键约束）
SET FOREIGN_KEY_CHECKS = 0;

-- 删除对话历史表数据（先删除依赖表）
TRUNCATE TABLE chat_history;

-- 删除应用表数据
TRUNCATE TABLE app;

-- 删除用户表数据
TRUNCATE TABLE user;

-- 重新开启外键检查
SET FOREIGN_KEY_CHECKS = 1;

-- 显示清理结果
SELECT '数据库完全清理完成，所有表数据已清空' AS message;
SELECT COUNT(*) AS user_count FROM user;
SELECT COUNT(*) AS app_count FROM app;
SELECT COUNT(*) AS chat_history_count FROM chat_history;

