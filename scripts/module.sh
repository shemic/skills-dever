#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="${1:-}"
RESOURCE_RAW="${2:-}"
DEVER_VERSION="${3:-main}"

if [[ -z "$MODULE_DIR" || -z "$RESOURCE_RAW" ]]; then
  echo "Usage: bash scripts/module.sh <module_dir> <resource_name> [dever_version]"
  echo "Example: bash scripts/module.sh blog article main"
  exit 1
fi

if [[ ! -f go.mod ]]; then
  echo "go.mod not found. Please run bootstrap first."
  exit 1
fi

PROJECT_MODULE="$(go list -m -f '{{.Path}}' 2>/dev/null || true)"
if [[ -z "$PROJECT_MODULE" ]]; then
  PROJECT_MODULE="$(awk '/^module /{print $2; exit}' go.mod)"
fi
if [[ -z "$PROJECT_MODULE" ]]; then
  echo "Cannot resolve module path from go.mod"
  exit 1
fi

to_camel() {
  echo "$1" | tr '-_' ' ' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) tolower(substr($i,2))} printf "%s",$0}' | tr -d ' '
}

RESOURCE_FILE="$(echo "$RESOURCE_RAW" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
TYPE_NAME="$(to_camel "$RESOURCE_FILE")"
SERVICE_TYPE="${TYPE_NAME}Service"
API_TYPE="${TYPE_NAME}"
MODEL_FUNC="${TYPE_NAME}Model"
TABLE_NAME="${MODULE_DIR}_${RESOURCE_FILE}"
SVC_VAR="$(echo "${TYPE_NAME:0:1}" | tr '[:upper:]' '[:lower:]')${TYPE_NAME:1}Svc"

mkdir -p "module/${MODULE_DIR}/model" "module/${MODULE_DIR}/service" "module/${MODULE_DIR}/api"

cat > "module/${MODULE_DIR}/model/${RESOURCE_FILE}.go" <<EOF
package model

import "github.com/shemic/dever/orm"

type ${TYPE_NAME} struct {
	ID     int64  \`dorm:"primaryKey;autoIncrement;comment:主键ID"\`
	Name   string \`dorm:"size:64;not null;comment:名称"\`
	Code   string \`dorm:"size:64;not null;comment:唯一标识"\`
	Status int8   \`dorm:"size:1;not null;default:1;comment:状态"\`
	Sort   int64  \`dorm:"default:1;comment:排序"\`
	Cdate  int64  \`dorm:"comment:创建时间"\`
}

type ${TYPE_NAME}Index struct {
	Code struct{} \`unique:"code"\`
	List struct{} \`index:"status,sort,id"\`
}

func ${MODEL_FUNC}() *orm.Model[${TYPE_NAME}] {
	return orm.LoadModel[${TYPE_NAME}]("${TABLE_NAME}", ${TYPE_NAME}Index{}, "sort desc,id desc", "default")
}
EOF

cat > "module/${MODULE_DIR}/service/helper.go" <<'EOF'
package service

import (
	"fmt"
	"time"
)

func buildCode(prefix string) string {
	if prefix == "" {
		prefix = "id"
	}
	return fmt.Sprintf("%s_%d", prefix, time.Now().UnixNano())
}
EOF

cat > "module/${MODULE_DIR}/service/${RESOURCE_FILE}.go" <<EOF
package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"${PROJECT_MODULE}/module/${MODULE_DIR}/model"
)

type ${SERVICE_TYPE} struct{}

func (${SERVICE_TYPE}) List(ctx context.Context, limit int64) []*model.${TYPE_NAME} {
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	return model.${MODEL_FUNC}().Select(ctx, map[string]any{
		"status": 1,
	}, map[string]any{
		"limit": fmt.Sprintf("%d", limit),
	})
}

func (${SERVICE_TYPE}) Info(ctx context.Context, code string) *model.${TYPE_NAME} {
	return model.${MODEL_FUNC}().Find(ctx, map[string]any{
		"code":   strings.TrimSpace(code),
		"status": 1,
	})
}

func (${SERVICE_TYPE}) Add(ctx context.Context, name string) (string, error) {
	name = strings.TrimSpace(name)
	if name == "" {
		return "", errors.New("name 不能为空")
	}
	code := buildCode("${RESOURCE_FILE}")
	model.${MODEL_FUNC}().Insert(ctx, map[string]any{
		"name":   name,
		"code":   code,
		"status": 1,
		"sort":   time.Now().Unix(),
		"cdate":  time.Now().Unix(),
	})
	return code, nil
}

func (${SERVICE_TYPE}) UpdateName(ctx context.Context, code, name string) error {
	code = strings.TrimSpace(code)
	name = strings.TrimSpace(name)
	if code == "" {
		return errors.New("code 不能为空")
	}
	if name == "" {
		return errors.New("name 不能为空")
	}
	rows := model.${MODEL_FUNC}().Update(ctx, map[string]any{
		"code":   code,
		"status": 1,
	}, map[string]any{
		"name": name,
	})
	if rows <= 0 {
		return errors.New("数据不存在或未更新")
	}
	return nil
}

func (${SERVICE_TYPE}) Delete(ctx context.Context, code string) bool {
	code = strings.TrimSpace(code)
	if code == "" {
		return false
	}
	rows := model.${MODEL_FUNC}().Update(ctx, map[string]any{
		"code":   code,
		"status": 1,
	}, map[string]any{
		"status": 2,
	})
	return rows > 0
}
EOF

cat > "module/${MODULE_DIR}/service/${RESOURCE_FILE}_provider.go" <<EOF
package service

import (
	"fmt"

	"github.com/shemic/dever/server"
)

func (s ${SERVICE_TYPE}) ProviderInfo(c *server.Context, params []any) any {
	if len(params) < 1 {
		panic("ProviderInfo 参数不足，需要 code")
	}
	code := fmt.Sprint(params[0])
	return s.Info(c.Context(), code)
}
EOF

cat > "module/${MODULE_DIR}/api/${RESOURCE_FILE}.go" <<EOF
package api

import (
	"strconv"

	"github.com/shemic/dever/server"

	${MODULE_DIR}service "${PROJECT_MODULE}/module/${MODULE_DIR}/service"
)

type ${API_TYPE} struct{}

var ${SVC_VAR} = ${MODULE_DIR}service.${SERVICE_TYPE}{}

func (${API_TYPE}) GetList(c *server.Context) error {
	limitStr := c.Input("limit", "is_number", "分页条数", "20")
	limit, _ := strconv.ParseInt(limitStr, 10, 64)
	return c.JSON(map[string]any{
		"list": ${SVC_VAR}.List(c.Context(), limit),
	})
}

func (${API_TYPE}) GetInfo(c *server.Context) error {
	code := c.Input("code", "required", "业务标识")
	info := ${SVC_VAR}.Info(c.Context(), code)
	if info == nil {
		return c.Error("数据不存在")
	}
	return c.JSON(map[string]any{"info": info})
}

func (${API_TYPE}) PostAdd(c *server.Context) error {
	name := c.Input("name", "required", "名称")
	code, err := ${SVC_VAR}.Add(c.Context(), name)
	if err != nil {
		return c.Error(err)
	}
	return c.JSON(map[string]any{"code": code})
}

func (${API_TYPE}) PostUpdate(c *server.Context) error {
	code := c.Input("code", "required", "业务标识")
	name := c.Input("name", "required", "名称")
	if err := ${SVC_VAR}.UpdateName(c.Context(), code, name); err != nil {
		return c.Error(err)
	}
	return c.JSON(map[string]any{"code": code, "name": name})
}

func (${API_TYPE}) PostDelete(c *server.Context) error {
	code := c.Input("code", "required", "业务标识")
	ok := ${SVC_VAR}.Delete(c.Context(), code)
	if !ok {
		return c.Error("删除失败或数据不存在")
	}
	return c.JSON(map[string]any{"code": code})
}
EOF

go run "github.com/shemic/dever/cmd/dever@${DEVER_VERSION}" init --skip-tidy

if [[ "$MODULE_DIR" == "main" ]]; then
  ROUTE_PREFIX="/${RESOURCE_FILE}"
else
  ROUTE_PREFIX="/${MODULE_DIR}/${RESOURCE_FILE}"
fi

echo "Scaffold completed: module/${MODULE_DIR} (${RESOURCE_FILE})"
echo "Generated routes examples:"
echo "  GET  ${ROUTE_PREFIX}/list"
echo "  GET  ${ROUTE_PREFIX}/info"
echo "  POST ${ROUTE_PREFIX}/add"
echo "  POST ${ROUTE_PREFIX}/update"
echo "  POST ${ROUTE_PREFIX}/delete"
