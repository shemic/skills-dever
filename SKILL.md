---
name: shemic-dever
description: Use when bootstrapping or developing a Dever-based Go project, especially for config/model/service/provider/api/middleware work that relies on init-based code generation.
---

# shemic-dever

## Overview

这个 skill 同时覆盖：
1. 空项目冷启动
2. 现有 Dever 项目继续开发

主参考：
- `references/module.md`（module 业务开发主手册）
- `references/boot.md`（冷启动入口）
- `scripts/boot.sh`（一键初始化脚本）
- `scripts/module.sh`（业务模块脚手架脚本）

## When to Use

出现以下任一情况时使用：

- 空项目要从 0 搭建 Dever 工程
- 新增模块或改动 `module/*` 下代码
- 新增/修改 Model、Service、Provider、API、中间件
- 需要确认 `Dever.Load` 可调用写法
- 需要统一执行注册文件生成流程

## Mode Selection

1. 冷启动模式：项目还没有完整骨架（缺少 `go.mod` / `main.go` / `module` / `config`）。
2. 迭代模式：项目骨架已存在，仅做业务增量开发。
3. 业务实现模式：无论冷启动还是迭代，只要要写 `module` 业务代码，都按 `references/module.md` 执行。

## Mandatory Rules

1. 框架来源是 `github.com/shemic/dever`（来自 `go.mod`），不要依赖本地 `./dever` 目录命令。
2. 改了 `module` 目录代码后，执行一次：
   - `go run github.com/shemic/dever/cmd/dever@main init --skip-tidy`
3. 不要手改生成文件：
   - `data/router.go`
   - `data/load/model.go`
   - `data/load/service.go`
4. API 参数统一使用 `c.Input(...)`（包含 path/query/form/json body 字段）。
5. API 必须是结构体方法，方法前缀使用 `Get/Post/Put/Delete`。
6. 如需严格可复现，优先使用 `go.mod` 中锁定的 dever 版本号替代 `@main`。

## Cold-Start Workflow (Empty Project)

当项目是空的或仅有 `go.mod` 时：

1. 优先运行脚本：
   - `bash scripts/boot.sh <module_name> [dever_version] [app_name] [port]`
2. 按需生成业务模块骨架：
   - `bash scripts/module.sh <module_dir> <resource_name> [dever_version]`
3. 再按 `references/module.md` 写业务代码。

## Iteration Workflow (Existing Project)

1. 明确本次改动属于哪类：`config` / `model` / `service` / `api` / `middleware`。
2. 需要新资源时先生成骨架：
   - `bash scripts/module.sh <module_dir> <resource_name> [dever_version]`
3. 在 `module/<name>` 下实现业务代码（严格按 `references/module.md`）。
4. 执行一次初始化生成：
   - `go run github.com/shemic/dever/cmd/dever@main init --skip-tidy`
5. 检查生成文件是否正确更新。
6. 汇报变更时给出：
   - 改动文件列表
   - 路由清单
   - `load` 注册名清单

## Requirement-To-Interface Delivery

当输入是“需求描述”，按这个顺序产出接口：

1. 从需求提取：模块名、资源名、接口动作（list/info/add/update/delete）、权限规则、状态规则。
2. 先生成骨架：
   - `bash scripts/module.sh <module_dir> <resource_name> [dever_version]`
3. 再补业务规则：
   - Model 字段和索引
   - Service 校验和状态流转
   - API 入参与错误返回
   - Provider（如果要被 `Dever.Load` 调用）
4. 执行一次：
   - `go run github.com/shemic/dever/cmd/dever@main init --skip-tidy`
5. 输出路由与 load 注册名给开发者确认。

## How To Use `references/module.md`

这是业务开发主线文档，默认必读。

使用方式：

1. 新建模块：直接按该文档的“新建模块完整流程（从 0 写业务）”执行。
2. 续写模块：按“续写现有模块完整流程（增量改业务）”执行。
3. 代码层面严格遵守其模板：Model -> Service -> Provider -> API -> Middleware -> init 生成。

## Quick Conventions

### Config
- 配置文件：`config/setting.json`
- 读取入口：`github.com/shemic/dever/config` 的 `Load("")`

### Model
- 使用 `orm.LoadModel[T](...)`
- `module/*/model` 中尽量只放模型相关导出函数，避免误被扫描注册

### Service + Provider
- 业务方法可自由签名（推荐 `ctx + 明确参数`）
- Provider 推荐签名：
  - `func (XxxService) ProviderAbc(c *server.Context, params []any) any`
- Provider 名称按生成结果调用（不要手写猜测）

### API
- 结构体方法映射路由
- 返回统一使用 `c.JSON(...)` / `c.Error(...)`
- 鉴权用户一般从 `mid.GetUid(c.Context())` 获取
- 参数统一走 `c.Input(...)`

### Middleware
- 统一在 `middleware/Register()` 挂载
- 全局优先 `coremiddleware.Init()` + 项目自定义中间件

## Optional Debug Commands

仅在排查问题时按需执行：

- `go run github.com/shemic/dever/cmd/dever@main model`
- `go run github.com/shemic/dever/cmd/dever@main service`
- `go run github.com/shemic/dever/cmd/dever@main routes`

## Done Criteria

满足以下条件才算完成：

1. 模式选择正确（冷启动/迭代）
2. 业务代码与目录约定一致
3. `init --skip-tidy` 已执行
4. 生成文件已更新且未手改
5. 输出包含路由与 load 注册信息
6. 若涉及 module 业务改动，已按 `references/module.md` 的交付要求输出业务规则说明
