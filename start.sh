#!/bin/bash

# 零代码平台启动脚本
# 使用方法：./start.sh

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   零代码平台启动脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查环境变量
if [ -z "$DB_PASSWORD" ]; then
    echo -e "${YELLOW}⚠️  未检测到 DB_PASSWORD 环境变量${NC}"
    echo -e "${YELLOW}请选择设置方式：${NC}"
    echo "1. 从 .zshrc 加载（如果已配置）"
    echo "2. 临时设置（仅本次会话有效）"
    echo "3. 退出并手动配置"
    read -p "请选择 (1/2/3): " choice
    
    case $choice in
        1)
            echo "正在从 .zshrc 加载环境变量..."
            source ~/.zshrc 2>/dev/null
            if [ -z "$DB_PASSWORD" ]; then
                echo -e "${RED}❌ .zshrc 中未找到 DB_PASSWORD，请先配置${NC}"
                exit 1
            fi
            ;;
        2)
            read -sp "请输入 MySQL root 密码: " DB_PASSWORD
            echo ""
            export DB_PASSWORD
            ;;
        3)
            echo "请先配置环境变量，然后重新运行此脚本"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            exit 1
            ;;
    esac
fi

# 检查其他必需的环境变量
if [ -z "$DEEPSEEK_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  未检测到 DEEPSEEK_API_KEY 环境变量${NC}"
    echo -e "${YELLOW}AI 功能可能无法正常使用${NC}"
fi

echo -e "${GREEN}✓ 环境变量检查完成${NC}"
echo ""

# 检查数据库连接
echo "正在检查 MySQL 连接..."
if mysql -u root -p"$DB_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ MySQL 连接成功${NC}"
else
    echo -e "${RED}❌ MySQL 连接失败，请检查密码是否正确${NC}"
    exit 1
fi

# 检查 Redis
echo "正在检查 Redis 连接..."
if redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Redis 连接成功${NC}"
else
    echo -e "${YELLOW}⚠️  Redis 未运行或连接失败${NC}"
fi

echo ""
echo -e "${GREEN}正在启动后端服务...${NC}"
echo ""

# 切换到项目目录
cd "$(dirname "$0")"

# 创建日志目录
mkdir -p logs

# 清理函数：停止后台进程
cleanup() {
    echo ""
    echo -e "${YELLOW}正在停止服务...${NC}"
    if [ ! -z "$BACKEND_PID" ]; then
        echo "停止后端服务 (PID: $BACKEND_PID)"
        kill $BACKEND_PID 2>/dev/null
        wait $BACKEND_PID 2>/dev/null
    fi
    if [ ! -z "$FRONTEND_PID" ]; then
        echo "停止前端服务 (PID: $FRONTEND_PID)"
        kill $FRONTEND_PID 2>/dev/null
        wait $FRONTEND_PID 2>/dev/null
    fi
    echo -e "${GREEN}服务已停止${NC}"
    exit 0
}

# 注册清理函数
trap cleanup SIGINT SIGTERM

# 检查前端依赖是否已安装
if [ ! -d "frontend/node_modules" ]; then
    echo -e "${YELLOW}⚠️  前端依赖未安装，正在安装...${NC}"
    cd frontend
    npm install
    cd ..
    echo -e "${GREEN}✓ 前端依赖安装完成${NC}"
    echo ""
fi

# 启动后端（后台运行）
echo -e "${GREEN}启动后端服务...${NC}"
./mvnw spring-boot:run > logs/backend.log 2>&1 &
BACKEND_PID=$!

# 等待后端启动（检查端口是否可用）
echo "等待后端启动..."
BACKEND_READY=false
for i in {1..30}; do
    if curl -s http://localhost:8123/api/actuator/health > /dev/null 2>&1 || curl -s http://localhost:8123/api/doc.html > /dev/null 2>&1; then
        BACKEND_READY=true
        break
    fi
    sleep 1
    echo -n "."
done
echo ""

if [ "$BACKEND_READY" = true ]; then
    echo -e "${GREEN}✓ 后端服务启动成功 (PID: $BACKEND_PID)${NC}"
    echo -e "   后端地址: http://localhost:8123"
    echo -e "   API 文档: http://localhost:8123/api/doc.html"
    echo -e "   后端日志: logs/backend.log"
else
    echo -e "${RED}❌ 后端服务启动超时，请检查日志: logs/backend.log${NC}"
    echo -e "${YELLOW}提示: 后端可能仍在启动中，可以手动查看日志${NC}"
fi

echo ""

# 启动前端
echo -e "${GREEN}启动前端服务...${NC}"
cd frontend
npm run dev > ../logs/frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

# 等待前端启动
echo "等待前端启动..."
sleep 3

if ps -p $FRONTEND_PID > /dev/null; then
    echo -e "${GREEN}✓ 前端服务启动成功 (PID: $FRONTEND_PID)${NC}"
    echo -e "   前端地址: http://localhost:5173"
    echo -e "   前端日志: logs/frontend.log"
else
    echo -e "${RED}❌ 前端服务启动失败，请检查日志: logs/frontend.log${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   服务启动完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "前端页面: ${GREEN}http://localhost:5173${NC}"
echo -e "后端 API: ${GREEN}http://localhost:8123/api${NC}"
echo -e "API 文档: ${GREEN}http://localhost:8123/api/doc.html${NC}"
echo ""
echo -e "${YELLOW}提示:${NC}"
echo -e "  - 后端日志: tail -f logs/backend.log"
echo -e "  - 前端日志: tail -f logs/frontend.log"
echo -e "  - 按 Ctrl+C 停止所有服务"
echo ""
echo -e "${GREEN}正在前台显示前端日志（按 Ctrl+C 停止所有服务）...${NC}"
echo ""

# 前台显示前端日志
tail -f logs/frontend.log
