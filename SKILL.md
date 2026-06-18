---
name: shemic-dever
description: Use when 修改或排查 Dever 项目：model、service、provider、api、page JSON、front 插件、package/module、dever.json、config/front、Dever CLI、生成路由/load、package/front 后台、package/bot/user、权限、option、logo、install、build、run、plugin。
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
- `references/front-page-quick.md`：普通后台 CRUD 和常用 page JSON 快速规则。
- `references/front-page.md`：复杂 page JSON、左分类右列表、弹窗、内联编辑、站点壳。
- `references/template-page.md`：服务端模板页面、SEO、模板资源和公开内容站。
- `references/service-api.md`：什么时候允许写 Provider、Service、API。
- `references/files.md`：配置模板、logo/favicon、AGENTS block、静态文件。
- `references/component.md`：package/module 组件、组件 skill、`dever.json`。
- `references/package-plugin.md`：package/module front 插件源码和构建产物。
- `references/security.md`：权限、action、公开路由、密钥、上传安全。
- `references/troubleshooting.md`：常见 Dever 错误和优先排查点。

## 任务分流

- 空项目、安装、新站点、admin/work/site 搭建：读 `workflow.md`、`empty-project.md`、`framework.md`、`files.md`、`component.md`。
- 新产品、业务系统、业务模块、需求拆分、产品功能设计：读 `workflow.md`、`product.md`，再按资源类型读取 `model.md`、`front-page-quick.md`、`service-api.md`。
- 后端 model 或表结构修改：读 `model.md`；涉及普通页面时读 `front-page-quick.md`，复杂页面再读 `front-page.md`。
- 后台页面、CRUD、列表/编辑/详情、权限或 option 错误：读 `front-page-quick.md`、`model.md`、`security.md`；左分类右列表、弹窗、内联编辑再读 `front-page.md`。
- 服务端模板、SEO、公开内容站：读 `front-page-quick.md`、`template-page.md`、`security.md`。
- Provider、Service、API、回调、登录、注册、workflow、外部请求、事务：读 `service-api.md`、`security.md`。
- config、logo、favicon、AGENTS、静态资产、公开文件：读 `files.md`。
- `package/front`、`package/bot`、`package/user`、module/package 组件：读 `component.md`；如果组件自带 `skills/**/SKILL.md`，继续读组件 skill。
- Front plugin 或 React node：读 `package-plugin.md`；除非确实需要自定义交互节点，否则优先用 page JSON。
- Dever CLI、生成文件、import cycle、run/build/install 问题：读 `framework.md`、`troubleshooting.md`。

## 硬规则

- `shemic-dever` 的唯一维护源是 `github.com/shemic/skills-dever`; Dever 框架仓库只负责安装和检查，不维护完整内嵌副本。
- `dever skill install` 必须每次从 `github.com/shemic/skills-dever` 拉取临时副本作为来源；不要读取项目本地 `skills/skills-dever`、已安装全局 skill 或本机缓存作为安装来源。
- 维护 `skills/skills-dever` 自身时，`references/`、`files/`、`scripts/` 必须互相一致；模板和脚本不能生成被 reference 禁止的写法。
- 不手改生成文件：`data/router.go`、`data/load/model.go`、`data/load/service.go`、`data/table/*.json`。
- 不通过修改 `package/front/front/html/assets/index*.js` 等编译产物来改行为、logo、文案或样式。
- 不为禁止字段保留适配代码、不保留废弃分支、不做双路径备用实现；发现禁止字段直接改成当前协议或让 audit 报错。
- 应用项目 Go module 固定使用 `my`；不要改成项目名、域名或目录名。
- 空项目 `go.mod` 来自 `files/go/go.mod.tmpl`。普通外部项目不能包含 `replace github.com/shemic/dever => ./dever`；只有本地框架开发才加这个 replace。
- 普通后台 CRUD 走 `Model + package/front + page JSON`；不要写 CRUD API 或 CRUD Service。
- 标准 page path 自动推导 model；标准 list/update/create/view/detail/info 页不要硬编码 `_model`、`_use`、`<<NewXxxModel>>`、`{{Service}}`、`submit.use`、`option.use` 或 `childUse`。
- page JSON 不能推导来源时，只写当前协议：`data.<key>.model`、`data.<key>.service`、`action.<key>.model`、`option.model`、`option.service`、`meta.model`、`meta.service`、`meta.childModel`、`meta.childService`；不要写 `modelName`、`type: "service"`、任意 `use` 禁止字段或 `/front/route/option` 字符串。
- `data.table.service` 和 `data.form.service` 是 model 加载后的补字段/规范化 service；同时存在 `model` 和 `service` 时，先按 model 查询，再把 rows/record 交给 service，不要把它理解为替代数据源。
- page JSON 能自动推导的字段（`page.type`、`page.title`、`data.table` 的 `page/pageSize/total/order`、`data.form` 的 `id`/`status`/`sort` 默认值、`option` 来源）不写；只有需要覆盖默认值或派生字段时才写。
- `action.submit` 普通 CRUD 只写 `{ "type": "save", "params": "form" }`，不写 `data`/`before`/`after`。要写 `data` 模板就必须覆盖所有可被 partial save 触及的字段（至少 `id` + 编辑字段 + `status` + `sort`），否则 `statusChangeAction`、`sortChangeAction`、表格内联编辑会触发 `没有可保存的字段`。
- update 页的 `before` hook 必须识别 `_partial`，跳过完整校验，只规范化实际存在的字段。
- Model comments、Options、Relations 是标签、枚举、关联选项的来源；除非有意覆盖展示文案，否则不要在 page JSON 重复写。
- `status`、`sort` 和简单列表维护字段使用 front 标准列表 action；不要为它们额外写 update 表单 service。
- Provider 只用于真实 page/load hook、校验、规范化、保存生命周期或适配；不要创建空 passthrough Provider。
- Service 只用于真实业务流程：事务、状态流转、外部调用、异步编排、跨表规则；不要创建 CRUD wrapper service。
- API 只用于真实 HTTP 能力：登录、注册、回调、外部端点、workflow action、复杂前端交互；API 必须薄。
- Config、logo、favicon、AGENTS 片段、page 骨架、组件 skill 骨架来自 `files/`；front 站点运行契约随组件写在 `dever.json.front.sites`，项目只可通过 `config/front.json` 覆盖 `sites.<site>` 展示配置；不要在脚本里散落 heredoc 模板或硬编码资产。
- 修改 `package/<name>` 或 `module/<name>` 前，先检查并遵守 `package/<name>/skills/**/SKILL.md` 或 `module/<name>/skills/**/SKILL.md`。复杂组件没有 skill 时，先按 `component.md` 补齐约束再做大改。
- `package/front` 是核心 runtime；维护它时必须同时读 `front-page-quick.md`、`front-page.md`、`package-plugin.md`、`security.md`、`framework.md`，不要把业务组件逻辑塞进 front。
- `front/src/plugin.ts` 的 `depends` 只写 Dever front plugin 名（如 `"crm"`），不要写 npm 包名；npm 依赖必须写在同目录 `front/package.json`。
- 当前本地代码是事实来源。参考顺序：当前 `package/front`、当前 `package/bot`、当前 `package/user`、当前 module/package 示例、`backend/dever`；外部 demo 只作为补充参考。
- 开始实现前必须先判断项目模式：`empty-project`、`app-feature`、`package-dev`、`framework-dev`。模式不明时先盘点，不生成、不删除。
- 非空项目只改当前任务需要的最小范围；删除 Service/API/Provider/page 配置前，必须确认当前 `package/front`、组件能力或真实业务 Service 已覆盖同等行为。
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
