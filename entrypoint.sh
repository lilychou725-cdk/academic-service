#!/bin/sh

# 动态生成 Xray 配置文件 (监听本地 10000 端口)
cat << EOF > /etc/xray.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": 10000,
    "listen": "127.0.0.1",
    "protocol": "vless",
    "settings": {
      "clients": [{
        "id": "${UUID}"
      }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "${WS_PATH}"
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom"
  }]
}
EOF

# 动态配置 Nginx (将外部请求代理给内部 Xray，根路径返回静态伪装网页)
mkdir -p /etc/nginx/http.d
cat << EOF > /etc/nginx/http.d/default.conf
server {
    listen ${PORT};
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location ${WS_PATH} {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# 启动 Xray 内核并在前台运行 Nginx
echo "Starting Xray Core..."
/usr/local/bin/xray run -config /etc/xray.json &

echo "Starting Nginx Reverse Proxy on port ${PORT}..."
exec nginx -g "daemon off;"
