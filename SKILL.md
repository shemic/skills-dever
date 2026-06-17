---
name: shemic-dever
description: 用于 Dever Go 项目开发；修改 model、service、provider、api、page JSON、front 插件、package/module 组件、config/front.json、Dever CLI、生成路由/load 文件、package/front 后台页、package/bot、package/user，或排查注册、权限、页面、option、logo、install、build、run、plugin 错误时必须使用。
version: 1.0.0
---

# shemic-dever

使用本 skill 开发 Dever 项目时，必须优先复用框架能力，而不是绕过框架另写一套。代码要保持简单直接：先检查当前项目结构，复用已有 `package/front` 行为，只写必要的 model/page/service 代码，不手改生成文件和编译产物。

## 阅读顺序

只读取当前任务需要的 reference：

- `references/workflow.md`：决策顺序和任务分流。
- `references/product.md`：业务产品拆分、模块边界、页面/API/Service 选择。
- `references/framework.md`：Dever CLI、生成文件、route/model/service 注册、middleware。
- `references/development.md`：复用、命名、职责边界、清理。
- `references/model.md`：model 文件、comment、Options、Relations、索引。
- `references/front-page.md`：`package/front` page JSON 规则、自动推导、后台/站点页面。
- `references/service-api.md`：什么时候允许写 Provider、Service、API。
- `references/files.md`：配置模板、logo/favicon、AGENTS block、静态文件。
- `references/component.md`：package/module 组件、组件 skill、`dever.json`。
- `references/package-plugin.md`：package/module front 插件源码和构建产物。
- `references/security.md`：权限、action、公开路由、密钥、上传安全。
- `references/troubleshooting.md`：常见 Dever 错误和优先排查点。
- `references/migration.md`：旧项目和旧组件升级规则。

## 任务分流

- 空项目、安装、新站点、admin/work/site 搭建：读 `workflow.md`、`empty-project.md`、`framework.md`、`files.md`、`component.md`。
- 旧项目、已有项目、迁移、升级、历史组件、老页面改造：读 `workflow.md`、`migration.md`，再按涉及面读取 `front-page.md`、`service-api.md`、`component.md`。
- 新产品、业务系统、业务模块、需求拆分、产品功能设计：读 `workflow.md`、`product.md`，再按资源类型读取 `model.md`、`front-page.md`、`service-api.md`。
- 后端 model 或表结构修改：读 `model.md`；涉及页面时再读 `front-page.md`。
- 后台页面、CRUD、列表/编辑/详情、左分类右列表、权限或 option 错误：读 `front-page.md`、`model.md`、`security.md`。
- Provider、Service、API、回调、登录、注册、workflow、外部请求、事务：读 `service-api.md`、`security.md`。
- config、logo、favicon、AGENTS、静态资产、公开文件：读 `files.md`。
- `package/front`、`package/bot`、`package/user`、module/package 组件：读 `component.md`；如果组件自带 `skills/**/SKILL.md`，继续读组件 skill。
- Front plugin 或 React node：读 `package-plugin.md`；除非确实需要自定义交互节点，否则优先用 page JSON。
- Dever CLI、生成文件、import cycle、run/build/install 问题：读 `framework.md`、`troubleshooting.md`。

## 硬规则

- `shemic-dever` 的唯一维护源是 `github.com/shemic/skills-dever`; Dever 框架仓库只负责安装和检查，不维护完整内嵌副本。
- 不手改生成文件：`data/router.go`、`data/load/model.go`、`data/load/service.go`、`data/table/*.json`。
- 不通过修改 `package/front/html/assets/index*.js` 等编译产物来改行为、logo、文案或样式。
- 应用项目 Go module 固定使用 `my`；不要改成项目名、域名或目录名。
- 空项目 `go.mod` 来自 `files/go/go.mod.tmpl`。普通外部项目不能包含 `replace github.com/shemic/dever => ./dever`；只有本地框架开发才加这个 replace。
- 普通后台 CRUD 走 `Model + package/front + page JSON`；不要写 CRUD API 或 CRUD Service。
- 标准 page path 自动推导 model；标准 list/update/create/view/detail/info 页不要硬编码 `_model`、`_use`、`<<NewXxxModel>>` 或 `submit.use`。
- Model comments、Options、Relations 是标签、枚举、关联选项的来源；除非有意覆盖展示文案，否则不要在 page JSON 重复写。
- `status`、`sort` 和简单列表维护字段使用 front 标准列表 action；不要为它们额外写 update 表单 service。
- Provider 只用于真实 page/load hook、校验、规范化、保存生命周期或适配；不要创建空 passthrough Provider。
- Service 只用于真实业务流程：事务、状态流转、外部调用、异步编排、跨表规则；不要创建 CRUD wrapper service。
- API 只用于真实 HTTP 能力：登录、注册、回调、外部端点、workflow action、复杂前端交互；API 必须薄。
- Config、logo、favicon、AGENTS 片段、page 骨架、组件 skill 骨架来自 `files/`；不要在脚本里散落 heredoc 模板或硬编码资产。
- 修改 `package/<name>` 或 `module/<name>` 前，先检查并遵守 `package/<name>/skills/**/SKILL.md` 或 `module/<name>/skills/**/SKILL.md`。
- 当前本地代码是事实来源。参考顺序：当前 `package/front`、当前 `package/bot`、当前 `package/user`、当前 module/package 示例、`backend/dever`；外部 demo 只作为兜底。
- 开始实现前必须先判断项目模式：`empty-project`、`existing-project`、`app-feature`、`package-dev`、`framework-dev`。模式不明时先盘点，不生成、不迁移、不删除。
- 旧项目和已有项目默认只做增量迁移。除非用户明确要求，不全量重写页面、Service、API、配置或组件。
- 删除旧 Service/API/Provider/page 配置前，必须确认当前 `package/front`、组件能力或真实业务 Service 已覆盖同等行为。
- `scripts/boot.sh` 只用于空项目初始化；已有项目不能用它覆盖骨架。
- 如果用户禁止 build/test，不运行 `npm run build`、`dever build`、`dever front build`、`go test` 或等价测试。只有确实有用时才跑静态文本 audit。

## 必须流程

1. 设计代码前，先用 `rg` 或 `find` 检查现有文件。
2. 判断任务应由 model metadata、page JSON、已有 `package/front` action、Provider hook、Service、API、front plugin、config 或静态模板解决。
3. 选择满足需求的最低能力层，不升级到更重的实现。
4. 改动尽量靠近所属 module/package。
5. 实现后删除重复代码和临时代码。
6. 允许且有价值时运行静态 audit：

```bash
bash skills/skills-dever/scripts/audit.sh <changed-file-or-dir>
```

7. 最终回复列出改动文件、影响的 model/page/service/api/component、是否触及生成文件、执行或跳过的验证。
