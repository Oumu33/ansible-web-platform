#!/bin/bash

# 快速启动脚本 - 开发/测试环境
# 无需root权限，直接在当前目录运行

set -e

echo "⚡ Ansible Web平台 - 快速启动"
echo "=============================="

# 检查Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 请先安装Python 3.8+"
    exit 1
fi

# 当前目录
CURRENT_DIR=$(pwd)
echo "📁 当前目录: $CURRENT_DIR"

# 创建虚拟环境
if [ ! -d "venv" ]; then
    echo "🐍 创建Python虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境
source venv/bin/activate
echo "✅ 虚拟环境已激活"

# 安装依赖
echo "📦 安装依赖..."
pip install --upgrade pip
pip install -r backend/requirements.txt

# 创建数据目录
echo "📁 创建数据目录..."
mkdir -p data/{files,logs,backups,uploads,cache}
mkdir -p data/files/{playbooks,inventory,config}

# 生成配置
echo "⚙️ 生成配置..."
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")

cat > .env << EOF
# 快速启动配置
APP_NAME=Ansible Web管理平台
DEBUG=true
API_V1_STR=/api/v1

# 数据库配置（SQLite）
DATABASE_URL=sqlite:///./data/ansible.db

# 安全配置
SECRET_KEY=$SECRET_KEY
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS配置
ALLOWED_HOSTS=["http://localhost:3000","http://127.0.0.1:3000","http://localhost:8000","http://127.0.0.1:8000"]

# 文件存储
UPLOAD_PATH=./data/files
MAX_FILE_SIZE=104857600

# Ansible配置
ANSIBLE_CONFIG_PATH=./data/files/config
ANSIBLE_INVENTORY_PATH=./data/files/inventory
ANSIBLE_PLAYBOOK_PATH=./data/files/playbooks

# 安全中间件（开发环境适度放宽）
SECURITY_MIDDLEWARE_ENABLED=true
RATE_LIMIT_ENABLED=true
IP_FILTER_ENABLED=false
REQUEST_VALIDATION_ENABLED=true
DEFAULT_RATE_LIMIT=1000
AUTH_RATE_LIMIT=100
BURST_LIMIT=200

# 其他配置
MAX_CONCURRENT_TASKS=5
TASK_TIMEOUT_SECONDS=3600
FORCE_HTTPS=false
EOF

echo "✅ 配置文件生成完成"

# 进入后端目录
cd backend

# 设置环境变量
export $(cat ../.env | xargs)

# 初始化数据库
echo "🗄️ 初始化数据库..."
python -c "
from app.core.database import init_database
init_database()
print('✅ 数据库初始化完成')
"

# 创建管理员用户（自动模式）
echo "👤 创建默认管理员用户..."
python -c "
import sys
sys.path.insert(0, '.')

from app.core.database import SessionLocal
from app.models.user import User
from app.core.auth import JWTManager

db = SessionLocal()
jwt_manager = JWTManager()

try:
    # 检查是否已有管理员
    existing_admin = db.query(User).filter(User.is_superuser == True).first()
    if existing_admin:
        print(f'✅ 管理员用户已存在: {existing_admin.username}')
    else:
        # 创建默认管理员
        admin_user = User(
            username='admin',
            email='admin@example.com',
            display_name='系统管理员',
            password_hash=jwt_manager.hash_password('admin123456'),
            is_active=True,
            is_superuser=True,
            is_verified=True
        )
        
        db.add(admin_user)
        db.commit()
        db.refresh(admin_user)
        
        print('✅ 默认管理员用户创建成功!')
        print('  用户名: admin')
        print('  密码: admin123456')
        print('  ⚠️ 请在生产环境中修改默认密码!')
        
except Exception as e:
    print(f'❌ 创建管理员失败: {e}')
    db.rollback()
finally:
    db.close()
"

echo ""
echo "🎉 Ansible Web平台启动准备完成！"
echo "=================================="
echo ""
echo "🚀 启动服务："
echo "  cd backend && uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo "📍 访问地址："
echo "  - 主页: http://localhost:8000"
echo "  - API文档: http://localhost:8000/docs"
echo "  - 健康检查: http://localhost:8000/health"
echo ""
echo "🔑 默认登录信息："
echo "  - 用户名: admin"
echo "  - 密码: admin123456"
echo ""
echo "💡 提示："
echo "  - 数据存储在 ./data/ 目录"
echo "  - 日志文件在 ./data/logs/ 目录"
echo "  - 配置文件是 ./.env"
echo ""

# 询问是否立即启动
read -p "是否立即启动服务？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 启动Ansible Web服务..."
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload
else
    echo "📝 手动启动命令："
    echo "  cd backend && uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
fi