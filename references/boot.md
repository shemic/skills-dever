# Empty Project Bootstrap (Dever)

优先用脚本，不手工拷大量模板。

## 一键初始化

```bash
bash scripts/boot.sh <module_name> [dever_version] [app_name] [port] [--force]
```

示例：

```bash
bash scripts/boot.sh my main my-app 8082
```

## 脚本会做什么

1. 初始化/复用 `go.mod`
2. 安装 `github.com/shemic/dever@<version>`
3. 生成/补齐 `.gitignore`
4. 生成可运行骨架（`main.go`、`middleware/init.go`、`module/main/api/{ping,debug}.go`、`module/main/service/echo.go`、`config/setting.jsonc`）
5. 安装 `dever` 命令：
   - 常规项目：`go run github.com/shemic/dever/cmd/dever@<version> install`
   - 如果 `go.mod` 显式 `replace github.com/shemic/dever => ./dever`：`go run ./dever/cmd/dever install`
6. 后续开发统一通过：
   - `dever run`

脚本默认拒绝覆盖已有核心文件；确认要重置这些文件时才加 `--force`。

## 当前推荐开发流程

1. 冷启动脚手架：`bash scripts/boot.sh ...`
2. 脚本会自动执行 `install`
3. 启动开发：`dever run`
4. 如果用户要做完整项目，先按 `references/project.md` 拆模块、模型、页面和动作矩阵
5. 如果要做后台页面，默认按 `package/front + page JSON`，按 `references/front-page.md` 接入/检查 `package/front`
6. 需要发布产物时：`dever build`

说明：

- `dever run` 会在启动前自动执行 `init --skip-tidy`
- 改动 `model/service/api` 等敏感文件后，也会自动重新执行 `init --skip-tidy`
- 日常开发不再把 `go run ... init --skip-tidy` 当成主命令
- 需要 Linux 发布包时，统一使用 `dever build`

## `.gitignore` 约定

Dever 冷启动项目必须建立 `.gitignore`。脚本会创建或追加一个带 marker 的 Dever ignore block；已有 `.gitignore` 不会被整体覆盖。

默认内容见 `files/gitignore`，不要在文档里重复维护完整模板，避免和脚本写入内容漂移。

手动冷启动时，可以直接把 `files/gitignore` 复制为项目根目录 `.gitignore`。如果项目已经有 `.gitignore`，只追加 `files/gitignore` 里的 Dever ignore block；如果已经存在 marker，则不要重复追加。

核心规则是：`data` 和 `package` 目录只保留占位文件，其余内容由本地运行、下载或生成得到。

冷启动脚本会创建：

- `data/readme.txt`
- `package/readme.txt`

`data/router.go`、`data/load/*.go`、`data/table/*.json` 等由 `dever run` / `init` 在本地刷新，不手改、不默认提交。

## 生成的默认配置约定

- 配置文件默认用 `config/setting.jsonc`
- 日志默认是结构化 JSON，不再配置 `log.encoding`
- 默认保留：
  - `auth.jwtSecret`（单 JWT）
  - `observe` 基础配置
  - `http.cors` 基础配置
- 如果后续需要多 JWT，再在 `auth.jwt.schemes + guards` 下扩展

## 下一步

1. 运行 `dever run` 验证服务可启动
2. 验证示例接口：
   - `GET /ping/index`
   - `GET /health/check`
   - `POST /debug/echo`（`msg` 支持 query/form/json，统一由 `c.Input` 读取）
3. 如果当前 shell 里还找不到 `dever`，优先检查：
   - `install` 是否执行成功
   - 用户 bin 目录是否已加入 `PATH`
4. 如果项目是本地联调 `./dever`，优先检查 `go.mod` 是否已有：
   - `replace github.com/shemic/dever => ./dever`
5. 确认 `.gitignore` 存在，并且 `data/readme.txt`、`package/readme.txt` 作为占位文件存在
6. 如果是完整项目，先读 `references/project.md`，不要直接从单个 API 开始写
7. 确实需要自定义 API/Provider 时创建业务骨架：
   - `bash scripts/module.sh <module_dir> <resource_name> [dever_version]`
8. 如果要开发后台页面，默认走 page JSON，先完成 `package/front` 初始化检查
9. 按 `references/module.md` 继续完善业务规则
10. 需要发布当前服务时：
   - `dever build`
