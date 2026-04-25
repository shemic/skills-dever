---
name: shemic-dever
description: Use when bootstrapping or developing a Dever-based Go project, especially for config, package/front-backed module page JSON, model, service, provider, api, middleware, jwt, and observe work that relies on init-based code generation and Dever runtime conventions.
---

# shemic-dever

## Overview

这个 skill 同时覆盖：
1. 空项目冷启动
2. 现有 Dever 项目继续开发

主参考：
- `references/module.md`（module 业务开发主手册）
- `references/front-page.md`（业务 module 如何使用 package/front 编写后台页面 JSON）
- `references/boot.md`（冷启动入口）
- `scripts/boot.sh`（一键初始化脚本）
- `scripts/module.sh`（业务模块脚手架脚本）

## When to Use

出现以下任一情况时使用：

- 空项目要从 0 搭建 Dever 工程
- 新增模块或改动 `module/*` 下代码
- 新增/修改 Model、Service、Provider、API、中间件
- 新增/修改 `module/*/page/**/*.json(c)` 页面协议
- 基于 `package/front` 写业务后台列表页、编辑页、详情页、统计页、导入导出、上传或资源库页面
- 在项目初始化或老项目接入后台时安装/加载 `package/front`（例如 `dever package front`，或按 front 手册补齐等价接入文件）
- 配置 `frontmeta.Options` / `frontmeta.Relations` 来支撑后台页面选项和关联字段
- 接入或调整 JWT、observe、结构化日志
- 需要确认 `Dever.Load` 可调用写法
- 需要统一执行注册文件生成流程

## Mode Selection

1. 冷启动模式：项目还没有完整骨架（缺少 `go.mod` / `main.go` / `module` / `config`）。
2. 迭代模式：项目骨架已存在，仅做业务增量开发。
3. 业务实现模式：无论冷启动还是迭代，只要要写 `module` 业务代码，都按 `references/module.md` 执行。
4. 后台页面模式：只要要写 `module/*/page/**/*.json(c)` 或使用 `package/front`，先按 `references/front-page.md` 检查 front 接入，再写 model/meta/page。

## Mandatory Rules

1. 框架来源优先看 `go.mod`：
   - 常规项目：使用 `github.com/shemic/dever`
   - 如果项目显式 `replace github.com/shemic/dever => ./dever`，再使用本地 `./dever` 命令
2. 主开发流程统一为：
   - 先执行一次 `install`
   - 后续统一使用 `dever run`
3. 发布打包统一使用 `dever build`
   - 无参数默认打包当前项目根目录 `main.go`
   - `dever build cmd/worker` 会自动打包 `cmd/worker/main.go`
   - 默认产物面向 release：`linux/amd64`、`trimpath`、`buildvcs=false`、`-ldflags="-s -w -buildid="`
4. `dever run` 已经负责：
   - 启动前执行 `init --skip-tidy`
   - 监听 `model/service/api` 等敏感变更后自动重新执行 `init --skip-tidy`
5. 显式执行 `init/routes/service/model` 只作为调试和排查手段，不再作为日常主流程
6. 不要手改生成文件：
   - `data/router.go`
   - `data/load/model.go`
   - `data/load/service.go`
7. API 参数统一使用 `c.Input(...)`（包含 path/query/form/json body 字段）。
8. API 必须是结构体方法，方法前缀使用 `Get/Post/Put/Delete`。
9. 如需严格可复现，优先使用 `go.mod` 中锁定的 dever 版本号替代 `@main`。
10. 能复用 `dever` 的，不要在项目层重复写第二套：
   - util 转换
   - JWT 校验
   - observe 埋点
   - 结构化日志
11. 能复用既有项目代码就复用：
   - 先找现有 model/service/provider/middleware/page JSON/frontmeta/helper
   - 可安全扩展现有实现时，不新建平行实现
   - 重复流程必须抽成清晰的 service/helper/config，而不是复制粘贴
12. 代码必须简单好读：
   - API 薄，Service 承载业务，Model 只放结构和构造
   - 函数职责单一、命名表达业务意图、控制流尽量平铺
   - 不为“以后可能用到”提前加复杂抽象、继承式基类或多余层级
13. 默认按高性能、高可用、高并发设计：
   - 查询必须考虑索引、分页、条件下推，避免全表扫描和 N+1
   - 外部调用要有超时、错误处理、可观测日志，重试只用于幂等场景
   - 并发场景避免无保护的包级可变状态；共享状态用 DB/Redis/锁/事务保证一致性
14. 严格按 Dever 框架开发：
   - 优先复用 `dever/orm`、`dever/load`、`dever/server`、`dever/util`、`dever/log`、`dever/observe`
   - 不绕过 Dever 自己实现第二套路由、模型加载、配置加载、日志和观测体系

## Cold-Start Workflow (Empty Project)

当项目是空的或仅有 `go.mod` 时：

1. 优先运行脚本：
   - `bash scripts/boot.sh <module_name> [dever_version] [app_name] [port]`
2. 安装 `dever` 命令：
   - 常规项目：`go run github.com/shemic/dever/cmd/dever@main install`
   - 本地框架项目：`go run ./dever/cmd/dever install`
3. 启动开发流程：
   - `dever run`
4. 按需生成业务模块骨架：
   - `bash scripts/module.sh <module_dir> <resource_name> [dever_version]`
5. 如果要做后台页面，先按 `references/front-page.md` 接入/检查 `package/front`。
6. 再按 `references/module.md` 写业务代码。

## Iteration Workflow (Existing Project)

1. 明确本次改动属于哪类：`config` / `model` / `service` / `api` / `middleware`。
2. 如未安装 `dever`，先执行一次：
   - 常规项目：`go run github.com/shemic/dever/cmd/dever@main install`
   - 本地框架项目：`go run ./dever/cmd/dever install`
3. 需要新资源时先生成骨架：
   - `bash scripts/module.sh <module_dir> <resource_name> [dever_version]`
4. 如果本次涉及后台页面，先按 `references/front-page.md` 确认 front 路由、菜单、权限和页面读取链路。
5. 保持 `dever run` 运行，敏感改动会自动刷新生成文件和重启服务。
6. 在 `module/<name>` 下实现业务代码（严格按 `references/module.md`）。
7. 检查生成文件是否正确更新。
8. 汇报变更时给出：
   - 改动文件列表
   - 路由清单
   - `load` 注册名清单

## Requirement-To-Interface Delivery

当输入是“需求描述”，按这个顺序产出接口：

1. 从需求提取：模块名、资源名、接口动作（list/info/add/update/delete）、权限规则、状态规则。
2. 先生成骨架：
   - `bash scripts/module.sh <module_dir> <resource_name> [dever_version]`
3. 如果需要后台页面，先确认 `package/front` 已接入，并采用 `New<Resource>Model` 这类能被 front 默认模型解析命中的构造函数命名。
4. 再补业务规则：
   - Model 字段和索引
   - Service 校验和状态流转
   - API 入参与错误返回
   - Provider（如果要被 `Dever.Load` 调用）
5. 确保 `dever run` 正在运行，敏感改动会自动刷新生成文件。
6. 输出路由与 load 注册名给开发者确认。

## How To Use `references/module.md`

这是业务开发主线文档，默认必读。

使用方式：

1. 新建模块：直接按该文档的“新建模块完整流程（从 0 写业务）”执行。
2. 续写模块：按“续写现有模块完整流程（增量改业务）”执行。
3. 代码层面严格遵守其模板：Model -> Service -> Provider -> API -> Middleware -> init 生成。

## How To Use `references/front-page.md`

这是业务 module 消费 `package/front` 通用后台能力的页面开发手册。

当任务涉及以下内容时读取：

- 新增或修改 `module/*/page/**/*.json(c)`
- 初始化或检查 `package/front` 是否已经安装、导入、路由生成
- 基于 model 写列表页、编辑页、详情页、统计页
- 配置后台菜单、layout、nodes、action、data、state
- 配置筛选、表格、表单、弹窗、抽屉、tab
- 配置导入、导出、上传、资源库
- 使用 `frontmeta.Options` / `frontmeta.Relations`
- 让业务模块复用 `package/front` 的通用后台能力，而不是重复造 CRUD 和页面运行时

## Quick Conventions

### Engineering Constraints
- 复用优先：先搜索同类 model/service/provider/helper/page JSON/frontmeta；能扩展就不要复制一套。
- 封装适度：重复流程抽 service/helper/config；不要抽没有实际复用价值的空层。
- 简单可读：API 只取参/调服务/返回；Service 写业务规则；函数短小、命名明确、少嵌套。
- 性能优先：列表接口必须考虑索引、分页、字段选择、批量查询，避免全表扫描、N+1、无界 goroutine。
- 可用性优先：外部依赖要设置超时、记录结构化错误、可降级；重试必须确认幂等。
- 并发安全：不要用未加锁的包级可变状态缓存请求数据；状态流转使用事务、唯一索引、锁或幂等键。
- Dever 优先：框架已有能力优先用 `orm/load/server/util/log/observe/auth/jwt`，不要绕开框架造第二套。

### Config
- 配置文件：`config/setting.json(c)`
- 读取入口：`github.com/shemic/dever/config` 的 `Load("")`
- `setting.jsonc`、`front.jsonc`、`module/*/page/**/*.jsonc` 现在支持 JSONC
- `data/table/*.json` 是生成文件，不要写注释，不要手改

### Model
- 使用 `orm.LoadModel[T](...)`
- `module/*/model` 中尽量只放模型相关导出函数，避免误被扫描注册

### Service + Provider
- 业务方法可自由签名（推荐 `ctx + 明确参数`）
- Provider 推荐签名：
  - `func (XxxService) ProviderAbc(c *server.Context, params []any) any`
- Provider 名称按生成结果调用（不要手写猜测）
- 先检查 `dever/util` 是否已有可复用 helper，优先复用：
  - `util.ToString`
  - `util.ToStringTrimmed`
  - `util.ParseInt64`
  - `util.ParseUint64`
  - `util.ParseFloat64`
  - `util.ParseBool`
  - `util.ToBool`
  - `util.ToKeyString`
  - `util.CloneMap`
  - `util.CloneMapSlice`
  - `util.FirstNonEmpty`
  - `util.ToSnake`
  - `util.UniqueUint64s`
- 不要在 `module/*/service` 里重复写：
  - `mapString`
  - `mapInt`
  - `NormalizeUint64`
  - `toSnake`
  - `isTrueValue`
  - `normalizeOptionSeedValue`

### API
- 结构体方法映射路由
- 返回统一使用 `c.JSON(...)` / `c.Error(...)`
- 鉴权用户一般从 `mid.GetUid(c.Context())` 获取
- 参数统一走 `c.Input(...)`

### Middleware
- 统一在 `middleware/Register()` 挂载
- 全局优先 `coremiddleware.Init()` + 项目自定义中间件
- JWT 认证优先复用 `dever/auth/jwt`
- 单 JWT 继续兼容 `config.auth.jwtSecret`
- 多 JWT 走 `config.auth.jwt.schemes + guards`
- 业务层尽量只保留薄装配和 `GetUid(...)` 一类包装，不要再手写 Bearer 解析、签名校验、claims 注入

### Observe
- 框架自观测统一放在 `dever/observe`
- 默认内置 provider 负责慢请求、慢 SQL、错误日志
- 外部观测通过 `observe.Register(name, factory)` 注册，再由 `config.observe.provider` 启用
- 框架内置 provider：
  - `builtin`
  - `http`
  - `webhook`
- 配置统一走 `config/setting.json(c)` 的 `observe` 段：
  - `enabled`
  - `provider`
  - `service`
  - `slowRequest`
  - `slowSQL`
  - `options`
- 请求观测优先挂在框架默认中间件里，不要在业务 API 里手写重复埋点
- 数据库观测优先挂在 `dever/orm` 执行器里，不要在业务 service 里重复包一层计时

### Log
- 当前日志是结构化 JSON，优先复用 `dever/log`
- 链路字段以：
  - `trace_id`
  - `span_id`
  为准，不再额外造 `request_id`

### Install + Run
- 日常开发主流程：
  1. `install`
  2. `dever run`
- `dever run` 会自动处理：
  - 启动前 `init --skip-tidy`
  - 敏感文件变更后的重新生成与热重载
- 不要把 `go run ... init --skip-tidy` 当成日常主命令再反复写进项目文档、脚本或交付说明

### Build
- 发布打包统一使用 `dever build`
- 常见用法：
  - 当前项目：`dever build`
  - 子命令：`dever build cmd/workflow-worker`
  - 指定输出：`dever build -o dist/server`
- 默认是 release 构建：
  - `CGO_ENABLED=0`
  - `GOOS=linux`
  - `GOARCH=amd64`
  - `-trimpath`
  - `-buildvcs=false`
  - `-ldflags="-s -w -buildid="`
- 如目标需要 cgo，再显式传：
  - `dever build --cgo=true`

## Optional Debug Commands

仅在排查问题时按需执行：

- `go run github.com/shemic/dever/cmd/dever@main model`
- `go run github.com/shemic/dever/cmd/dever@main service`
- `go run github.com/shemic/dever/cmd/dever@main routes`
- 如果项目本地 `replace` 到 `./dever`，对应改成：
  - `go run ./dever/cmd/dever model`
  - `go run ./dever/cmd/dever service`
  - `go run ./dever/cmd/dever routes`

## Done Criteria

满足以下条件才算完成：

1. 模式选择正确（冷启动/迭代）
2. 业务代码与目录约定一致
3. 已检查可复用代码，没有留下不必要重复实现
4. API/Service/Model 职责清晰，代码简单可读
5. 已考虑性能、可用性、并发安全的关键风险
6. `dever run` 已覆盖自动初始化，或已按需手动执行生成命令
7. 生成文件已更新且未手改
8. 输出包含路由与 load 注册信息
9. 若涉及 module 业务改动，已按 `references/module.md` 的交付要求输出业务规则说明
