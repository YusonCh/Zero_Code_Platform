#!/bin/bash

# 完全清理数据库脚本
# 此脚本将删除所有表的所有数据，包括用户数据

# 从环境变量或配置文件读取数据库配置
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_USERNAME=${DB_USERNAME:-root}
DB_PASSWORD=${DB_PASSWORD:-}
DB_NAME=${DB_NAME:-zero_code_platform}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="$SCRIPT_DIR/clean_all_database.sql"

echo "=========================================="
echo "数据库完全清理脚本"
echo "=========================================="
echo "数据库: $DB_NAME"
echo "主机: $DB_HOST:$DB_PORT"
echo "用户: $DB_USERNAME"
echo ""
echo "⚠️  警告: 此操作将删除所有表的所有数据！"
echo "⚠️  包括: user、app、chat_history 表的所有数据！"
echo "⚠️  此操作不可恢复！"
echo "=========================================="
read -p "确认继续? (输入 'yes' 继续): " confirm

if [ "$confirm" != "yes" ]; then
    echo "操作已取消"
    exit 0
fi

# 执行 SQL 脚本
if [ -z "$DB_PASSWORD" ]; then
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" "$DB_NAME" < "$SQL_FILE"
else
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" < "$SQL_FILE"
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 数据库完全清理完成！"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "❌ 数据库清理失败，请检查错误信息"
    echo "=========================================="
    exit 1
fi

