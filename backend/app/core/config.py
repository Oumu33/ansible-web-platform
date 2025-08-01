import os
from typing import List
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # 基础配置
    APP_NAME: str = "Ansible Web管理平台"
    DEBUG: bool = False
    API_V1_STR: str = "/api/v1"
    
    # 安全配置
    SECRET_KEY: str = "your-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # OAuth2配置
    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""
    GITHUB_CLIENT_ID: str = ""
    GITHUB_CLIENT_SECRET: str = ""
    MICROSOFT_CLIENT_ID: str = ""
    MICROSOFT_CLIENT_SECRET: str = ""
    
    OAUTH2_REDIRECT_URL: str = "http://localhost:8000/api/v1/oauth2/callback"
    
    # 数据库配置
    DATABASE_URL: str = "sqlite:///./data/ansible.db"
    
    # Redis配置 (可选)
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # CORS配置
    ALLOWED_HOSTS: List[str] = ["http://localhost:3002", "http://127.0.0.1:3002", "http://localhost:3000", "http://127.0.0.1:3000"]
    
    # 文件存储配置
    UPLOAD_PATH: str = "./data/files"
    MAX_FILE_SIZE: int = 100 * 1024 * 1024  # 100MB
    
    # Ansible配置
    ANSIBLE_CONFIG_PATH: str = "./data/files/config"
    ANSIBLE_INVENTORY_PATH: str = "./data/files/inventory"
    ANSIBLE_PLAYBOOK_PATH: str = "./data/files/playbooks"
    
    # 任务配置
    MAX_CONCURRENT_TASKS: int = 5
    TASK_TIMEOUT_SECONDS: int = 3600  # 1小时
    
    # 安全中间件配置
    SECURITY_MIDDLEWARE_ENABLED: bool = True
    RATE_LIMIT_ENABLED: bool = True
    IP_FILTER_ENABLED: bool = True
    REQUEST_VALIDATION_ENABLED: bool = True
    
    # 速率限制配置
    DEFAULT_RATE_LIMIT: int = 100  # 每分钟请求数
    AUTH_RATE_LIMIT: int = 10      # 认证接口每分钟请求数
    BURST_LIMIT: int = 20          # 突发请求限制
    
    # 请求验证配置
    MAX_REQUEST_SIZE: int = 10 * 1024 * 1024  # 10MB
    
    # IP过滤配置
    BLOCKED_IPS: List[str] = []
    ALLOWED_NETWORKS: List[str] = ["0.0.0.0/0"]  # 默认允许所有IP
    BLOCKED_NETWORKS: List[str] = []
    IP_WHITELIST_ENABLED: bool = False
    
    # HTTPS配置
    FORCE_HTTPS: bool = False
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()