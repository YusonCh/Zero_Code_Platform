#!/bin/bash

# 数据库清理脚本
# 此脚本将删除除 user 表之外的所有数据，仅保留用户信息

# 从环境变量或配置文件读取数据库配置
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_USERNAME=${DB_USERNAME:-root}
DB_PASSWORD=${DB_PASSWORD:-}
DB_NAME=${DB_NAME:-zero_code_platform}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="$SCRIPT_DIR/clean_database.sql"

echo "=========================================="
echo "数据库清理脚本"
echo "=========================================="
echo "数据库: $DB_NAME"
echo "主机: $DB_HOST:$DB_PORT"
echo "用户: $DB_USERNAME"
echo ""
echo "警告: 此操作将删除 app 和 chat_history 表的所有数据！"
echo "仅保留 user 表的数据。"
echo "=========================================="
read -p "确认继续? (yes/no): " confirm

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
    echo "数据库清理完成！"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "数据库清理失败，请检查错误信息"
    echo "=========================================="
    exit 1
fi

