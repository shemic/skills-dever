#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="${1:-}"
RESOURCE_RAW="${2:-}"
FORCE=0
WITH_PROVIDER=0
WITH_API=0

shift $(( $# >= 2 ? 2 : $# )) || true
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --provider) WITH_PROVIDER=1 ;;
    --api) WITH_API=1; WITH_PROVIDER=1 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

if [[ -z "$MODULE_DIR" || -z "$RESOURCE_RAW" ]]; then
  echo "Usage: bash scripts/module.sh <module_dir> <resource_name> [--provider] [--api] [--force]"
  echo "Default only creates model. Use --provider/--api only for real business logic."
  exit 1
fi

if [[ ! "$MODULE_DIR" =~ ^[A-Za-z0-9_-]+$ || ! "$RESOURCE_RAW" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "module_dir and resource_name only support letters, numbers, underscore and hyphen."
  exit 1
fi

if [[ ! -f go.mod ]]; then
  echo "go.mod not found. Run this from project root."
  exit 1
fi

PROJECT_MODULE="$(go list -m -f '{{.Path}}' 2>/dev/null || awk '/^module /{print $2; exit}' go.mod)"
if [[ -z "$PROJECT_MODULE" ]]; then
  echo "Cannot resolve module path from go.mod"
  exit 1
fi

to_pascal() {
  echo "$1" | tr '-_' ' ' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) tolower(substr($i,2))} printf "%s",$0}' | tr -d ' '
}

RESOURCE_FILE="$(echo "$RESOURCE_RAW" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
TYPE_NAME="$(to_pascal "$RESOURCE_FILE")"
MODEL_FUNC="New${TYPE_NAME}Model"
TABLE_NAME="${MODULE_DIR}_${RESOURCE_FILE}"

TARGET_FILES=("module/${MODULE_DIR}/model/${RESOURCE_FILE}.go")
if [[ "$WITH_PROVIDER" == "1" ]]; then
  TARGET_FILES+=("module/${MODULE_DIR}/service/${RESOURCE_FILE}.go")
fi
if [[ "$WITH_API" == "1" ]]; then
  TARGET_FILES+=("module/${MODULE_DIR}/api/${RESOURCE_FILE}.go")
fi

if [[ "$FORCE" != "1" ]]; then
  existing=()
  for file in "${TARGET_FILES[@]}"; do
    [[ -e "$file" ]] && existing+=("$file")
  done
  if (( ${#existing[@]} > 0 )); then
    echo "Refuse to overwrite existing files:"
    printf '  %s\n' "${existing[@]}"
    echo "Re-run with --force only after confirming replacement."
    exit 1
  fi
fi

mkdir -p "module/${MODULE_DIR}/model"

cat > "module/${MODULE_DIR}/model/${RESOURCE_FILE}.go" <<EOF
package model

import (
	"time"

	"github.com/shemic/dever/orm"
)

type ${TYPE_NAME} struct {
	ID        uint64    \`dorm:"primaryKey;autoIncrement;comment:主键ID"\`
	Name      string    \`dorm:"type:varchar(128);not null;comment:名称"\`
	Code      string    \`dorm:"type:varchar(128);not null;comment:标识"\`
	Status    int16     \`dorm:"type:smallint;not null;default:1;comment:状态"\`
	Sort      int       \`dorm:"type:int;not null;default:100;comment:排序"\`
	CreatedAt time.Time \`dorm:"comment:创建时间"\`
}

type ${TYPE_NAME}Index struct {
	Code       struct{} \`unique:"code"\`
	StatusSort struct{} \`index:"status,sort,id"\`
}

var ${RESOURCE_FILE}StatusOptions = []map[string]any{
	{"id": 1, "value": "启用"},
	{"id": 2, "value": "停用"},
}

func ${MODEL_FUNC}() *orm.Model[${TYPE_NAME}] {
	return orm.LoadModel[${TYPE_NAME}]("${TYPE_NAME}", "${TABLE_NAME}", orm.ModelConfig{
		Index:    ${TYPE_NAME}Index{},
		Order:    "sort asc,id asc",
		Database: "default",
		Options: map[string]any{
			"status": ${RESOURCE_FILE}StatusOptions,
		},
	})
}
EOF

if [[ "$WITH_PROVIDER" == "1" ]]; then
  mkdir -p "module/${MODULE_DIR}/service"
  cat > "module/${MODULE_DIR}/service/${RESOURCE_FILE}.go" <<EOF
package service

import "github.com/shemic/dever/server"

type ${TYPE_NAME}Hook struct{}

func (${TYPE_NAME}Hook) ProviderBeforeSave${TYPE_NAME}(_ *server.Context, params []any) any {
	if len(params) == 0 {
		return map[string]any{}
	}
	record, _ := params[0].(map[string]any)
	if record == nil {
		return map[string]any{}
	}
	return record
}
EOF
fi

if [[ "$WITH_API" == "1" ]]; then
  mkdir -p "module/${MODULE_DIR}/api"
  cat > "module/${MODULE_DIR}/api/${RESOURCE_FILE}.go" <<EOF
package api

import "github.com/shemic/dever/server"

type ${TYPE_NAME} struct{}

func (${TYPE_NAME}) PostAction(c *server.Context) error {
	return c.Error("请在 service 中实现真实业务逻辑后再开放 API")
}
EOF
fi

echo "Generated:"
printf '  %s\n' "${TARGET_FILES[@]}"
