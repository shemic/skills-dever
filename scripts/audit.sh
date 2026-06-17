#!/usr/bin/env bash
set -euo pipefail

if ! command -v rg &>/dev/null; then
  echo "错误：audit.sh 依赖 ripgrep（rg），未检测到该命令。"
  echo "安装方式参考：https://github.com/BurntSushi/ripgrep#installation"
  exit 1
fi

if (( $# == 0 )); then
  echo "用法：bash scripts/audit.sh <file-or-dir> [...]"
  exit 2
fi

fail=0
warn_count=0

err() {
  echo "错误：$*"
  fail=1
}

warn() {
  echo "警告：$*"
  warn_count=$((warn_count + 1))
}

pascal_to_snake() {
  echo "$1" |
    sed -E 's/([A-Z]+)([A-Z][a-z])/\1_\2/g; s/([a-z0-9])([A-Z])/\1_\2/g' |
    tr '[:upper:]' '[:lower:]'
}

collect_files() {
  for target in "$@"; do
    if [[ -d "$target" ]]; then
      find "$target" -type f \( -name '*.go' -o -name '*.json' -o -name '*.jsonc' -o -name '*.js' -o -name '*.css' -o -name '*.ts' -o -name '*.tsx' \)
    elif [[ -f "$target" ]]; then
      echo "$target"
    else
      err "路径不存在：$target"
    fi
  done
}

domain_for_model_file() {
  local file="$1"
  local normalized="${file//\\//}"
  local after_model="${normalized#*/model/}"
  if [[ "$after_model" != "$normalized" && "$after_model" == */* ]]; then
    echo "${after_model%%/*}"
    return
  fi
  if [[ "$normalized" =~ (^|/)module/([^/]+)/model/ ]]; then
    echo "${BASH_REMATCH[2]}"
    return
  fi
  if [[ "$normalized" =~ (^|/)package/([^/]+)/model/ ]]; then
    echo "${BASH_REMATCH[2]}"
    return
  fi
  echo ""
}

check_generated() {
  case "$1" in
    */data/router.go|data/router.go|*/data/load/model.go|data/load/model.go|*/data/load/service.go|data/load/service.go|*/data/table/*.json|data/table/*.json)
      err "$1: 生成文件不能手动编辑"
      ;;
    */package/front/html/assets/*|package/front/html/assets/*|*/front/dist/*|front/dist/*|*/package/*/front/dist/*|package/*/front/dist/*|*/module/*/front/dist/*|module/*/front/dist/*)
      err "$1: 编译后的前端产物不能手动编辑"
      ;;
  esac
}

check_model() {
  local file="$1"
  [[ "$file" == *.go ]] || return 0
  [[ "$file" == */model/* || "$file" == */model/*.go ]] || return 0

  local base
  base="$(basename "$file")"
  if [[ "$base" == "main.go" ]]; then
    err "$file: 表 model 不能放在 main.go"
  fi
  if rg -q 'type:longtext|type:LONGTEXT' "$file"; then
    err "$file: 请使用 dorm type:text，不要使用 longtext"
  fi

  mapfile -t funcs < <(rg -o 'func New[A-Za-z0-9_]+Model\(' "$file" | sed -E 's/func New([A-Za-z0-9_]+)Model\(/\1/')
  if (( ${#funcs[@]} > 1 )); then
    err "$file: 一个 model 文件不能定义多个 NewXxxModel 函数"
    return
  fi
  if (( ${#funcs[@]} == 0 )); then
    return
  fi

  local resource expected domain trimmed actual
  resource="${funcs[0]}"
  expected="$(pascal_to_snake "$resource")"
  actual="${base%.go}"
  domain="$(domain_for_model_file "$file" | tr '-' '_' | tr '[:upper:]' '[:lower:]')"
  trimmed="$expected"
  if [[ -n "$domain" && "$expected" == "${domain}_"* ]]; then
    trimmed="${expected#${domain}_}"
  fi

  if [[ "$actual" != "$expected" && "$actual" != "$trimmed" ]]; then
    err "$file: 文件名应匹配 New${resource}Model（${expected}.go 或 ${trimmed}.go）"
  fi
}

is_page_file() {
  [[ "$1" == */page/*.json || "$1" == */page/*.jsonc ]]
}

is_standard_page() {
  local name
  name="$(basename "$1")"
  name="${name%.json}"
  name="${name%.jsonc}"
  case "$name" in
    list|update|create|view|detail|info) return 0 ;;
    *) return 1 ;;
  esac
}

check_page() {
  local file="$1"
  is_page_file "$file" || return 0

  for key in page layout nodes data state action; do
    if ! rg -q "^[[:space:]]*\"${key}\"[[:space:]]*:" "$file"; then
      err "$file: 缺少顶层 ${key}: {}"
    fi
  done

  if is_standard_page "$file"; then
    if rg -q '"_model"[[:space:]]*:|"_use"[[:space:]]*:|"<<[^"]*New[A-Za-z0-9_]*Model>>' "$file"; then
      err "$file: 标准页必须使用路径推导 model，不要写 _model/_use/<<Model>>"
    fi
    if has_direct_submit_model_use "$file"; then
      err "$file: 标准页 action 不能硬编码 submit.use"
    fi
  fi

  if rg -q '/front/route/action|http://|https://.*route/action' "$file"; then
    err "$file: page JSON 不能硬编码 route/action URL；请使用当前 site runtime"
  fi
  if rg -q '"table"[[:space:]]*:[[:space:]]*"[^"]+"|"model"[[:space:]]*:[[:space:]]*"[^"]+"' "$file" && rg -q '"action"[[:space:]]*:' "$file"; then
    warn "$file: 检查 action 配置是否直连表/model 修改；优先使用已注册 front action"
  fi
}

has_direct_submit_model_use() {
  local file="$1"
  awk '
    /"submit"[[:space:]]*:/ {
      in_submit = 1
      depth = 0
    }
    in_submit {
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (c == "{") depth++
        if (c == "}") depth--
      }
      if (depth == 1 && $0 ~ /"use"[[:space:]]*:[[:space:]]*"[^"]*New[A-Za-z0-9_]*Model"/) {
        found = 1
        exit
      }
      if (depth <= 0) {
        in_submit = 0
      }
    }
    END { exit found ? 0 : 1 }
  ' "$file"
}

check_service_api() {
  local file="$1"
  [[ "$file" == *.go ]] || return 0

  if [[ "$file" == */service/* ]]; then
    if rg -q 'Provider[A-Za-z0-9_]+\(.*params \[\]any\) any' "$file" &&
       rg -q 'return record|return params\[0\]|return map\[string\]any\{\}' "$file"; then
      warn "$file: Provider 看起来只是透传；只保留真实校验、规范化或适配 hook"
    fi
    if rg -q 'func .* (Save|List|Create|Update|Delete|GetInfo)[A-Za-z0-9_]*\(' "$file"; then
      warn "$file: Service 方法看起来像 CRUD wrapper；普通 CRUD 应交给 package/front"
    fi
  fi

  if [[ "$file" == */api/* ]]; then
    if rg -q 'Post(Action|Create|Update|Save)|Get(List|Info|Detail)|Delete(Delete)?' "$file"; then
      warn "$file: API 看起来像 CRUD/action wrapper；请确认它是真实 HTTP 能力"
    fi
  fi
}

while IFS= read -r file; do
  check_generated "$file"
  check_model "$file"
  check_page "$file"
  check_service_api "$file"
done < <(collect_files "$@")

if (( fail != 0 )); then
  exit 1
fi

if (( warn_count > 0 )); then
  echo "dever skill audit 通过，有 ${warn_count} 个警告"
else
  echo "dever skill audit 通过"
fi
