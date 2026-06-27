# Docker LNMP Platform

容器化多环境 LNMP 全栈运维平台（Nginx + PHP-FPM + MySQL + Redis），集成 ELK 日志中心、Prometheus + Grafana 监控告警、一键部署与自验证。

## 整体架构

```
User Browser
     |
   Nginx (:80) --upstream--> PHP-FPM (:9000)
     |                           |
     | logs                  MySQL (:3306)
     |                           |
  Filebeat                  Redis (:6379)
     |
  Logstash --output--> Elasticsearch
     |
  Kibana (:5601)  <-- 日志查看

Prometheus<--scrape-- Nginx / PHP / MySQL / Node
     |
  Grafana (:3000)  <-- 监控面板
     |
  Alertmanager --> Webhook (钉钉/飞书)
```

## 项目结构

```
Docker-LNMP-Platform/
  docker-compose.yml          基础服务定义（16个服务）
  docker-compose.dev.yml      开发环境覆写
  docker-compose.prod.yml     生产环境覆写
  .env.example                环境变量模板
  .env                        环境变量
  deploy.sh                   一键部署脚本
  test.sh                     自验证脚本
  Makefile                    常用命令快捷入口
  nginx/                      Nginx 配置
    default.conf              主配置（安全头、stub_status）
    maintenance.html          PHP-FPM 故障时的维护页面
  php/                        PHP 配置
    Dockerfile                PHP 8.2 + pdo_mysql/redis 扩展
    php.ini                   PHP 配置
    www.conf                  PHP-FPM 进程池配置
  mysql/init.sql              数据库初始化
  www/index.php               系统探针页
  filebeat/filebeat.yml       日志采集配置
  logstash/pipeline/nginx.conf 日志解析管道
  prometheus/                 监控配置
    prometheus.yml            抓取配置
    rules.yml                 告警规则（5条）
  grafana/provisioning/       Grafana 自动配置
  alerts/alertmanager.yml     告警通知配置
  README.md
```

## 快速开始

### 前提条件
- Docker 24+（含 Compose V2）
- 推荐配置：2 核 CPU、4GB 内存、20GB 磁盘

### 一键启动
```bash
# 开发环境
make dev

# 或手动执行
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

### 生产环境
```bash
# 先编辑 .env 设置强密码
make prod

# 或手动执行
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

### 常用命令
- make dev - 启动开发环境
- make prod - 启动生产环境
- make down - 停止所有服务
- make restart - 重启所有服务
- make logs - 查看实时日志
- make ps - 查看服务状态
- make test - 运行自验证脚本
- make clean - 停止并删除数据卷

## 服务访问入口

| 服务 | 地址 | 默认凭证 |
|------|------|----------|
| 网站 (Nginx+PHP) | http://localhost:80 | - |
| Kibana (日志) | http://localhost:5601 | - |
| Grafana (监控) | http://localhost:3000 | admin/admin |
| Prometheus | http://localhost:9090 | - |
| Alertmanager | http://localhost:9093 | - |
| PHP Probe | http://localhost:80/ | - |
| MySQL (仅dev) | localhost:3306 | root/root123 |
| Redis (仅dev) | localhost:6379 | redispass |

## 环境切换

| 特性 | 开发 (dev) | 生产 (prod) |
|------|-----------|-------------|
| MySQL 端口暴露 | :3306 | 不暴露 |
| Redis 端口暴露 | :6379 | 不暴露 |
| PHP display_errors | On | Off |

## 监控与告警

### Grafana 仪表盘
Grafana 启动后自动配置了 Prometheus 数据源。访问 http://localhost:3000 (admin/admin)，导入社区仪表盘 ID 11159（Nginx）或 7362（MySQL）。

### 告警规则
- Nginx 5xx 过高：错误率 > 1%
- PHP-FPM 进程过高：活跃进程 > 80% max_children
- MySQL 连接数过高：连接数 > 80% max_connections
- Redis 内存过高：内存使用 > 80%
- 容器离线：up == 0 持续 1 分钟

告警默认发送到 http://localhost:5000（内置 Webhook 接收器）。如需对接钉钉/飞书，修改 alerts/alertmanager.yml。

## 日志中心
访问 http://localhost:5601（Kibana）查看集中日志。首次使用时需创建索引模式 lnmp-logs-*，时间字段选 @timestamp。

## 资源要求
全部 16 个容器启动后估算约 1.2GB 内存。建议宿主机至少 4GB 可用内存。

## 故障排除

端口冲突：修改 .env 中的端口号，然后 make restart。
容器反复重启：docker compose logs <service> 查看具体错误。
PHP 无法连接数据库：等待 MySQL 健康检查通过后再访问。
Kibana 报错 "No default index pattern"：创建索引模式 lnmp-logs-*。
