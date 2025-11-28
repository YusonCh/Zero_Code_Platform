#!/bin/bash

# 零代码平台环境检查脚本
# 使用方法：./check-env.sh

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   零代码平台环境检查${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查结果统计
PASS=0
FAIL=0
WARN=0

# 检查函数
check_cmd() {
    local cmd=$1
    local name=$2
    local version_cmd=$3
    
    if command -v $cmd &> /dev/null; then
        local version=""
        if [ -n "$version_cmd" ]; then
            version=$($version_cmd 2>&1 | head -1)
        fi
        echo -e "${GREEN}✓${NC} $name: $version"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $name: 未安装"
        ((FAIL++))
        return 1
    fi
}

check_version() {
    local cmd=$1
    local name=$2
    local min_version=$3
    local current_version=$4
    
    if [ -n "$current_version" ]; then
        echo -e "${GREEN}✓${NC} $name: $current_version (要求: $min_version+)"
        ((PASS++))
    else
        echo -e "${YELLOW}⚠${NC} $name: 无法获取版本信息"
        ((WARN++))
    fi
}

# 1. 检查必需环境
echo -e "${BLUE}[1] 检查必需环境${NC}"
echo "----------------------------------------"

check_cmd "java" "JDK" "java -version"
check_cmd "mvn" "Maven" "mvn -v"
check_cmd "node" "Node.js" "node -v"
check_cmd "npm" "npm" "npm -v"
check_cmd "mysql" "MySQL" "mysql --version"
check_cmd "redis-cli" "Redis" "redis-cli --version"

echo ""

# 2. 检查环境变量
echo -e "${BLUE}[2] 检查环境变量${NC}"
echo "----------------------------------------"

check_env_var() {
    local var=$1
    local name=$2
    local required=$3
    
    if [ -n "${!var}" ]; then
        # 隐藏敏感信息的显示
        local display_value="已配置"
        if [ "$var" = "DB_PASSWORD" ] || [ "$var" = "REDIS_PASSWORD" ] || [[ "$var" == *"API_KEY"* ]]; then
            display_value="已配置（已隐藏）"
        fi
        echo -e "${GREEN}✓${NC} $name ($var): $display_value"
        ((PASS++))
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC} $name ($var): 未配置 (必需)"
            ((FAIL++))
            return 1
        else
            echo -e "${YELLOW}⚠${NC} $name ($var): 未配置 (可选)"
            ((WARN++))
            return 0
        fi
    fi
}

check_env_var "DB_PASSWORD" "MySQL 密码" "true"
check_env_var "DB_USERNAME" "MySQL 用户名" "false"
check_env_var "DEEPSEEK_API_KEY" "DeepSeek API Key" "true"
check_env_var "ALIBABA_DASHSCOPE_API_KEY" "阿里云 DashScope API Key" "false"
check_env_var "REDIS_PASSWORD" "Redis 密码" "false"
check_env_var "PEXELS_API_KEY" "Pexels API Key" "false"

echo ""

# 3. 检查服务连接
echo -e "${BLUE}[3] 检查服务连接${NC}"
echo "----------------------------------------"

# 检查 MySQL
if [ -n "$DB_PASSWORD" ]; then
    if mysql -u root -p"$DB_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} MySQL 连接: 成功"
        ((PASS++))
        
        # 检查数据库是否存在
        if mysql -u root -p"$DB_PASSWORD" -e "USE zero_code_platform; SELECT 1" > /dev/null 2>&1; then
            table_count=$(mysql -u root -p"$DB_PASSWORD" -e "USE zero_code_platform; SHOW TABLES;" 2>/dev/null | wc -l | tr -d ' ')
            if [ -n "$table_count" ] && [ "$table_count" -ge 4 ]; then  # 至少3个表 + 标题行
                echo -e "${GREEN}✓${NC} 数据库 zero_code_platform: 已创建并包含表结构"
                ((PASS++))
            else
                echo -e "${YELLOW}⚠${NC} 数据库 zero_code_platform: 已创建但表结构可能不完整"
                ((WARN++))
            fi
        else
            echo -e "${YELLOW}⚠${NC} 数据库 zero_code_platform: 未创建，请执行 sql/create_table.sql"
            ((WARN++))
        fi
    else
        echo -e "${RED}✗${NC} MySQL 连接: 失败（请检查密码和服务状态）"
        ((FAIL++))
    fi
else
    echo -e "${YELLOW}⚠${NC} MySQL 连接: 跳过（DB_PASSWORD 未配置）"
    ((WARN++))
fi

# 检查 Redis
if redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Redis 连接: 成功"
    ((PASS++))
else
    echo -e "${RED}✗${NC} Redis 连接: 失败（请检查服务是否运行）"
    ((FAIL++))
fi

echo ""

# 4. 检查项目文件
echo -e "${BLUE}[4] 检查项目文件${NC}"
echo "----------------------------------------"

check_file() {
    local file=$1
    local name=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $name: 存在"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $name: 不存在 ($file)"
        ((FAIL++))
        return 1
    fi
}

check_file "pom.xml" "后端配置文件 (pom.xml)"
check_file "src/main/resources/application.yml" "后端配置文件 (application.yml)"
check_file "frontend/package.json" "前端配置文件 (package.json)"
check_file "frontend/vite.config.ts" "前端配置文件 (vite.config.ts)"
check_file "sql/create_table.sql" "数据库初始化脚本"

# 检查前端 .env 文件
if [ -f "frontend/.env.local" ]; then
    echo -e "${GREEN}✓${NC} 前端环境配置文件 (.env.local): 存在"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} 前端环境配置文件 (.env.local): 不存在（可选，默认使用硬编码配置）"
    ((WARN++))
fi

echo ""

# 5. 总结
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   检查总结${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ 通过: $PASS${NC}"
echo -e "${YELLOW}⚠ 警告: $WARN${NC}"
echo -e "${RED}✗ 失败: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ 环境检查完成，所有必需项都已配置！${NC}"
    echo ""
    echo "下一步："
    echo "  1. 启动后端: ./start.sh 或 mvn spring-boot:run"
    echo "  2. 启动前端: cd frontend && npm install && npm run dev"
    exit 0
else
    echo -e "${RED}✗ 环境检查失败，请修复上述问题后重新检查${NC}"
    exit 1
fi

