#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GITIGNORE_TEMPLATE="${SKILL_ROOT}/files/gitignore"

FORCE=0
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--force" ]]; then
    FORCE=1
  else
    ARGS+=("$arg")
  fi
done

REQUESTED_MODULE_NAME="${ARGS[0]:-}"
MODULE_NAME="my"
DEVER_VERSION="${ARGS[1]:-main}"
APP_NAME="${ARGS[2]:-dever-app}"
PORT="${ARGS[3]:-8082}"

if [[ -z "$REQUESTED_MODULE_NAME" ]]; then
  echo "Usage: bash scripts/boot.sh <module_name> [dever_version] [app_name] [port] [--force]"
  echo "Note: Dever application projects always use Go module path: my"
  exit 1
fi

if [[ "$REQUESTED_MODULE_NAME" != "$MODULE_NAME" ]]; then
  echo "Ignoring requested module path: $REQUESTED_MODULE_NAME"
  echo "Dever application projects always use Go module path: $MODULE_NAME"
fi

if [[ ! -f go.mod ]]; then
  go mod init "$MODULE_NAME"
else
  EXISTING_MODULE="$(awk '/^module /{print $2; exit}' go.mod)"
  if [[ -n "$EXISTING_MODULE" && "$EXISTING_MODULE" != "$MODULE_NAME" ]]; then
    echo "Detected go.mod module path: $EXISTING_MODULE"
    echo "Dever package components require module path: $MODULE_NAME"
    echo "Refuse to continue instead of generating incompatible imports."
    exit 1
  fi
fi

run_dever() {
  if grep -Eq 'replace[[:space:]]+github.com/shemic/dever[[:space:]]+=>[[:space:]]+\./dever' go.mod 2>/dev/null; then
    go run ./dever/cmd/dever "$@"
    return
  fi
  go run "github.com/shemic/dever/cmd/dever@${DEVER_VERSION}" "$@"
}

ensure_gitignore() {
  local file=".gitignore"
  local marker="# >>> dever generated ignore"
  if [[ ! -f "$GITIGNORE_TEMPLATE" ]]; then
    echo "Missing gitignore template: $GITIGNORE_TEMPLATE"
    exit 1
  fi
  if [[ ! -f "$file" ]]; then
    cp "$GITIGNORE_TEMPLATE" "$file"
    return
  fi
  if [[ -f "$file" ]] && grep -Fq "$marker" "$file"; then
    return
  fi
  if [[ -s "$file" ]]; then
    printf '\n' >> "$file"
  fi
  cat "$GITIGNORE_TEMPLATE" >> "$file"
}

TARGET_FILES=(
  "main.go"
  "middleware/readme.txt"
  "module/main/api/ping.go"
  "module/main/api/debug.go"
  "module/main/service/echo.go"
)

if [[ "$FORCE" != "1" ]]; then
  existing=()
  for file in "${TARGET_FILES[@]}"; do
    if [[ -e "$file" ]]; then
      existing+=("$file")
    fi
  done
  if (( ${#existing[@]} > 0 )); then
    echo "Refuse to overwrite existing files:"
    printf '  %s\n' "${existing[@]}"
    echo "Re-run with --force only after confirming these files can be replaced."
    exit 1
  fi
fi

go get "github.com/shemic/dever@${DEVER_VERSION}"

mkdir -p config module/main/{api,service,model} middleware data/{load,log} package
touch data/readme.txt package/readme.txt
ensure_gitignore

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

cat > middleware/readme.txt <<'EOF'
项目自定义 middleware 是可选目录。

如需项目级中间件，在本目录增加 Go 文件并提供 Register() 函数。
Dever 生成 data/router.go 时会自动导入并调用。
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

if [[ ! -f config/setting.json && ! -f config/setting.jsonc ]]; then
cat > config/setting.jsonc <<EOF
{
  "log": {
    "level": "info",
    "development": false,
    "enabled": true,
    "output": "file",
    "successFile": "data/log/access.log",
    "errorFile": "data/log/error.log"
  },
  "observe": {
    "enabled": false,
    "provider": "builtin",
    "service": "",
    "slowRequest": "500ms",
    "slowSQL": "200ms",
    "options": {
      "endpoint": "",
      "timeout": "3s",
      "buffer": 512,
      "headers": {
        "Authorization": ""
      }
    }
  },
  "http": {
    "host": "0.0.0.0",
    "port": ${PORT},
    "shutdownTimeout": "10s",
    "appName": "${APP_NAME}",
    "cors": {
      "enabled": true,
      "allowOrigins": ["*"],
      "allowMethods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
      "allowHeaders": ["*"],
      "allowCredentials": false,
      "exposeHeaders": [],
      "maxAge": 0
    },
    "enableTuning": true,
    "prefork": false
  },
  "auth": {
    "jwtSecret": "replace_me"
    // 多 JWT 时改为：
    // "jwt": {
    //   "schemes": {
    //     "user": {
    //       "alg": "HS256",
    //       "secret": "replace_user_secret",
    //       "header": "Authorization",
    //       "prefix": "Bearer",
    //       "claimKeys": ["uid", "sub"]
    //     }
    //   },
    //   "guards": [
    //     {
    //       "scheme": "user",
    //       "prefixes": ["/"],
    //       "publicPaths": ["/ping/index", "/health/check"]
    //     }
    //   ]
    // }
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

run_dever install

echo "Bootstrap completed."
echo "Install: dever command ready"
echo "Config: config/setting.jsonc"
echo "Gitignore: .gitignore"
echo "Run: dever run"
echo "Build: dever build"
echo "Try endpoints:"
echo "  GET  /ping/index"
echo "  GET  /health/check"
echo "  POST /debug/echo  (msg from query/form/json via c.Input)"
