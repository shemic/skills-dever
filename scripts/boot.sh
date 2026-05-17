#!/usr/bin/env bash
set -euo pipefail

FORCE=0
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--force" ]]; then
    FORCE=1
  else
    ARGS+=("$arg")
  fi
done

MODULE_NAME="${ARGS[0]:-}"
DEVER_VERSION="${ARGS[1]:-main}"
APP_NAME="${ARGS[2]:-dever-app}"
PORT="${ARGS[3]:-8082}"

if [[ -z "$MODULE_NAME" ]]; then
  echo "Usage: bash scripts/boot.sh <module_name> [dever_version] [app_name] [port] [--force]"
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
  if [[ -f "$file" ]] && grep -Fq "$marker" "$file"; then
    return
  fi
  if [[ -f "$file" && -s "$file" ]]; then
    printf '\n' >> "$file"
  fi
  cat >> "$file" <<'EOF'
# >>> dever generated ignore
# Local environment and secrets
.env
.env.*
!.env.example
!.env.*.example
config/*.local.json
config/*.local.jsonc

# Dever runtime data and local build artifacts
/data/log/
/data/tmp/
/data/cache/
/data/run/
/data/bin/
/data/upload/

# Release/build outputs
/server
/server.exe
/dist/
/build/
*.test
*.out
coverage.out

# OS/editor
.DS_Store
.idea/
.vscode/
# <<< dever generated ignore
EOF
}

TARGET_FILES=(
  "main.go"
  "middleware/init.go"
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

mkdir -p config module/main/{api,service,model} middleware data/load
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

if [[ ! -f config/setting.json && ! -f config/setting.jsonc ]]; then
cat > config/setting.jsonc <<EOF
{
  "log": {
    "level": "info",
    "development": false,
    "enabled": true,
    "output": "stdout"
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
