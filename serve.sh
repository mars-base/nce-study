#!/usr/bin/env bash
# 本地启动 nce-study 静态站点
# 用法: ./serve.sh [端口]  默认 8088

cd "$(dirname "$0")" || exit 1

port=${1:-8088}

if command -v uv >/dev/null 2>&1 && [ -x "$HOME/.venv/bin/python3" ]; then
    py="$HOME/.venv/bin/python3"
else
    py=python3
fi

echo "serving $PWD at http://localhost:$port (Ctrl+C to stop)"
exec "$py" -m http.server "$port" --bind 127.0.0.1
