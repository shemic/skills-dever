#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${SKILL_ROOT}/files/component"
source "${SCRIPT_DIR}/lib/template.sh"

OWNER_KIND="${1:-}"
COMPONENT_RAW="${2:-}"
COMPONENT_TITLE="${3:-}"
FORCE=0

shift $(( $# >= 3 ? 3 : $# )) || true
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) echo "未知选项：$arg"; exit 1 ;;
  esac
done

if [[ -z "$OWNER_KIND" || -z "$COMPONENT_RAW" ]]; then
  echo "用法：bash scripts/component-skill.sh <package|module> <component_name> [component_title] [--force]"
  exit 1
fi

case "$OWNER_KIND" in
  package|module) ;;
  *) echo "组件归属必须是 package 或 module"; exit 1 ;;
esac

if [[ ! "$COMPONENT_RAW" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]]; then
  echo "component_name 必须以字母开头，只支持字母、数字、下划线和连字符。"
  exit 1
fi

COMPONENT_NAME="$(echo "$COMPONENT_RAW" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
COMPONENT_SKILL_NAME="${COMPONENT_NAME//_/-}"
COMPONENT_TITLE="${COMPONENT_TITLE:-$COMPONENT_NAME}"
dever_template_require_single_line component_title "$COMPONENT_TITLE" || exit 1
BASE_DIR="${OWNER_KIND}/${COMPONENT_NAME}"
COMPONENT_ROOT="${BASE_DIR}"
SKILL_DIR="${BASE_DIR}/skills"

dever_render_template "${TEMPLATE_DIR}/dever.json.tmpl" "${BASE_DIR}/dever.json" "$FORCE" \
  json COMPONENT_NAME "$COMPONENT_NAME" \
  json COMPONENT_TITLE "$COMPONENT_TITLE"
dever_render_template "${TEMPLATE_DIR}/skills/SKILL.md.tmpl" "${SKILL_DIR}/SKILL.md" "$FORCE" \
  raw COMPONENT_NAME "$COMPONENT_NAME" \
  raw COMPONENT_SKILL_NAME "$COMPONENT_SKILL_NAME" \
  json COMPONENT_TITLE_YAML "$COMPONENT_TITLE" \
  text COMPONENT_TITLE "$COMPONENT_TITLE" \
  raw OWNER_KIND "$OWNER_KIND" \
  text COMPONENT_ROOT "$COMPONENT_ROOT"
dever_render_template "${TEMPLATE_DIR}/skills/README.md.tmpl" "${SKILL_DIR}/README.md" "$FORCE" \
  text COMPONENT_TITLE "$COMPONENT_TITLE" \
  raw COMPONENT_NAME "$COMPONENT_NAME"

echo "已生成组件 skill 骨架："
echo "  ${BASE_DIR}/dever.json"
echo "  ${SKILL_DIR}/SKILL.md"
echo "  ${SKILL_DIR}/README.md"
