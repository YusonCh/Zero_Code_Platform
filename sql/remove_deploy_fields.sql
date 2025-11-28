-- 删除部署相关字段的迁移脚本
-- 执行此脚本将删除 app 表中的 deployKey 和 deployedTime 字段

USE zero_code_platform;

-- 删除 deployKey 的唯一索引（如果存在）
SET @index_exists = (SELECT COUNT(*) FROM information_schema.statistics 
    WHERE table_schema = 'zero_code_platform' 
    AND table_name = 'app' 
    AND index_name = 'uk_deployKey');

SET @sql = IF(@index_exists > 0, 'ALTER TABLE app DROP INDEX uk_deployKey', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 删除 deployKey 字段（如果存在）
SET @column_exists = (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_schema = 'zero_code_platform' 
    AND table_name = 'app' 
    AND column_name = 'deployKey');

SET @sql = IF(@column_exists > 0, 'ALTER TABLE app DROP COLUMN deployKey', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 删除 deployedTime 字段（如果存在）
SET @column_exists = (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_schema = 'zero_code_platform' 
    AND table_name = 'app' 
    AND column_name = 'deployedTime');

SET @sql = IF(@column_exists > 0, 'ALTER TABLE app DROP COLUMN deployedTime', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 验证字段是否已删除
DESC app;

