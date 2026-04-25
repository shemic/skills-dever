# Empty Project Bootstrap (Dever)

优先用脚本，不手工拷大量模板。

## 一键初始化

```bash
bash scripts/boot.sh <module_name> [dever_version] [app_name] [port]
```

示例：

```bash
bash scripts/boot.sh my main my-app 8082
```

## 脚本会做什么

1. 初始化/复用 `go.mod`
2. 安装 `github.com/shemic/dever@<version>`
3. 生成可运行骨架（`main.go`、`middleware/init.go`、`module/main/api/{ping,debug}.go`、`module/main/service/echo.go`、`config/setting.jsonc`）
4. 安装 `dever` 命令：
   - 常规项目：`go run github.com/shemic/dever/cmd/dever@<version> install`
   - 如果 `go.mod` 显式 `replace github.com/shemic/dever => ./dever`：`go run ./dever/cmd/dever install`
5. 后续开发统一通过：
   - `dever run`

## 当前推荐开发流程

1. 冷启动脚手架：`bash scripts/boot.sh ...`
2. 脚本会自动执行 `install`
3. 启动开发：`dever run`
4. 如果要做后台页面，按 `references/front-page.md` 接入/检查 `package/front`
5. 需要发布产物时：`dever build`

说明：

- `dever run` 会在启动前自动执行 `init --skip-tidy`
- 改动 `model/service/api` 等敏感文件后，也会自动重新执行 `init --skip-tidy`
- 日常开发不再把 `go run ... init --skip-tidy` 当成主命令
- 需要 Linux 发布包时，统一使用 `dever build`

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
5. 创建业务模块骨架：
   - `bash scripts/module.sh <module_dir> <resource_name> [dever_version]`
6. 如果要开发后台页面，先完成 `package/front` 初始化检查
7. 按 `references/module.md` 继续完善业务规则
8. 需要发布当前服务时：
   - `dever build`
