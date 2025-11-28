# 清理数据库脚本
# 此脚本将删除除 user 表之外的所有数据，仅保留用户信息

-- 切换库
use zero_code_platform;

-- 关闭外键检查（如果有外键约束）
SET FOREIGN_KEY_CHECKS = 0;

-- 删除对话历史表数据（先删除依赖表）
TRUNCATE TABLE chat_history;

-- 删除应用表数据
TRUNCATE TABLE app;

-- 重新开启外键检查
SET FOREIGN_KEY_CHECKS = 1;

-- 显示清理结果
SELECT '数据库清理完成，仅保留 user 表数据' AS message;
SELECT COUNT(*) AS user_count FROM user;
SELECT COUNT(*) AS app_count FROM app;
SELECT COUNT(*) AS chat_history_count FROM chat_history;

