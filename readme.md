## 1. 安装 clash

clash_url=xxxx

```bash
git clone https://ghfast.top/https://github.com/xiaoxiunique/clash-for-linux-backup

echo "CLASH_URL=$clash_url" >> clash-for-linux-backend/.env

cd clash-for-linux-backend

bash ./start.sh

source /etc/profile.d/clash.sh

proxy_on

docker compose up
```

## 2. 安装 docker

```
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo vim /etc/systemd/system/docker.service.d/http-proxy.conf


[Service]
Environment="HTTP_PROXY=http://127.0.0.1:7890"
Environment="HTTPS_PROXY=http://127.0.0.1:7890"

sudo systemctl daemon-reload
sudo systemctl restart docker
```