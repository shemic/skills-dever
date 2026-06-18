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
PARENT_OVERRIDE=""

shift $(( $# >= 5 ? 5 : $# )) || true
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --parent=*) PARENT_OVERRIDE="${arg#--parent=}" ;;
    *) echo "未知选项：$arg"; exit 1 ;;
  esac
done

if [[ -z "$OWNER_DIR" || -z "$SITE_KEY" || -z "$RESOURCE_RAW" || -z "$PAGE_KIND" ]]; then
  echo "用法：bash scripts/page.sh <module-or-package-dir> <site_key> <resource_name> <list|update|detail> [resource_title] [--parent=<parent_key_or_route>] [--force]"
  echo "示例：bash scripts/page.sh module/demo admin product list 产品 --parent=product-center"
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
if [[ -n "$PARENT_OVERRIDE" && ! "$PARENT_OVERRIDE" =~ ^[A-Za-z0-9_/-]+$ ]]; then
  echo "parent 只支持字母、数字、下划线、连字符和斜杠。"
  exit 1
fi

RESOURCE_NAME="$(echo "$RESOURCE_RAW" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
RESOURCE_TITLE="${RESOURCE_TITLE:-$RESOURCE_NAME}"
COMPONENT_NAME="$(basename "$OWNER_DIR" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
PARENT_ROUTE="${PARENT_OVERRIDE:-${COMPONENT_NAME}/${RESOURCE_NAME}/list}"
UPDATE_ROUTE="${COMPONENT_NAME}/${RESOURCE_NAME}/update"
TEMPLATE="${TEMPLATE_DIR}/${PAGE_KIND}.json.tmpl"
TARGET="${OWNER_DIR}/front/page/${SITE_KEY}/${RESOURCE_NAME}/${PAGE_KIND}.json"

if [[ "$PAGE_KIND" == "list" && -z "$PARENT_OVERRIDE" ]]; then
  echo "生成 list 页必须显式指定 --parent=<menu_key>，避免权限同步把页面错误放到顶层菜单。"
  exit 1
fi

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
  -e "s#{{PARENT_KEY}}#${PARENT_OVERRIDE}#g" \
  -e "s#{{PARENT_ROUTE}}#${PARENT_ROUTE}#g" \
  -e "s#{{UPDATE_ROUTE}}#${UPDATE_ROUTE}#g" \
  "$TEMPLATE" > "$TARGET"

echo "已生成："
echo "  $TARGET"
echo "标准页面骨架使用 model 自动推导，未生成 Service/API。"
