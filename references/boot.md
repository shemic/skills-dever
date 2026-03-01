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
3. 生成可运行骨架（`main.go`、`middleware/init.go`、`module/main/api/{ping,debug}.go`、`module/main/service/echo.go`、`config/setting.json`）
4. 执行一次：
   - `go run github.com/shemic/dever/cmd/dever@<version> init --skip-tidy`

## 下一步

1. 运行 `go run .` 验证服务可启动
2. 验证示例接口：
   - `GET /ping/index`
   - `GET /health/check`
   - `POST /debug/echo`（`msg` 支持 query/form/json，统一由 `c.Input` 读取）
3. 创建业务模块骨架：
   - `bash scripts/module.sh <module_dir> <resource_name> [dever_version]`
4. 按 `references/module.md` 继续完善业务规则
