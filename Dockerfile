FROM alpine:latest

# 安装必要依赖
RUN apk add --no-cache curl unzip nginx gettext

# 下载并安装官方 Xray-core
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64-v8a"; else ARCH="64"; fi && \
    curl -sL https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-linux-${ARCH}.zip -o /tmp/xray.zip && \
    unzip -q /tmp/xray.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/xray && \
    rm -rf /tmp/xray.zip

# 复制前端伪装网站与入口脚本
COPY index.html /var/www/html/index.html
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PORT=8080
ENV UUID=b831381d-6324-4d53-ad4f-8cda48b30811
ENV WS_PATH=/ws

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
