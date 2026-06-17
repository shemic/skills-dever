#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="${1:-}"
RESOURCE_RAW="${2:-}"
FORCE=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE="${SKILL_ROOT}/files/go/model.go.tmpl"

shift $(( $# >= 2 ? 2 : $# )) || true
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --provider|--api)
      echo "此脚本故意不生成 $arg。"
      echo "只有读完 references/service-api.md 并确认需要后，才手写 Provider/Service/API。"
      exit 1
      ;;
    *) echo "未知选项：$arg"; exit 1 ;;
  esac
done

if [[ -z "$MODULE_DIR" || -z "$RESOURCE_RAW" ]]; then
  echo "用法：bash scripts/module.sh <module_dir> <resource_name> [--force]"
  echo "此脚本只创建 model 骨架，不创建 Provider/API/Service。"
  exit 1
fi

if [[ ! "$MODULE_DIR" =~ ^[A-Za-z0-9_-]+$ || ! "$RESOURCE_RAW" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "module_dir 和 resource_name 只支持字母、数字、下划线和连字符。"
  exit 1
fi

if [[ ! -f go.mod ]]; then
  echo "未找到 go.mod，请在项目根目录执行。"
  exit 1
fi
if [[ ! -f "$TEMPLATE" ]]; then
  echo "模板不存在：$TEMPLATE"
  exit 1
fi

to_pascal() {
  echo "$1" | tr '-_' ' ' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) tolower(substr($i,2))} printf "%s",$0}' | tr -d ' '
}

RESOURCE_FILE="$(echo "$RESOURCE_RAW" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
TYPE_NAME="$(to_pascal "$RESOURCE_FILE")"
MODEL_FUNC="New${TYPE_NAME}Model"
TABLE_NAME="${MODULE_DIR}_${RESOURCE_FILE}"
TARGET_FILE="module/${MODULE_DIR}/model/${RESOURCE_FILE}.go"

if [[ -e "$TARGET_FILE" && "$FORCE" != "1" ]]; then
  echo "拒绝覆盖已有文件：$TARGET_FILE"
  echo "确认需要替换后再使用 --force 重新执行。"
  exit 1
fi
if [[ -e "$TARGET_FILE" && "$FORCE" == "1" ]]; then
  cp "$TARGET_FILE" "${TARGET_FILE}.bak"
fi

mkdir -p "module/${MODULE_DIR}/model"
sed \
  -e "s/{{TYPE_NAME}}/${TYPE_NAME}/g" \
  -e "s/{{RESOURCE_FILE}}/${RESOURCE_FILE}/g" \
  -e "s/{{MODEL_FUNC}}/${MODEL_FUNC}/g" \
  -e "s/{{TABLE_NAME}}/${TABLE_NAME}/g" \
  "$TEMPLATE" > "$TARGET_FILE"

echo "已生成："
echo "  $TARGET_FILE"
echo "未生成 Provider/API/Service。只有真实业务逻辑需要时才手动添加。"
