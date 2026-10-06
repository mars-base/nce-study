#!/usr/bin/env bash
# 本地静态站点管理：./serve.sh {start|stop|status|restart|log} [端口]
# 默认端口 8088，仅监听 127.0.0.1

cd "$(dirname "$0")" || exit 1

cmd=${1:-start}
port=${2:-${PORT:-8088}}

pidfile=".serve.pid"
logfile=".serve.log"

if command -v uv >/dev/null 2>&1 && [ -x "$HOME/.venv/bin/python3" ]; then
    py="$HOME/.venv/bin/python3"
else
    py=python3
fi

running_pid() {
    local pid
    pid=$(cat "$pidfile" 2>/dev/null) || return 1
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null || return 1
    echo "$pid"
}

do_start() {
    local pid
    if pid=$(running_pid); then
        echo "already running: pid $pid, http://localhost:$port"
        return 0
    fi
    setsid "$py" -m http.server "$port" --bind 127.0.0.1 >"$logfile" 2>&1 &
    pid=$!
    echo "$pid" > "$pidfile"
    sleep 0.5
    if kill -0 "$pid" 2>/dev/null; then
        echo "started: pid $pid, http://localhost:$port (log: $logfile)"
    else
        rm -f "$pidfile"
        echo "failed to start, see $logfile" >&2
        return 1
    fi
}

do_stop() {
    local pid
    if ! pid=$(running_pid); then
        echo "not running"
        rm -f "$pidfile"
        return 0
    fi
    kill "$pid"
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.2
    done
    kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    rm -f "$pidfile"
    echo "stopped: pid $pid"
}

case "$cmd" in
    start)  do_start ;;
    stop)   do_stop ;;
    restart) do_stop && do_start ;;
    status)
        if pid=$(running_pid); then
            echo "running: pid $pid, http://localhost:$port"
            curl -s -o /dev/null -m 3 -w "http: %{http_code}\n" "http://127.0.0.1:$port/" || true
        else
            echo "not running"
            exit 1
        fi
        ;;
    log)    tail -n 50 "$logfile" ;;
    *)      echo "usage: $0 {start|stop|restart|status|log} [port]" >&2; exit 2 ;;
esac
