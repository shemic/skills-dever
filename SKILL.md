---
name: shemic-dever
description: Use when 开发 Dever Go 项目，包括冷启动、完整后台/admin、package/front page JSON、model、service、provider、api、middleware、JWT、observe、config、Dever.Load、dever run/build 和生成注册文件等场景。
---

# shemic-dever

## 用途

本 skill 用于 Dever Go 项目的两类任务：

1. 冷启动：从零创建可运行的 Dever 项目。
2. 迭代开发：在现有项目中新增或修改 model、service、provider、api、middleware、config、observe、JWT 或 `package/front` page JSON。

主要参考：

| 任务 | 先读 | 再用 |
| --- | --- | --- |
| 空项目 / 冷启动 | `references/boot.md` | `scripts/boot.sh`，再读 `references/module.md` |
| 完整后端 / 管理后台 | `references/project.md` | `references/module.md`、`references/front-page.md` |
| 业务后端代码 | `references/module.md` | 需要 API/Provider 骨架时用 `scripts/module.sh` |
| 后台 / page JSON | `references/front-page.md` | 需要 service/provider hook 时读 `references/module.md` |

## 触发条件

任务涉及以下任一内容时使用本 skill：

- 冷启动 Dever 项目。
- 从需求开发完整后端或管理后台系统。
- 新增或修改 `module/*` 业务代码。
- 新增或修改 Model、Service、Provider、API、middleware、JWT、observe、日志或 config。
- 新增或修改 `module/*/page/**/*.json(c)` 或 `package/*/page/**/*.json(c)`。
- 基于 `package/front` 编写后台 CRUD、列表、编辑、详情、统计、导入导出、上传或资源库页面。
- 安装/加载 `package/front`，或配置 `frontmeta.Options` / `frontmeta.Relations`。
- 确认 `Dever.Load`、生成注册、路由或 Dever 命令流程。

## 模式路由

1. 冷启动：项目缺少完整骨架（`go.mod`、`main.go`、`module`、`config`）时，先读 `references/boot.md`。
2. 完整项目：用户给的是业务目标而不是单个文件改动时，先读 `references/project.md`，编码前产出模块、模型、页面、动作、Service/API 矩阵。
3. 业务实现：只要写承载业务规则的后端代码，就读 `references/module.md`，不限于 `module/*`。
4. 后台页面：只要写后台、admin、CRUD 页面，就读 `references/front-page.md`；即使用户没说 JSON，也默认 page JSON。
5. 现有项目：新增平行实现前，先搜索可复用 model、service、provider、middleware、page JSON、frontmeta 和 config。

## 硬规则

1. 框架来源以 `go.mod` 为准。
   - 常规项目使用 `github.com/shemic/dever`。
   - 如果 `go.mod` 显式 `replace github.com/shemic/dever => ./dever`，使用本地 `./dever` 命令。
   - 需要可复现时，优先使用 `go.mod` 锁定的 Dever 版本，不优先用 `@main`。
2. 日常开发流程是先 `install` 一次，再 `dever run`。
   - `dever run` 启动前会执行 `init --skip-tidy`，并在敏感 `model/service/api` 变更后刷新生成注册。
   - 手动 `init/routes/service/model` 只用于调试。
3. 禁止手改生成文件：
   - `data/router.go`
   - `data/load/model.go`
   - `data/load/service.go`
4. 冷启动项目必须建立 `.gitignore`。
   - 忽略本地密钥、运行时数据、下载/生成的 package、打包产物和编辑器目录。
   - `data` 和 `package` 默认只保留 `readme.txt` 占位文件。
   - 默认内容按 `files/gitignore` 和 `references/boot.md` 的 `.gitignore` 约定执行。
5. API 必须薄。
   - API 必须是结构体方法，方法名前缀使用 `Get/Post/Put/Delete`。
   - 所有请求字段用 `c.Input(...)` 获取。
   - API 只取参、调用 Service、返回 `c.JSON(...)` 或 `c.Error(...)`；不要在 handler 里写长业务流程。
6. 优先复用 Dever 和现有项目代码。
   - 优先复用 `orm/load/server/util/log/observe/auth/jwt` 以及已有 model、service、provider、middleware、page JSON、frontmeta。
   - 不要在项目层重复造第二套路由、模型加载、配置加载、日志、observe、JWT 或 util 系统。
7. 所有业务后端代码都遵守通用开发约束，不限于 `module/*/service`。
   - 写代码前先搜索可复用实现，禁止复制一套平行逻辑。
   - 业务流程先从用例开始，再按真实职责拆分。
   - 禁止假抽象、固定模板拆文件、无意义单行转发、单实现 interface、桶文件（`helper/utils/common/value/manager`）和单文件微目录。
   - 命名必须短、清晰，复用目录和 package 语义；不要用长文件名、长类型名或多段下划线掩盖职责混乱。
   - 同一稳定领域出现多个文件时必须收进子目录；已有领域目录时，同域新增文件必须放进去。
   - 实现后必须做清理检查（cleanup pass），删除未使用、重复、临时、旧分支、旧配置和无意义 wrapper。
   - 只要代码承载业务规则、状态流转、外部调用、任务处理、页面 hook、worker 或中间件策略，就必须按 `references/module.md` 的 Service 规则写。
8. 性能和并发安全不是可选项。
   - 列表必须考虑索引、分页、字段选择和批量查询；避免全表扫描和 N+1。
   - 外部调用必须有超时、结构化错误/日志；重试只用于幂等操作。
   - 状态流转、唯一创建、计数器和共享状态必须用事务、唯一索引、锁或幂等键兜底。
9. 后台页面默认使用 `package/front + page JSON`。
   - 普通 CRUD 不需要自定义 API。
   - 复杂保存、校验、规范化、跨表逻辑放到 Service/Provider hook。
   - 只有用户明确要求，或 `front-page.md` 证明缺少可复用运行时能力，才改前端 runtime。
10. 页面归属按代码归属。
   - 项目业务模块页面放 `module/<module>/page/**/*.json(c)`。
   - 可复用 package 页面放 `package/<package>/page/**/*.json(c)`。
   - 如果 `module/<name>/main.go` 只是引入 package，页面仍放 package，不复制到 module。
   - 可见页面的 `page.parent` 用 `config/front.json(c)` 菜单 key；隐藏编辑、详情、弹窗页面用入口页面 path。
11. page JSON 必须使用 model 元信息。
   - 枚举、状态、分类列必须有 `data.option.<field>` 或 `column.meta.option`，不要展示内部原始值。
   - 标准 `/list`、`/update`、`/create`、`/detail` 页面应从 Model comment、Options、Relations 推导 label、option 和 relation。
   - `/set`、`/config` 和自定义弹窗页必须显式指定 model：列表用 `data.table.list: "<<ModelName>>"`，表单用 `data.form._model` / `_use`，保存用 submit `use`，保证推导链路可用。
12. 禁止猜 page JSON 节点、action 或 meta。
   - 先读 `references/front-page.md`。
   - 如需样例，只参考 GitHub 上的 `demo`、`package/front`、`package/bot`、`module/user`；不要把当前 workspace 的页面副本当标准。

## 工作流程

### 冷启动

1. 读 `references/boot.md`。
2. 执行 `bash scripts/boot.sh <module_name> [dever_version] [app_name] [port] [--force]`。
3. 确认 `.gitignore` 已创建或补齐 Dever ignore block。
4. 安装 Dever 一次：
   - 常规项目：`go run github.com/shemic/dever/cmd/dever@main install`
   - 本地 replace：`go run ./dever/cmd/dever install`
5. 启动 `dever run`。
6. 确实需要业务 API/Provider 骨架时执行 `bash scripts/module.sh <module_dir> <resource_name> [dever_version] [--force]`。
7. 如果需要后台页面，写 page JSON 前先读 `references/front-page.md`。

### 完整项目

1. 读 `references/project.md`。
2. 产出模块、模型、页面、动作、Service/API 边界矩阵。
3. 先设计 Model：字段、注释、Options、Relations、索引。
4. 再设计后台信息架构：菜单分组、可见页面、隐藏编辑/详情/弹窗页面、parent path。
5. 普通 CRUD 使用 Model + page JSON。
6. 只有真实业务逻辑、外部协议、状态流转、异步任务或跨表规则才写 Service/Provider/API。
7. 交付时列出 model 清单、page 清单、Service/Provider 清单、API 路由清单、使用说明和未执行项。

### 迭代开发

1. 判断改动类型：`config`、`model`、`service`、`provider`、`api`、`middleware` 或 page JSON。
2. 先搜索现有实现。
3. 新增资源时，默认用 `scripts/module.sh` 的覆盖保护；确认替换同名文件时才加 `--force`。
4. 写 page JSON 时，按 `references/front-page.md` 确认页面归属、菜单 parent、model 推导、front route 和 service hook 边界。
5. 尽量保持 `dever run` 运行；敏感变更会自动刷新生成文件。
6. 汇报时给出改动文件、路由和 load 注册名。

### 从需求到接口

1. 从需求提取 module、resource、动作、权限、状态和错误。
2. 后台 CRUD 优先使用 Model + page JSON。
3. 校验、状态和跨表规则写 Service。
4. `Dever.Load` 或页面 hook 写 Provider。
5. 非后台 CRUD 的 HTTP 行为才写 API。
6. 输出路由和 load 注册名。

## 快速约定

- 配置文件：`config/setting.json(c)`、`config/front.json(c)`。
- config 和 page 文件支持 JSONC；生成的 `data/table/*.json` 必须保持普通 JSON，且不能手改。
- `.gitignore` 必须保留 Dever ignore block：忽略 `/server`、`/dist/`、`/build/`、`/data/*`、`/package/*`、`.env*`、`config/*.local.json(c)`；只反向保留 `/data/readme.txt` 和 `/package/readme.txt`。
- Model 构造函数使用 `orm.LoadModel[T](...)`；`module/*/model` 保持模型相关导出，避免误注册。
- 业务 Service 方法可自由签名，推荐 `ctx + 明确参数`。
- Provider 方法格式：`func (XxxService) ProviderAbc(c *server.Context, params []any) any`。
- Provider 名称以生成注册为准，不要手写猜测。
- 写转换函数前，先检查 `dever/util`，例如 `ToStringTrimmed`、`ParseInt64`、`ParseUint64`、`ParseFloat64`、`ParseBool`、`ToBool`、`ToKeyString`、`CloneMap`、`CloneMapSlice`、`ToSnake`、`UniqueUint64s`。
- 鉴权用户通常从项目 middleware helper 获取，例如 `mid.GetUid(c.Context())`。
- middleware 统一在 `middleware/Register()` 挂载。
- JWT 优先复用 `dever/auth/jwt`；业务 middleware 只做薄装配。
- Observe/log 复用 `dever/observe` 和 `dever/log`；不要在业务 API/Service 里重复包计时埋点。
- 日志是结构化 JSON；链路字段以 `trace_id`、`span_id` 为准。

## 命令

日常：

1. `install`
2. `dever run`

构建：

- 使用 `dever build`。
- 示例：`dever build`、`dever build cmd/worker`、`dever build -o dist/server`。
- 默认 release 输出：`linux/amd64`、`CGO_ENABLED=0`、`trimpath`、`buildvcs=false`、`-ldflags="-s -w -buildid="`。
- 只有需要 cgo 时才显式启用：`dever build --cgo=true`。

仅调试：

- `go run github.com/shemic/dever/cmd/dever@main model`
- `go run github.com/shemic/dever/cmd/dever@main service`
- `go run github.com/shemic/dever/cmd/dever@main routes`
- 本地 replace 时用 `go run ./dever/cmd/dever <model|service|routes>`。

## 完成标准

完成前检查：

1. 模式和 reference 文件选择正确。
2. 已搜索可复用代码。
3. Model/API/Service/Provider/page 职责清晰。
4. 生成文件已按需刷新，且未手改。
5. 已考虑性能、可用性和并发风险。
6. Service 代码避免假抽象，并遵守 `references/module.md`。
7. 涉及 page JSON 时，已遵守 `references/front-page.md`。
8. 最终回复包含改动文件、路由、load 注册、使用方式和未执行的验证项。
