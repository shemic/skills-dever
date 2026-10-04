#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/tools"
cat > "$TEST_ROOT/tools/go" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  version)
    echo 'go version go1.25.3 linux/amd64'
    ;;
  install)
    printf '%s\n' "$@" > "$INSTALL_TEST_CASE/go.args"
    package="${2%@*}"
    cp "$INSTALL_TEST_ROOT/cli" "$GOBIN/${package##*/}"
    chmod +x "$GOBIN/${package##*/}"
    ;;
  *)
    exit 1
    ;;
esac
EOF
cat > "$TEST_ROOT/cli" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$0" "$@" > "$INSTALL_TEST_CASE/cli.args"
EOF
cat > "$TEST_ROOT/forbidden" <<'EOF'
#!/usr/bin/env bash
echo "不应调用：$0" >&2
exit 1
EOF
for command_name in git curl wget; do
  cp "$TEST_ROOT/forbidden" "$TEST_ROOT/tools/$command_name"
done
chmod +x "$TEST_ROOT/tools/"*

run_case() {
  local case_name="$1"
  local module="$2"
  local version="$3"
  local skip_skill="$4"
  local case_root="$TEST_ROOT/$case_name"
  local -a arguments

  mkdir -p "$case_root/bin" "$case_root/project with spaces"
  cp "$TEST_ROOT/forbidden" "$case_root/bin/dever"
  chmod +x "$case_root/bin/dever"
  arguments=(--project-root "$case_root/project with spaces" --bin-dir "$case_root/bin")
  if [[ "$skip_skill" == 1 ]]; then
    arguments=(--project-root="$case_root/project with spaces" --skip-skills)
  fi

  env -i PATH="$TEST_ROOT/tools:$case_root/bin:/usr/bin:/bin" \
    INSTALL_TEST_ROOT="$TEST_ROOT" INSTALL_TEST_CASE="$case_root" \
    DEVER_MODULE="$module" DEVER_VERSION="$version" \
    DEVER_HOME="$case_root/dever-home" DEVER_BIN_DIR="$case_root/bin" \
    bash "$REPO_ROOT/scripts/install.sh" "${arguments[@]}" > "$case_root/output"

  printf '%s\n' install "${module:-github.com/shemic/dever/cmd/dever-go}@${version:-latest}" > "$case_root/expected-go"
  cmp "$case_root/expected-go" "$case_root/go.args"
  test -x "$case_root/bin/dever-go"
  cmp "$TEST_ROOT/forbidden" "$case_root/bin/dever"
  test -x "$case_root/bin/dever"
  grep -Fq "dever-go skill doctor --project-root=\"$case_root/project with spaces\"" "$case_root/output"
  if [[ "$skip_skill" == 1 ]]; then
    test ! -e "$case_root/cli.args"
  else
    printf '%s\n' "$case_root/bin/dever-go" skill install "--project-root=$case_root/project with spaces" > "$case_root/expected-cli"
    cmp "$case_root/expected-cli" "$case_root/cli.args"
  fi
}

run_case default '' '' 0
run_case custom github.com/example/dever/cmd/dever-go main 1

rejected_root="$TEST_ROOT/legacy-module"
mkdir -p "$rejected_root/bin"
cp "$TEST_ROOT/forbidden" "$rejected_root/bin/dever"
if env -i PATH="$TEST_ROOT/tools:/usr/bin:/bin" \
  INSTALL_TEST_ROOT="$TEST_ROOT" INSTALL_TEST_CASE="$rejected_root" \
  DEVER_MODULE=github.com/shemic/dever/cmd/dever DEVER_HOME="$rejected_root/dever-home" \
  bash "$REPO_ROOT/scripts/install.sh" --bin-dir="$rejected_root/bin" --skip-skill > "$rejected_root/output" 2>&1; then
  echo '旧命令包不应被接受' >&2
  exit 1
fi
cmp "$TEST_ROOT/forbidden" "$rejected_root/bin/dever"
test ! -e "$rejected_root/go.args"
grep -Fq 'DEVER_MODULE 的命令包名称必须是 dever-go' "$rejected_root/output"
echo '安装器定向测试通过（默认安装、环境覆盖、跳过 skill、保留原有 dever、拒绝旧命令包）'
