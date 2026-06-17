#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FILES_DIR="${SKILL_ROOT}/files"

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
DEVER_VERSION="${ARGS[1]:-v0.1.2}"
APP_NAME="${ARGS[2]:-dever-app}"
PORT="${ARGS[3]:-8082}"

if [[ -z "$REQUESTED_MODULE_NAME" ]]; then
  echo "用法：bash scripts/boot.sh <module_name> [dever_version] [app_name] [port] [--force]"
  echo "说明：Dever 应用项目固定使用 Go 模块路径：my"
  exit 1
fi

if [[ "$REQUESTED_MODULE_NAME" != "$MODULE_NAME" ]]; then
  echo "已忽略传入的 module path：$REQUESTED_MODULE_NAME"
  echo "Dever 应用项目固定使用 Go 模块路径：$MODULE_NAME"
fi

copy_file() {
  local src="$1"
  local dest="$2"
  if [[ ! -f "$src" ]]; then
    echo "模板不存在：$src"
    exit 1
  fi
  if [[ -e "$dest" && "$FORCE" != "1" ]]; then
    return
  fi
  if [[ -e "$dest" && "$FORCE" == "1" ]]; then
    cp "$dest" "${dest}.bak"
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

render_template() {
  local src="$1"
  local dest="$2"
  if [[ ! -f "$src" ]]; then
    echo "模板不存在：$src"
    exit 1
  fi
  if [[ -e "$dest" && "$FORCE" != "1" ]]; then
    return
  fi
  if [[ -e "$dest" && "$FORCE" == "1" ]]; then
    cp "$dest" "${dest}.bak"
  fi
  mkdir -p "$(dirname "$dest")"
  sed \
    -e "s/{{MODULE_NAME}}/${MODULE_NAME}/g" \
    -e "s/{{DEVER_VERSION}}/${DEVER_VERSION}/g" \
    -e "s/{{APP_NAME}}/${APP_NAME}/g" \
    -e "s/{{PORT}}/${PORT}/g" \
    "$src" > "$dest"
}

ensure_go_mod() {
  if [[ ! -f go.mod ]]; then
    render_template "${FILES_DIR}/go/go.mod.tmpl" "go.mod"
    return
  fi
  local existing_module
  existing_module="$(awk '/^module /{print $2; exit}' go.mod)"
  if [[ -n "$existing_module" && "$existing_module" != "$MODULE_NAME" ]]; then
    echo "检测到 go.mod 模块路径：$existing_module"
    echo "Dever package 组件要求模块路径：$MODULE_NAME"
    echo "已停止，避免生成不兼容的 import。"
    exit 1
  fi
}

ensure_gitignore() {
  local file=".gitignore"
  local template="${FILES_DIR}/gitignore"
  local marker="# >>> dever generated ignore"
  if [[ ! -f "$template" ]]; then
    echo "gitignore 模板不存在：$template"
    exit 1
  fi
  if [[ ! -f "$file" ]]; then
    cp "$template" "$file"
    return
  fi
  if grep -Fq "$marker" "$file"; then
    return
  fi
  [[ -s "$file" ]] && printf '\n' >> "$file"
  cat "$template" >> "$file"
}

mkdir -p config/front/assets/{admin,work}/images middleware data/{load,log} package module/main/model
ensure_go_mod
ensure_gitignore

render_template "${FILES_DIR}/go/main.go.tmpl" "main.go"
render_template "${FILES_DIR}/config/setting.jsonc.tmpl" "config/setting.jsonc"
copy_file "${FILES_DIR}/config/front.jsonc.tmpl" "config/front.jsonc"
copy_file "${FILES_DIR}/go/middleware/readme.txt" "middleware/readme.txt"
copy_file "${FILES_DIR}/go/data/readme.txt" "data/readme.txt"
copy_file "${FILES_DIR}/go/package/readme.txt" "package/readme.txt"

for site in admin work; do
  for file in logo.svg favicon.svg; do
    copy_file "${FILES_DIR}/config/front/assets/${site}/images/${file}" "config/front/assets/${site}/images/${file}"
  done
done

echo "已生成最小 Dever 项目骨架。"
echo "未生成任何业务 API 或 Service。"
