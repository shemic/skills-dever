#!/usr/bin/env bash
set -euo pipefail

if ! command -v rg &>/dev/null; then
  echo "错误：audit.sh 依赖 ripgrep（rg），未检测到该命令。"
  echo "安装方式参考：https://github.com/BurntSushi/ripgrep#installation"
  exit 1
fi

fail=0
warn_count=0
CHANGED=0
TARGETS=()

for arg in "$@"; do
  case "$arg" in
    --changed) CHANGED=1 ;;
    --help|-h)
      echo "用法：bash scripts/audit.sh [--changed] <file-or-dir> [...]"
      echo "  --changed  只检查 git 已修改/新增文件"
      exit 0
      ;;
    *) TARGETS+=("$arg") ;;
  esac
done

if (( CHANGED == 0 && ${#TARGETS[@]} == 0 )); then
  echo "用法：bash scripts/audit.sh [--changed] <file-or-dir> [...]"
  exit 2
fi

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
  if (( CHANGED == 1 )); then
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
      err "--changed 需要在 git 仓库内执行"
      return
    fi
    if (( ${#TARGETS[@]} > 0 )); then
      git_changed_files "${TARGETS[@]}" |
        filter_audit_files
      git_untracked_files "${TARGETS[@]}" |
        filter_audit_files
    else
      git_changed_files |
        filter_audit_files
      git_untracked_files |
        filter_audit_files
    fi
    return
  fi

  for target in "${TARGETS[@]}"; do
    if [[ -d "$target" ]]; then
      find "$target" -type f \( -name '*.go' -o -name '*.json' -o -name '*.jsonc' -o -name '*.js' -o -name '*.css' -o -name '*.ts' -o -name '*.tsx' -o -name '*.go.tmpl' -o -name '*.json.tmpl' -o -name '*.jsonc.tmpl' \) |
        filter_audit_files |
        skip_generated_or_built_files
    elif [[ -f "$target" ]]; then
      echo "$target"
    else
      err "路径不存在：$target"
    fi
  done
}

git_has_head() {
  git rev-parse --verify HEAD &>/dev/null
}

git_changed_files() {
  if git_has_head; then
    git diff --name-only --diff-filter=ACMRTUXB HEAD -- "$@"
    return
  fi
  git diff --name-only --cached --diff-filter=ACMRTUXB -- "$@"
  git ls-files --modified -- "$@"
}

git_untracked_files() {
  git ls-files --others --exclude-standard -- "$@"
}

filter_audit_files() {
  awk '
    /\.(go|json|jsonc|js|css|ts|tsx)$/ { print }
    /\.(go|json|jsonc)\.tmpl$/ { print }
  '
}

skip_generated_or_built_files() {
  while IFS= read -r file; do
    is_generated_or_built_file "$file" && continue
    echo "$file"
  done
}

is_generated_or_built_file() {
  case "$1" in
    */data/router.go|data/router.go|*/data/load/model.go|data/load/model.go|*/data/load/service.go|data/load/service.go|*/data/table/*.json|data/table/*.json)
      return 0
      ;;
    */package/front/front/html/*|package/front/front/html/*|*/package/front/html/assets/*|package/front/html/assets/*|*/front/dist/*|front/dist/*|*/package/*/front/dist/*|package/*/front/dist/*|*/module/*/front/dist/*|module/*/front/dist/*)
      return 0
      ;;
  esac
  return 1
}

is_explicit_target() {
  local file="$1"
  for target in "${TARGETS[@]}"; do
    [[ "$file" == "$target" ]] && return 0
  done
  return 1
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
  if (( CHANGED == 0 )) && ! is_explicit_target "$1"; then
    return
  fi

  case "$1" in
    */data/router.go|data/router.go|*/data/load/model.go|data/load/model.go|*/data/load/service.go|data/load/service.go|*/data/table/*.json|data/table/*.json)
      err "$1: 生成文件不能手动编辑"
      ;;
    */package/front/front/html/*|package/front/front/html/*|*/package/front/html/assets/*|package/front/html/assets/*|*/front/dist/*|front/dist/*|*/package/*/front/dist/*|package/*/front/dist/*|*/module/*/front/dist/*|module/*/front/dist/*)
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
  [[ "$1" == */page/*.json || "$1" == */page/*.jsonc || "$1" == */page/*.json.tmpl || "$1" == */page/*.jsonc.tmpl ]]
}

page_kind() {
  local name
  name="$(basename "$1")"
  name="${name%.tmpl}"
  name="${name%.json}"
  name="${name%.jsonc}"
  echo "$name"
}

is_standard_page() {
  local name
  name="$(page_kind "$1")"
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

  check_forbidden_page_protocol "$file"
  check_option_params_protocol "$file"
  check_page_field_boundary "$file"

  if is_standard_page "$file"; then
    local kind
    kind="$(page_kind "$file")"
    if ! rg -q '^[[:space:]]*"parent"[[:space:]]*:' "$file"; then
      err "$file: 标准 ${kind} 页必须声明 page.parent，避免权限/菜单归属错误"
    fi
    if [[ "$kind" == "update" || "$kind" == "create" ]] && ! rg -q '"submit"[[:space:]]*:' "$file"; then
      err "$file: 标准 ${kind} 页必须声明最小 action.submit"
    fi
    if [[ "$kind" == "list" ]] && rg -q '"type"[[:space:]]*:[[:space:]]*"form-switch"|"editor"[[:space:]]*:' "$file" && ! has_inline_edit_save_handler "$file"; then
      err "$file: 标准列表存在内联编辑/状态切换时必须声明 show-table.meta.savePath"
    fi
  fi

  if rg -q '/front/route/action|https?://[^"[:space:]]*/front/route/action' "$file"; then
    err "$file: page JSON 不能硬编码 route/action URL；请使用当前 site runtime"
  fi
}

check_forbidden_page_protocol() {
  local file="$1"

  if rg -q '"_model"[[:space:]]*:|"_use"[[:space:]]*:|"<<[^"]*New[A-Za-z0-9_]*Model>>|"\{\{[^"]*Service[^"]*\}\}"|"childUse"[[:space:]]*:|"modelName"[[:space:]]*:|"modelPath"[[:space:]]*:|"transform"[[:space:]]*:|"service@[A-Za-z0-9_.-]+|"type"[[:space:]]*:[[:space:]]*"service"' "$file"; then
    err "$file: page JSON 存在禁止协议；请改为自动推导或显式 model/service，不要写 _model/_use/<<Model>>/{{Service}}/type:service/childUse/modelName/modelPath/service@/transform"
  fi
  if rg -q -U '"option"[[:space:]]*:[[:space:]]*\{[^}]*"use"[[:space:]]*:' "$file"; then
    err "$file: option 不能写 use；请改为 option.model 或 option.service"
  fi
  if rg -q '"/front/route/option([?#][^"]*)?"' "$file"; then
    err "$file: page JSON 不能手写 /front/route/option；请改为自动推导或显式 model/service 对象"
  fi
  if rg -q -U '"meta"[[:space:]]*:[[:space:]]*\{[^}]*"use"[[:space:]]*:' "$file"; then
    err "$file: meta 不能写 use；请改为 meta.model/meta.service 或 meta.childModel/meta.childService"
  fi
  if has_direct_submit_use "$file"; then
    err "$file: action.submit 不能写 use；跨资源保存请改为 action.submit.model，hook 请写 before/after.service"
  fi
}

check_option_params_protocol() {
  local file="$1"

  if rg -q -U '"optionParams"[[:space:]]*:[[:space:]]*\{[^}]*"(parentField|childParentField|valueField|labelField|leafField|extraFields|searchFields|filterField|filterValue|filters|order|pageSize)"[[:space:]]*:' "$file"; then
    err "$file: optionParams 只传 parentId/selected/keyword/level 等动态值；parentField/valueField/labelField/extraFields/pageSize/order/filters 等静态配置请放到 option 或 meta"
  fi
}

check_page_field_boundary() {
  local file="$1"
  local system_fields='code|key|slug|sn|no|created_at|updated_at|created_by|updated_by|author|author_id|editor|editor_id|creator|creator_id|operator|operator_id'

  if rg -q '"value"[[:space:]]*:[[:space:]]*"form\.('"$system_fields"')"' "$file"; then
    warn "$file: form 中出现系统/审计/派生字段；请确认不是 code/key/slug/作者/编辑/创建人/更新人等手填项"
  fi

  if rg -q '"\$form\.('"$system_fields"')"' "$file"; then
    warn "$file: action 或校验中引用系统/审计/派生字段；请确认该字段允许从表单提交"
  fi

  if rg -q -U '\{[^{}]*"type"[[:space:]]*:[[:space:]]*"form-(input|textarea)"[^{}]*"value"[[:space:]]*:[[:space:]]*"form\.(cate_id|category_id|type|kind|group_id)"' "$file" ||
     rg -q -U '\{[^{}]*"value"[[:space:]]*:[[:space:]]*"form\.(cate_id|category_id|type|kind|group_id)"[^{}]*"type"[[:space:]]*:[[:space:]]*"form-(input|textarea)"' "$file"; then
    warn "$file: 分类/类型/分组字段看起来是自由输入；优先使用 Options/Relations/form-select/form-cascader/show-category-list"
  fi
}

has_direct_submit_use() {
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
      if (depth == 1 && $0 ~ /"use"[[:space:]]*:/) {
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

has_inline_edit_save_handler() {
  local file="$1"
  rg -q '"savePath"[[:space:]]*:' "$file" || rg -q '"change"[[:space:]]*:' "$file"
}

check_service_api() {
  local file="$1"
  [[ "$file" == *.go ]] || return 0

  if [[ "$file" == */service/* ]]; then
    if rg -q 'Provider[A-Za-z0-9_]+\(.*params \[\]any\) any' "$file" &&
       rg -q 'return record|return params\[0\]|return map\[string\]any\{\}' "$file"; then
      warn "$file: Provider 看起来只是透传；只保留真实校验、规范化或适配 hook"
    fi
    if rg -q 'func .* (Save|List|Create|Update|Delete|GetInfo|HandleData|Process)[A-Za-z0-9_]*\(' "$file"; then
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
done < <(collect_files)

if (( fail != 0 )); then
  exit 1
fi

if (( warn_count > 0 )); then
  echo "dever skill audit 通过，有 ${warn_count} 个警告"
else
  echo "dever skill audit 通过"
fi
