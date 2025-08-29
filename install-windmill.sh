#!/bin/bash

set -e

echo "🚀 Windmill 一键安装脚本"
echo "========================================"

# 检查 Docker 和 Docker Compose
check_docker() {
    echo "📋 检查 Docker 环境..."
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    echo "✅ Docker 环境检查通过"
}

# 配置 Clash 代理
setup_clash() {
    echo ""
    echo "🌐 配置 Clash 代理..."
    
    # 提示用户输入 clash URL
    read -p "请输入您的 Clash 订阅 URL (留空跳过代理配置): " clash_url
    
    if [ -z "$clash_url" ]; then
        echo "⏭️  跳过代理配置"
        return 0
    fi
    
    echo "📥 安装 Clash..."
    
    # 克隆 clash 仓库到临时目录
    TEMP_DIR=$(mktemp -d)
    git clone https://ghfast.top/https://github.com/xiaoxiunique/clash-for-linux-backup "$TEMP_DIR/clash-for-linux-backup"
    
    # 配置环境变量
    echo "CLASH_URL=$clash_url" > "$TEMP_DIR/clash-for-linux-backup/.env"
    
    # 启动 clash
    cd "$TEMP_DIR/clash-for-linux-backup"
    bash ./start.sh
    
    # 设置代理环境
    if [ -f "/etc/profile.d/clash.sh" ]; then
        source /etc/profile.d/clash.sh
        proxy_on
        echo "✅ Clash 代理已启动"
    else
        echo "⚠️  Clash 配置文件未找到，请手动配置代理"
    fi
    
    cd - > /dev/null
}

# 配置 Docker 代理
setup_docker_proxy() {
    if [ -z "$clash_url" ]; then
        echo "⏭️  跳过 Docker 代理配置"
        return 0
    fi
    
    echo ""
    echo "🐳 配置 Docker 代理..."
    
    # 创建 Docker 代理配置目录
    sudo mkdir -p /etc/systemd/system/docker.service.d
    
    # 写入代理配置
    sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null << EOF
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:7890"
Environment="HTTPS_PROXY=http://127.0.0.1:7890"
EOF
    
    # 重启 Docker 服务
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    echo "✅ Docker 代理配置完成"
}


# 检查网络连接
check_network() {
    echo ""
    echo "🌐 检查网络连接..."
    
    # 测试网络连接
    if ! curl -sf --max-time 10 https://www.docker.com > /dev/null 2>&1; then
        echo "⚠️  网络连接可能有问题，请确保代理配置正确"
        echo "尝试继续安装..."
    else
        echo "✅ 网络连接正常"
    fi
}

# 部署 Windmill
deploy_windmill() {
    echo ""
    echo "🚀 部署 Windmill..."
    
    # 设置重试次数
    max_retries=3
    retry_count=0
    
    echo "📥 拉取 Docker 镜像..."
    while [ $retry_count -lt $max_retries ]; do
        if docker compose pull; then
            echo "✅ 镜像拉取成功"
            break
        else
            retry_count=$((retry_count + 1))
            echo "⚠️  镜像拉取失败，重试 $retry_count/$max_retries..."
            
            if [ $retry_count -eq $max_retries ]; then
                echo "❌ 镜像拉取失败，请检查网络连接和代理配置"
                echo "💡 你可以尝试："
                echo "   1. 检查代理是否正常工作"
                echo "   2. 手动运行: docker compose pull"
                echo "   3. 使用国内 Docker 镜像源"
                exit 1
            fi
            
            sleep 10
        fi
    done
    
    # 启动服务
    echo "🚀 启动 Windmill 服务..."
    docker compose up -d
    
    echo "✅ Windmill 服务已启动"
}

# 等待服务就绪
wait_for_services() {
    echo ""
    echo "⏳ 等待服务就绪..."
    
    # 等待数据库就绪
    echo "等待数据库启动..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker compose exec db pg_isready -U postgres &> /dev/null; then
            break
        fi
        sleep 2
        ((timeout-=2))
    done
    
    if [ $timeout -le 0 ]; then
        echo "⚠️  数据库启动超时，但服务可能仍在启动中"
    else
        echo "✅ 数据库已就绪"
    fi
    
    # 等待 Windmill 服务就绪
    echo "等待 Windmill 服务启动..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if curl -sf http://localhost/api/version &> /dev/null; then
            break
        fi
        sleep 2
        ((timeout-=2))
    done
    
    if [ $timeout -le 0 ]; then
        echo "⚠️  Windmill 服务启动超时，请手动检查"
    else
        echo "✅ Windmill 服务已就绪"
    fi
}

# 显示部署结果
show_results() {
    echo ""
    echo "🎉 Windmill 部署完成!"
    echo "========================================"
    echo "访问地址: http://localhost"
    echo "管理员账号: admin@windmill.dev"
    echo "管理员密码: changeme"
    echo ""
    echo "📊 服务状态:"
    docker compose ps
    echo ""
    echo "📝 常用命令:"
    echo "  查看日志: docker compose logs -f"
    echo "  停止服务: docker compose down" 
    echo "  重启服务: docker compose restart"
    echo ""
    echo "📚 更多信息: https://docs.windmill.dev"
}

# 主函数
main() {
    check_docker
    setup_clash
    setup_docker_proxy
    check_network
    deploy_windmill
    wait_for_services
    show_results
}

# 错误处理
trap 'echo "❌ 安装过程中出现错误"; exit 1' ERR

# 执行主函数
main "$@"