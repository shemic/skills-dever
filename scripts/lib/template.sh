#!/usr/bin/env bash

dever_template_require_single_line() {
  local name="$1"
  local value="$2"

  if [[ "$value" =~ [[:cntrl:]] ]]; then
    echo "错误：${name} 只能是无控制字符的单行文本。" >&2
    return 1
  fi
}

dever_template_json_escape() {
  local value="$1"

  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

dever_template_sed_escape() {
  local value="$1"

  value="${value//\\/\\\\}"
  value="${value//&/\\&}"
  value="${value//|/\\|}"
  printf '%s' "$value"
}

dever_template_commit() {
  local temporary="$1"
  local destination="$2"
  local force="$3"

  if [[ -e "$destination" && "$force" == "1" ]]; then
    if ! cp -p "$destination" "${destination}.bak"; then
      rm -f "$temporary"
      return 1
    fi
  fi
  if ! mv "$temporary" "$destination"; then
    rm -f "$temporary"
    return 1
  fi
}

dever_render_template() {
  local source="$1"
  local destination="$2"
  local force="$3"
  local mode key value rendered escaped temporary
  local -a expressions=()
  shift 3

  if [[ ! -f "$source" ]]; then
    echo "模板不存在：$source" >&2
    return 1
  fi
  if [[ -e "$destination" && "$force" != "1" ]]; then
    return 0
  fi
  if (( $# == 0 || $# % 3 != 0 )); then
    echo "错误：模板变量必须按 <raw|json|text> <name> <value> 传入。" >&2
    return 1
  fi

  while (( $# > 0 )); do
    mode="$1"
    key="$2"
    value="$3"
    shift 3

    if [[ ! "$key" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
      echo "错误：模板变量名不合法：$key" >&2
      return 1
    fi
    dever_template_require_single_line "$key" "$value" || return 1
    case "$mode" in
      raw|text)
        rendered="$value"
        ;;
      json)
        rendered="$(dever_template_json_escape "$value")"
        ;;
      *)
        echo "错误：未知模板变量模式：$mode" >&2
        return 1
        ;;
    esac
    escaped="$(dever_template_sed_escape "$rendered")"
    expressions+=("-e" "s|{{${key}}}|${escaped}|g")
  done

  mkdir -p "$(dirname "$destination")"
  temporary="$(mktemp "${destination}.tmp.XXXXXX")"
  if ! sed "${expressions[@]}" "$source" > "$temporary"; then
    rm -f "$temporary"
    return 1
  fi
  if ! chmod 0644 "$temporary"; then
    rm -f "$temporary"
    return 1
  fi
  dever_template_commit "$temporary" "$destination" "$force"
}

dever_copy_template_file() {
  local source="$1"
  local destination="$2"
  local force="$3"
  local temporary

  if [[ ! -f "$source" ]]; then
    echo "模板不存在：$source" >&2
    return 1
  fi
  if [[ -e "$destination" && "$force" != "1" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$destination")"
  temporary="$(mktemp "${destination}.tmp.XXXXXX")"
  if ! cp -p "$source" "$temporary"; then
    rm -f "$temporary"
    return 1
  fi
  dever_template_commit "$temporary" "$destination" "$force"
}
