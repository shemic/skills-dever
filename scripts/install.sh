#!/usr/bin/env bash
set -euo pipefail

DEVER_MODULE="${DEVER_MODULE:-github.com/shemic/dever/cmd/dever}"
DEVER_VERSION="${DEVER_VERSION:-latest}"
REQUIRED_GO_VERSION="${REQUIRED_GO_VERSION:-1.25.3}"
GO_DOWNLOAD_BASE="${GO_DOWNLOAD_BASE:-https://go.dev/dl}"
PROJECT_ROOT="${PWD}"
BIN_DIR="${DEVER_BIN_DIR:-}"
DEVER_HOME="${DEVER_HOME:-${HOME:-}/.dever}"
GO_ROOT="${DEVER_GO_ROOT:-${DEVER_HOME}/go}"
SKIP_SKILL=0
SKIP_TRELLIS=0
SKIP_TRELLIS_PROJECT=0
TRELLIS_VERSION="${TRELLIS_VERSION:-latest}"
TRELLIS_USER="${TRELLIS_USER:-}"
USING_DEVER_GO=0
DEVER_GO_NEEDS_PATH=0

usage() {
  cat <<'EOF'
用法：bash scripts/install.sh [--project-root=.] [--bin-dir=] [--skip-skill] [--skip-trellis] [--skip-trellis-project] [--trellis-user=] [--trellis-version=latest]

自动安装 Go，安装 Dever CLI，同步 shemic-dever skill，并通过 Dever 安装/初始化 Trellis。

环境变量：
  REQUIRED_GO_VERSION  Go 最低版本，默认 1.25.3
  DEVER_GO_ROOT        Go 安装目录，默认 ~/.dever/go
  DEVER_VERSION        Dever 安装版本，默认 latest
  DEVER_BIN_DIR        Dever 命令安装目录
  TRELLIS_VERSION      Trellis npm 版本或 dist-tag，默认 latest
  TRELLIS_USER         Trellis 开发者名称，默认由 Dever 自动检测
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root=*)
      PROJECT_ROOT="${1#--project-root=}"
      shift
      ;;
    --project-root)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "错误：--project-root 需要参数。" >&2
        exit 1
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
        exit 1
      fi
      BIN_DIR="${2:-}"
      shift 2
      ;;
    --skip-skill|--skip-skills)
      SKIP_SKILL=1
      shift
      ;;
    --skip-trellis)
      SKIP_TRELLIS=1
      shift
      ;;
    --skip-trellis-project)
      SKIP_TRELLIS_PROJECT=1
      shift
      ;;
    --trellis-user=*)
      TRELLIS_USER="${1#--trellis-user=}"
      shift
      ;;
    --trellis-user)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "错误：--trellis-user 需要参数。" >&2
        exit 1
      fi
      TRELLIS_USER="${2:-}"
      shift 2
      ;;
    --trellis-version=*)
      TRELLIS_VERSION="${1#--trellis-version=}"
      shift
      ;;
    --trellis-version)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "错误：--trellis-version 需要参数。" >&2
        exit 1
      fi
      TRELLIS_VERSION="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "未知参数：$1" >&2
      usage
      exit 1
      ;;
  esac
done

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
    printf '%s/%s\n' "$(cd "$parent" && pwd -P)" "$name"
    return
  fi

  printf '%s\n' "$path"
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
  exit 1
}

install_go() {
  local platform os arch archive url tmpdir go_parent

  platform="$(detect_go_platform)"
  read -r os arch <<< "$platform"

  require_command tar "自动安装 Go 需要 tar。请先安装 tar 后重新运行。"
  if [[ -z "${HOME:-}" && -z "${DEVER_GO_ROOT:-}" ]]; then
    echo "错误：无法确定 HOME，请设置 DEVER_GO_ROOT 指定 Go 安装目录。" >&2
    exit 1
  fi

  GO_ROOT="$(absolute_dir "$(dirname "$GO_ROOT")")/$(basename "$GO_ROOT")"
  case "$GO_ROOT" in
    /|/usr|/usr/*|/System|/System/*|/Library|/Library/*|/opt/homebrew|/opt/homebrew/*)
      echo "错误：自动安装不会写入系统 Go 目录：$GO_ROOT。请设置 DEVER_GO_ROOT 到用户目录后重试。" >&2
      exit 1
      ;;
  esac
  archive="go${REQUIRED_GO_VERSION}.${os}-${arch}.tar.gz"
  url="${GO_DOWNLOAD_BASE}/${archive}"
  tmpdir="$(mktemp -d)"

  echo "自动安装 Go ${REQUIRED_GO_VERSION}: $url"
  download_file "$url" "$tmpdir/$archive"
  tar -C "$tmpdir" -xzf "$tmpdir/$archive"

  if [[ ! -x "$tmpdir/go/bin/go" ]]; then
    echo "错误：Go 安装包内容异常：$archive" >&2
    rm -rf "$tmpdir"
    exit 1
  fi

  go_parent="$(dirname "$GO_ROOT")"
  mkdir -p "$go_parent"
  rm -rf "$GO_ROOT"
  mv "$tmpdir/go" "$GO_ROOT"
  rm -rf "$tmpdir"

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

ensure_go
require_command git "dever skill install 需要 git 拉取 skills-dever。请先安装 git。"

PROJECT_ROOT="$(absolute_dir "$PROJECT_ROOT")"
if [[ -z "$BIN_DIR" ]]; then
  BIN_DIR="$(default_bin_dir)"
fi
if [[ -z "$BIN_DIR" ]]; then
  echo "错误：无法确定安装目录，请使用 --bin-dir 指定。" >&2
  exit 1
fi
BIN_DIR="$(absolute_dir "$BIN_DIR")"

echo "安装 Dever CLI: ${DEVER_MODULE}@${DEVER_VERSION}"
GOBIN="$BIN_DIR" go install "${DEVER_MODULE}@${DEVER_VERSION}"

DEVER_BIN="$BIN_DIR/dever"
if [[ ! -x "$DEVER_BIN" ]]; then
  echo "错误：安装后未找到 dever 命令：$DEVER_BIN" >&2
  exit 1
fi

echo "Dever CLI 已安装: $DEVER_BIN"
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
  SKILL_ARGS=(skill install --project-root="$PROJECT_ROOT")
  if [[ "$SKIP_TRELLIS" == "1" ]]; then
    SKILL_ARGS+=(--trellis=false)
  else
    SKILL_ARGS+=(--trellis-version="$TRELLIS_VERSION")
    if [[ "$SKIP_TRELLIS_PROJECT" == "1" ]]; then
      SKILL_ARGS+=(--trellis-project=false)
    fi
    if [[ -n "$TRELLIS_USER" ]]; then
      SKILL_ARGS+=(--trellis-user="$TRELLIS_USER")
    fi
  fi
  "$DEVER_BIN" "${SKILL_ARGS[@]}"
fi

echo "完成。下一步："
echo "  dever skill doctor --project-root=\"$PROJECT_ROOT\""
