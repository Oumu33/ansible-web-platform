#!/bin/bash

# Ansible Web管理平台 - 快速启动脚本
# Author: Ansible Web Platform Team
# License: MIT

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if netstat -tuln | grep ":$port " > /dev/null; then
        return 0
    else
        return 1
    fi
}

# 等待服务启动
wait_for_service() {
    local url=$1
    local max_attempts=30
    local attempt=0
    
    log_info "等待服务启动: $url"
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
        echo -n "."
    done
    echo
    return 1
}

# 主函数
main() {
    echo "=================================================="
    echo "🚀 Ansible Web管理平台 - 快速启动"
    echo "=================================================="
    echo
    
    # 检查系统要求
    log_info "检查系统要求..."
    
    # 检查Python
    if ! command_exists python3; then
        log_error "Python 3 未安装，请先安装 Python 3.7+"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    log_info "检测到 Python版本: $PYTHON_VERSION"
    
    # 检查Node.js
    if ! command_exists node; then
        log_error "Node.js 未安装，请先安装 Node.js 16+"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    log_info "检测到 Node.js版本: $NODE_VERSION"
    
    # 检查端口占用
    if check_port 8000; then
        log_warning "端口 8000 已被占用，后端可能无法启动"
    fi
    
    if check_port 3000; then
        log_warning "端口 3000 已被占用，前端可能无法启动"
    fi
    
    echo
    
    # 安装依赖
    log_info "安装项目依赖..."
    
    # 安装根目录依赖
    if [ -f "package.json" ]; then
        log_info "安装根目录 Node.js 依赖..."
        npm install --silent
    fi
    
    # 安装后端依赖
    if [ -f "backend/requirements.txt" ]; then
        log_info "安装后端 Python 依赖..."
        cd backend
        
        # 创建虚拟环境（如果不存在）
        if [ ! -d "venv" ]; then
            log_info "创建 Python 虚拟环境..."
            python3 -m venv venv
        fi
        
        # 激活虚拟环境
        source venv/bin/activate
        
        # 升级pip
        pip install --upgrade pip --quiet
        
        # 安装依赖
        pip install -r requirements.txt --quiet
        
        cd ..
        
        log_success "后端依赖安装完成"
    fi
    
    # 安装前端依赖
    if [ -f "frontend/package.json" ]; then
        log_info "安装前端 Node.js 依赖..."
        cd frontend
        npm install --silent
        cd ..
        log_success "前端依赖安装完成"
    fi
    
    echo
    
    # 初始化数据库
    log_info "初始化数据库..."
    if [ -f "backend/scripts/init_db.py" ]; then
        cd backend
        source venv/bin/activate
        python scripts/init_db.py
        cd ..
        log_success "数据库初始化完成"
    fi
    
    echo
    
    # 启动服务
    log_info "启动服务..."
    
    # 启动后端
    log_info "启动后端服务 (端口: 8000)..."
    cd backend
    source venv/bin/activate
    nohup python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > ../logs/backend.log 2>&1 &
    BACKEND_PID=$!
    cd ..
    
    # 等待后端启动
    if wait_for_service "http://localhost:8000/health"; then
        log_success "后端服务启动成功 (PID: $BACKEND_PID)"
    else
        log_error "后端服务启动失败"
        kill $BACKEND_PID 2>/dev/null || true
        exit 1
    fi
    
    # 启动前端
    log_info "启动前端服务 (端口: 3000)..."
    cd frontend
    nohup npm run dev > ../logs/frontend.log 2>&1 &
    FRONTEND_PID=$!
    cd ..
    
    # 等待前端启动
    sleep 5
    if wait_for_service "http://localhost:3000"; then
        log_success "前端服务启动成功 (PID: $FRONTEND_PID)"
    else
        log_error "前端服务启动失败"
        kill $FRONTEND_PID 2>/dev/null || true
        kill $BACKEND_PID 2>/dev/null || true
        exit 1
    fi
    
    # 保存PID到文件
    mkdir -p .pids
    echo $BACKEND_PID > .pids/backend.pid
    echo $FRONTEND_PID > .pids/frontend.pid
    
    echo
    echo "=================================================="
    log_success "🎉 Ansible Web管理平台启动成功！"
    echo "=================================================="
    echo
    echo "📋 服务信息:"
    echo "   🌐 Web界面:     http://localhost:3000"
    echo "   🔧 API接口:     http://localhost:8000"
    echo "   📊 API文档:     http://localhost:8000/docs"
    echo "   💚 健康检查:    http://localhost:8000/health"
    echo
    echo "👤 默认账户:"
    echo "   用户名: admin"
    echo "   密码:   admin123"
    echo "   ⚠️  首次登录后请立即修改密码！"
    echo
    echo "📋 服务管理:"
    echo "   停止服务: ./stop.sh"
    echo "   查看日志: tail -f logs/backend.log"
    echo "   查看日志: tail -f logs/frontend.log"
    echo
    echo "📞 获取帮助:"
    echo "   📖 用户手册: https://github.com/Oumu33/ansible-web-platform#readme"
    echo "   🐛 问题反馈: https://github.com/Oumu33/ansible-web-platform/issues"
    echo
    log_info "按 Ctrl+C 停止所有服务"
    
    # 等待用户中断
    trap 'log_info "正在停止服务..."; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true; rm -f .pids/*.pid; log_success "服务已停止"; exit 0' INT
    
    # 监控服务状态
    while true; do
        if ! kill -0 $BACKEND_PID 2>/dev/null; then
            log_error "后端服务意外停止"
            break
        fi
        if ! kill -0 $FRONTEND_PID 2>/dev/null; then
            log_error "前端服务意外停止"
            break
        fi
        sleep 5
    done
}

# 创建日志目录
mkdir -p logs

# 运行主函数
main "$@"