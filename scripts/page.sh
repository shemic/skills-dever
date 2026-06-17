#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${SKILL_ROOT}/files/page/standard"

OWNER_DIR="${1:-}"
SITE_KEY="${2:-}"
RESOURCE_RAW="${3:-}"
PAGE_KIND="${4:-}"
RESOURCE_TITLE="${5:-}"
FORCE=0

shift $(( $# >= 5 ? 5 : $# )) || true
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) echo "未知选项：$arg"; exit 1 ;;
  esac
done

if [[ -z "$OWNER_DIR" || -z "$SITE_KEY" || -z "$RESOURCE_RAW" || -z "$PAGE_KIND" ]]; then
  echo "用法：bash scripts/page.sh <module-or-package-dir> <site_key> <resource_name> <list|update|detail> [resource_title] [--force]"
  echo "示例：bash scripts/page.sh module/demo admin product list 产品"
  exit 1
fi

case "$PAGE_KIND" in
  list|update|detail) ;;
  *) echo "不支持的页面类型：$PAGE_KIND"; exit 1 ;;
esac

if [[ ! "$SITE_KEY" =~ ^[A-Za-z0-9_-]+$ || ! "$RESOURCE_RAW" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "site_key 和 resource_name 只支持字母、数字、下划线和连字符。"
  exit 1
fi

RESOURCE_NAME="$(echo "$RESOURCE_RAW" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
RESOURCE_TITLE="${RESOURCE_TITLE:-$RESOURCE_NAME}"
TEMPLATE="${TEMPLATE_DIR}/${PAGE_KIND}.json.tmpl"
TARGET="${OWNER_DIR}/front/page/${SITE_KEY}/${RESOURCE_NAME}/${PAGE_KIND}.json"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "模板不存在：$TEMPLATE"
  exit 1
fi
if [[ -e "$TARGET" && "$FORCE" != "1" ]]; then
  echo "拒绝覆盖已有文件：$TARGET"
  echo "确认需要替换后再使用 --force 重新执行。"
  exit 1
fi
if [[ -e "$TARGET" && "$FORCE" == "1" ]]; then
  cp "$TARGET" "${TARGET}.bak"
fi

mkdir -p "$(dirname "$TARGET")"
sed \
  -e "s/{{RESOURCE_NAME}}/${RESOURCE_NAME}/g" \
  -e "s/{{RESOURCE_TITLE}}/${RESOURCE_TITLE}/g" \
  "$TEMPLATE" > "$TARGET"

echo "已生成："
echo "  $TARGET"
echo "标准页面骨架使用 model 自动推导，未生成 Service/API。"
