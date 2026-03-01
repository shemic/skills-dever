#!/usr/bin/env bash
set -euo pipefail

MODULE_NAME="${1:-}"
DEVER_VERSION="${2:-main}"
APP_NAME="${3:-dever-app}"
PORT="${4:-8082}"

if [[ -z "$MODULE_NAME" ]]; then
  echo "Usage: bash scripts/bootstrap-empty-project.sh <module_name> [dever_version] [app_name] [port]"
  exit 1
fi

if [[ ! -f go.mod ]]; then
  go mod init "$MODULE_NAME"
else
  EXISTING_MODULE="$(awk '/^module /{print $2; exit}' go.mod)"
  if [[ -n "$EXISTING_MODULE" && "$EXISTING_MODULE" != "$MODULE_NAME" ]]; then
    echo "Detected go.mod module path: $EXISTING_MODULE"
    echo "Use existing module path instead of input: $MODULE_NAME"
    MODULE_NAME="$EXISTING_MODULE"
  fi
fi

go get "github.com/shemic/dever@${DEVER_VERSION}"

mkdir -p config module/main/{api,service,model} middleware data/load

cat > main.go <<EOF
package main

import (
	"log"

	"${MODULE_NAME}/data"
	_ "${MODULE_NAME}/data/load"

	dever "github.com/shemic/dever/cmd"
)

func main() {
	if err := dever.Run(data.RegisterRoutes); err != nil {
		log.Fatal(err)
	}
}
EOF

cat > middleware/init.go <<'EOF'
package middleware

import (
	"sync"

	coremiddleware "github.com/shemic/dever/middleware"
)

var registerOnce sync.Once

func Register() {
	registerOnce.Do(func() {
		coremiddleware.UseGlobal(coremiddleware.Init())
	})
}
EOF

cat > module/main/api/ping.go <<'EOF'
package api

import "github.com/shemic/dever/server"

type Ping struct{}

func (Ping) GetIndex(c *server.Context) error {
	return c.JSON(map[string]any{
		"pong": true,
	})
}
EOF

cat > module/main/service/echo.go <<'EOF'
package service

import "strings"

type EchoService struct{}

func (EchoService) Echo(msg string) map[string]any {
	return map[string]any{
		"msg": strings.TrimSpace(msg),
	}
}
EOF

cat > module/main/api/debug.go <<EOF
package api

import (
	"github.com/shemic/dever/server"

	mainService "${MODULE_NAME}/module/main/service"
)

type Health struct{}
type Debug struct{}

var echoSvc = mainService.EchoService{}

func (Health) GetCheck(c *server.Context) error {
	return c.JSON(map[string]any{
		"ok": true,
	})
}

func (Debug) PostEcho(c *server.Context) error {
	msg := c.Input("msg", "required", "消息内容")
	return c.JSON(echoSvc.Echo(msg))
}
EOF

if [[ ! -f config/setting.json ]]; then
cat > config/setting.json <<EOF
{
  "log": {
    "level": "info",
    "encoding": "console",
    "development": false,
    "enabled": true,
    "output": "stdout"
  },
  "http": {
    "host": "0.0.0.0",
    "port": ${PORT},
    "shutdownTimeout": "10s",
    "appName": "${APP_NAME}",
    "enableTuning": true,
    "prefork": false
  },
  "auth": {
    "jwtSecret": "replace_me"
  },
  "database": {
    "create": false
  },
  "redis": {
    "enable": false
  }
}
EOF
fi

go run "github.com/shemic/dever/cmd/dever@${DEVER_VERSION}" init --skip-tidy

echo "Bootstrap completed."
echo "Run: go run ."
echo "Try endpoints:"
echo "  GET  /ping/index"
echo "  GET  /health/check"
echo "  POST /debug/echo  (msg from query/form/json via c.Input)"
