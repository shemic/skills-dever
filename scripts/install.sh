#!/usr/bin/env bash
set -euo pipefail

DEVER_MODULE="${DEVER_MODULE:-github.com/shemic/dever/cmd/dever}"
DEVER_VERSION="${DEVER_VERSION:-latest}"
REQUIRED_GO_VERSION="${REQUIRED_GO_VERSION:-1.25.3}"
GO_DOWNLOAD_BASE="${GO_DOWNLOAD_BASE:-https://go.dev/dl}"
GO_DOWNLOAD_METADATA_URL="${GO_DOWNLOAD_METADATA_URL:-https://go.dev/dl/?mode=json&include=all}"
PROJECT_ROOT="${PWD}"
BIN_DIR="${DEVER_BIN_DIR:-}"
DEVER_HOME="${DEVER_HOME:-${HOME:-}/.dever}"
GO_ROOT="${DEVER_GO_ROOT:-${DEVER_HOME}/go}"
DEVER_MANAGED_GO_MARKER=".dever-managed-go"
SKIP_SKILL=0
USING_DEVER_GO=0
DEVER_GO_NEEDS_PATH=0

usage() {
  cat <<'EOF'
用法：bash scripts/install.sh [--project-root=.] [--bin-dir=] [--skip-skill]

自动安装 Go，安装 Dever CLI，并同步 shemic-dever skill。

环境变量：
  REQUIRED_GO_VERSION  Go 最低版本，默认 1.25.3
  DEVER_GO_ROOT        Go 安装目录，默认 ~/.dever/go
  GO_DOWNLOAD_BASE     Go 归档下载地址，默认 https://go.dev/dl
  GO_DOWNLOAD_METADATA_URL  Go 官方下载清单地址
  DEVER_VERSION        Dever 安装版本，默认 latest
  DEVER_BIN_DIR        Dever 命令安装目录
EOF
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-root=*)
        PROJECT_ROOT="${1#--project-root=}"
        shift
        ;;
      --project-root)
        if [[ $# -lt 2 || -z "${2:-}" ]]; then
          echo "错误：--project-root 需要参数。" >&2
          return 1
        fi
        PROJECT_ROOT="${2:-}"
        shift 2
        ;;
      --bin-dir=*)
        BIN_DIR="${1#--bin-dir=}"
        shift
        ;;
      --bin-dir)
        if [[ $# -lt 2 || -z "${2:-}" ]]; then
          echo "错误：--bin-dir 需要参数。" >&2
          return 1
        fi
        BIN_DIR="${2:-}"
        shift 2
        ;;
      --skip-skill|--skip-skills)
        SKIP_SKILL=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "未知参数：$1" >&2
        usage
        return 1
        ;;
    esac
  done
}

require_command() {
  local name="$1"
  local message="$2"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "错误：未检测到 $name。" >&2
    echo "$message" >&2
    exit 1
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

absolute_dir() {
  local path="$1"
  mkdir -p "$path"
  (cd "$path" && pwd -P)
}

join_absolute_path() {
  local parent="$1"
  local child="$2"

  if [[ "$parent" == "/" ]]; then
    printf '/%s\n' "$child"
    return
  fi
  printf '%s/%s\n' "$parent" "$child"
}

normalize_dir() {
  local path="$1"
  local parent name

  [[ "$path" = /* ]] || path="$PWD/$path"
  if [[ -d "$path" ]]; then
    (cd "$path" && pwd -P)
    return
  fi

  parent="$(dirname "$path")"
  name="$(basename "$path")"
  if [[ -d "$parent" ]]; then
    join_absolute_path "$(cd "$parent" && pwd -P)" "$name"
    return
  fi

  printf '%s\n' "$path"
}

canonical_go_root() {
  local path="$1"
  local parent name suffix

  if [[ -z "$path" ]]; then
    echo "错误：Go 安装目录不能为空。" >&2
    return 1
  fi
  while [[ "$path" != "/" && "$path" == */ ]]; do
    path="${path%/}"
  done
  [[ "$path" = /* ]] || path="$PWD/$path"
  if [[ "$path" == "/" ]]; then
    printf '/\n'
    return
  fi
  case "/$path/" in
    */../*|*/./*)
      echo "错误：Go 安装目录不能包含 . 或 .. 路径段：$path" >&2
      return 1
      ;;
  esac
  if [[ -L "$path" ]]; then
    echo "错误：Go 安装目录不能是符号链接：$path" >&2
    return 1
  fi

  parent="$(dirname "$path")"
  name="$(basename "$path")"
  if [[ "$name" == "." || "$name" == ".." || -z "$name" ]]; then
    echo "错误：Go 安装目录不合法：$path" >&2
    return 1
  fi
  suffix="$name"
  while [[ ! -d "$parent" ]]; do
    if [[ -e "$parent" || -L "$parent" ]]; then
      echo "错误：Go 安装目录的父路径不是目录：$parent" >&2
      return 1
    fi
    suffix="$(basename "$parent")/$suffix"
    parent="$(dirname "$parent")"
  done
  join_absolute_path "$(cd "$parent" && pwd -P)" "$suffix"
}

directory_has_entries() {
  local directory="$1"
  local entry

  for entry in "$directory"/* "$directory"/.[!.]* "$directory"/..?*; do
    if [[ -e "$entry" || -L "$entry" ]]; then
      return 0
    fi
  done
  return 1
}

path_contains_protected_root() {
  local candidate="$1"
  local protected="$2"

  [[ "$protected" == "$candidate" || "$protected" == "$candidate/"* ]]
}

validate_go_root() {
  local default_root normalized_home normalized_dever_home normalized_project_root

  GO_ROOT="$(canonical_go_root "$GO_ROOT")" || return 1
  default_root="$(canonical_go_root "${DEVER_HOME}/go")" || return 1
  normalized_home="$(normalize_dir "${HOME:-/}")"
  normalized_dever_home="$(normalize_dir "$DEVER_HOME")"
  normalized_project_root="$(normalize_dir "$PROJECT_ROOT")"

  case "$GO_ROOT" in
    /|/bin|/bin/*|/boot|/boot/*|/dev|/dev/*|/etc|/etc/*|/lib|/lib/*|/lib32|/lib32/*|/lib64|/lib64/*|/proc|/proc/*|/root|/run|/run/*|/sbin|/sbin/*|/sys|/sys/*|/usr|/usr/*|/var|/var/*|/private/etc|/private/etc/*|/private/run|/private/run/*|/private/var|/private/var/*|/System|/System/*|/Library|/Library/*|/opt/homebrew|/opt/homebrew/*)
      echo "错误：自动安装不会写入系统目录：$GO_ROOT。请设置 DEVER_GO_ROOT 到专用用户目录后重试。" >&2
      return 1
      ;;
  esac
  if path_contains_protected_root "$GO_ROOT" "$normalized_home" ||
     path_contains_protected_root "$GO_ROOT" "$normalized_dever_home" ||
     path_contains_protected_root "$GO_ROOT" "$normalized_project_root"; then
    echo "错误：Go 安装目录不能指向或包含 HOME、DEVER_HOME 或项目根目录：$GO_ROOT" >&2
    return 1
  fi
  if [[ -e "$GO_ROOT" && ! -d "$GO_ROOT" ]]; then
    echo "错误：Go 安装目录已存在且不是目录：$GO_ROOT" >&2
    return 1
  fi
  if [[ ! -d "$GO_ROOT" || "$GO_ROOT" == "$default_root" || -f "$GO_ROOT/$DEVER_MANAGED_GO_MARKER" ]]; then
    return 0
  fi

  if directory_has_entries "$GO_ROOT"; then
    echo "错误：拒绝替换未由 Dever 管理的非空 Go 目录：$GO_ROOT" >&2
    echo "请使用新的空目录，或继续使用默认目录 ${default_root}。" >&2
    return 1
  fi
  return 0
}

is_dir_in_path() {
  local target="$1"
  local current
  target="$(normalize_dir "$target")"
  IFS=':' read -r -a path_items <<< "${PATH:-}"
  for current in "${path_items[@]}"; do
    [[ -z "$current" ]] && continue
    if [[ "$(normalize_dir "$current")" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

default_bin_dir() {
  local home="${HOME:-}"
  if [[ -z "$home" ]]; then
    echo ""
    return
  fi
  if is_dir_in_path "$home/.local/bin"; then
    echo "$home/.local/bin"
    return
  fi
  if is_dir_in_path "$home/go/bin"; then
    echo "$home/go/bin"
    return
  fi
  echo "$home/.local/bin"
}

parse_go_version() {
  local version="$1"
  if [[ "$version" =~ ^go ]]; then
    version="${version#go}"
  fi
  if [[ "$version" =~ ^([0-9]+)\.([0-9]+)(\.([0-9]+))? ]]; then
    printf '%s %s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[4]:-0}"
    return 0
  fi
  return 1
}

go_version_at_least() {
  local current="$1"
  local required="$2"
  local current_tuple required_tuple
  local current_major current_minor current_patch
  local required_major required_minor required_patch

  current_tuple="$(parse_go_version "$current")" || return 1
  required_tuple="$(parse_go_version "$required")" || return 1
  read -r current_major current_minor current_patch <<< "$current_tuple"
  read -r required_major required_minor required_patch <<< "$required_tuple"

  if (( current_major != required_major )); then
    if (( current_major > required_major )); then
      return 0
    fi
    return 1
  fi
  if (( current_minor != required_minor )); then
    if (( current_minor > required_minor )); then
      return 0
    fi
    return 1
  fi
  if (( current_patch >= required_patch )); then
    return 0
  fi
  return 1
}

current_go_version() {
  go version | awk '{print $3}'
}

go_is_ready() {
  command_exists go && go_version_at_least "$(current_go_version)" "$REQUIRED_GO_VERSION"
}

detect_go_platform() {
  local os arch
  case "$(uname -s)" in
    Linux)
      os="linux"
      ;;
    Darwin)
      os="darwin"
      ;;
    CYGWIN*|MINGW*|MSYS*)
      echo "Windows 暂不支持自动安装 Go。请安装 Go ${REQUIRED_GO_VERSION}+ 后重新运行：https://go.dev/dl/" >&2
      return 1
      ;;
    *)
      echo "当前系统暂不支持自动安装 Go：$(uname -s)。请安装 Go ${REQUIRED_GO_VERSION}+ 后重新运行：https://go.dev/dl/" >&2
      return 1
      ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64)
      arch="amd64"
      ;;
    arm64|aarch64)
      arch="arm64"
      ;;
    *)
      echo "当前 CPU 架构暂不支持自动安装 Go：$(uname -m)。请安装 Go ${REQUIRED_GO_VERSION}+ 后重新运行：https://go.dev/dl/" >&2
      return 1
      ;;
  esac

  printf '%s %s\n' "$os" "$arch"
}

download_file() {
  local url="$1"
  local output="$2"

  if command_exists curl; then
    curl -fsSL "$url" -o "$output"
    return
  fi
  if command_exists wget; then
    wget -qO "$output" "$url"
    return
  fi
  echo "错误：自动安装 Go 需要 curl 或 wget。" >&2
  return 1
}

go_archive_checksum() {
  local metadata="$1"
  local archive="$2"

  awk -v target="$archive" '
    /"filename"[[:space:]]*:/ {
      filename = $0
      sub(/^.*"filename"[[:space:]]*:[[:space:]]*"/, "", filename)
      sub(/".*$/, "", filename)
      matched = (filename == target)
    }
    matched && /"sha256"[[:space:]]*:/ {
      checksum = $0
      sub(/^.*"sha256"[[:space:]]*:[[:space:]]*"/, "", checksum)
      sub(/".*$/, "", checksum)
      print checksum
      exit
    }
  ' "$metadata"
}

sha256_file() {
  local file="$1"

  if command_exists sha256sum; then
    sha256sum "$file" | awk '{print $1}'
    return
  fi
  if command_exists shasum; then
    shasum -a 256 "$file" | awk '{print $1}'
    return
  fi
  echo "错误：校验 Go 安装包需要 sha256sum 或 shasum。" >&2
  return 1
}

verify_go_archive() {
  local archive_path="$1"
  local metadata_path="$2"
  local archive_name="$3"
  local expected actual

  expected="$(go_archive_checksum "$metadata_path" "$archive_name")"
  if [[ ! "$expected" =~ ^[0-9a-fA-F]{64}$ ]]; then
    echo "错误：Go 官方下载清单中未找到归档校验和：$archive_name" >&2
    return 1
  fi
  actual="$(sha256_file "$archive_path")" || return 1
  actual="$(printf '%s' "$actual" | tr '[:upper:]' '[:lower:]')"
  expected="$(printf '%s' "$expected" | tr '[:upper:]' '[:lower:]')"
  if [[ "$actual" != "$expected" ]]; then
    echo "错误：Go 安装包 SHA-256 校验失败：$archive_name" >&2
    return 1
  fi
}

replace_go_root() {
  local staged_root="$1"
  local go_parent backup=""

  go_parent="$(dirname "$GO_ROOT")"
  if [[ -e "$GO_ROOT" ]]; then
    backup="$(mktemp -d "${go_parent}/.dever-go-backup.XXXXXX")"
    rmdir "$backup"
    if ! mv "$GO_ROOT" "$backup"; then
      return 1
    fi
  fi

  if ! mv "$staged_root" "$GO_ROOT"; then
    if [[ -n "$backup" ]]; then
      mv "$backup" "$GO_ROOT" || echo "错误：恢复旧 Go 目录失败：$backup" >&2
    fi
    return 1
  fi
  if [[ -n "$backup" ]] && ! rm -rf -- "$backup"; then
    echo "警告：旧 Go 目录未能清理：$backup" >&2
  fi
}

install_go() {
  local platform os arch archive url tmpdir go_parent metadata stage_version

  platform="$(detect_go_platform)"
  read -r os arch <<< "$platform"

  require_command tar "自动安装 Go 需要 tar。请先安装 tar 后重新运行。"
  if [[ -z "${HOME:-}" && -z "${DEVER_GO_ROOT:-}" ]]; then
    echo "错误：无法确定 HOME，请设置 DEVER_GO_ROOT 指定 Go 安装目录。" >&2
    exit 1
  fi

  validate_go_root || return 1
  archive="go${REQUIRED_GO_VERSION}.${os}-${arch}.tar.gz"
  url="${GO_DOWNLOAD_BASE}/${archive}"
  go_parent="$(dirname "$GO_ROOT")"
  mkdir -p "$go_parent"
  tmpdir="$(mktemp -d "${go_parent}/.dever-go-install.XXXXXX")"
  metadata="$tmpdir/releases.json"

  echo "自动安装 Go ${REQUIRED_GO_VERSION}: $url"
  if ! download_file "$url" "$tmpdir/$archive"; then
    rm -rf -- "$tmpdir"
    return 1
  fi
  if ! download_file "$GO_DOWNLOAD_METADATA_URL" "$metadata"; then
    rm -rf -- "$tmpdir"
    return 1
  fi
  if ! verify_go_archive "$tmpdir/$archive" "$metadata" "$archive"; then
    rm -rf -- "$tmpdir"
    return 1
  fi
  if ! tar -C "$tmpdir" -xzf "$tmpdir/$archive"; then
    rm -rf -- "$tmpdir"
    return 1
  fi

  if [[ ! -x "$tmpdir/go/bin/go" ]]; then
    echo "错误：Go 安装包内容异常：$archive" >&2
    rm -rf -- "$tmpdir"
    return 1
  fi
  stage_version="$("$tmpdir/go/bin/go" version 2>/dev/null | awk '{print $3}')"
  if ! go_version_at_least "$stage_version" "$REQUIRED_GO_VERSION"; then
    echo "错误：Go 安装包版本异常：${stage_version:-unknown}" >&2
    rm -rf -- "$tmpdir"
    return 1
  fi
  : > "$tmpdir/go/$DEVER_MANAGED_GO_MARKER"
  if ! replace_go_root "$tmpdir/go"; then
    rm -rf -- "$tmpdir"
    return 1
  fi
  rm -rf -- "$tmpdir"

  if ! is_dir_in_path "$GO_ROOT/bin"; then
    DEVER_GO_NEEDS_PATH=1
  fi
  export PATH="$GO_ROOT/bin:$PATH"
  USING_DEVER_GO=1
  hash -r 2>/dev/null || true
  echo "Go 已安装: $GO_ROOT/bin/go"
}

ensure_go() {
  if go_is_ready; then
    echo "Go 已就绪: $(go version)"
    return
  fi

  if [[ -x "$GO_ROOT/bin/go" ]]; then
    if ! is_dir_in_path "$GO_ROOT/bin"; then
      DEVER_GO_NEEDS_PATH=1
    fi
    export PATH="$GO_ROOT/bin:$PATH"
    USING_DEVER_GO=1
    hash -r 2>/dev/null || true
    if go_is_ready; then
      echo "Go 已就绪: $(go version)"
      return
    fi
  fi

  if command_exists go; then
    echo "当前 Go 版本低于 ${REQUIRED_GO_VERSION}: $(go version)"
  else
    echo "未检测到 Go，开始自动安装。"
  fi
  install_go

  if ! go_is_ready; then
    echo "错误：Go 安装后仍不可用，请检查 PATH 或安装目录：$GO_ROOT" >&2
    exit 1
  fi
}

main() {
  local dever_bin

  parse_arguments "$@"
  ensure_go
  require_command git "dever skill install 需要 git 拉取 skills-dever。请先安装 git。"

  PROJECT_ROOT="$(absolute_dir "$PROJECT_ROOT")"
  if [[ -z "$BIN_DIR" ]]; then
    BIN_DIR="$(default_bin_dir)"
  fi
  if [[ -z "$BIN_DIR" ]]; then
    echo "错误：无法确定安装目录，请使用 --bin-dir 指定。" >&2
    return 1
  fi
  BIN_DIR="$(absolute_dir "$BIN_DIR")"

  echo "安装 Dever CLI: ${DEVER_MODULE}@${DEVER_VERSION}"
  GOBIN="$BIN_DIR" go install "${DEVER_MODULE}@${DEVER_VERSION}"

  dever_bin="$BIN_DIR/dever"
  if [[ ! -x "$dever_bin" ]]; then
    echo "错误：安装后未找到 dever 命令：$dever_bin" >&2
    return 1
  fi

  echo "Dever CLI 已安装: $dever_bin"
  if [[ "$USING_DEVER_GO" == "1" && "$DEVER_GO_NEEDS_PATH" == "1" ]]; then
    echo "建议将 Go 加入 PATH:"
    echo "  export PATH=\"$GO_ROOT/bin:\$PATH\""
  fi
  if ! is_dir_in_path "$BIN_DIR"; then
    echo "请将安装目录加入 PATH:"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
  fi

  if [[ "$SKIP_SKILL" != "1" ]]; then
    echo "同步 shemic-dever skill 和项目提示词: $PROJECT_ROOT"
    "$dever_bin" skill install --project-root="$PROJECT_ROOT"
  fi

  echo "完成。下一步："
  echo "  dever skill doctor --project-root=\"$PROJECT_ROOT\""
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
