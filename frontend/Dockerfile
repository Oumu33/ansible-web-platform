# Ansible Web Frontend Production Dockerfile
# 多阶段构建优化镜像大小

# Stage 1: Build stage
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装构建依赖
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++

# 复制package文件并安装依赖
COPY package*.json ./
RUN npm ci --only=production --silent

# 复制源代码
COPY . .

# 构建应用
RUN npm run build:prod

# Stage 2: Nginx production stage
FROM nginx:1.25-alpine AS production

# 安装额外工具
RUN apk add --no-cache \
    curl \
    jq \
    tzdata

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建nginx用户和目录
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制nginx配置
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.prod.conf /etc/nginx/conf.d/default.conf

# 复制健康检查脚本
COPY scripts/health-check.sh /usr/local/bin/health-check.sh
RUN chmod +x /usr/local/bin/health-check.sh

# 创建日志目录
RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /usr/share/nginx/html

# 暴露端口
EXPOSE 80 443

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /usr/local/bin/health-check.sh

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]

# 元数据标签
LABEL maintainer="Ansible Web Team" \
      version="1.0.0" \
      description="Ansible Web管理平台前端" \
      org.opencontainers.image.source="https://github.com/ansible-web/frontend"