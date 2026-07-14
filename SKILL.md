---
name: shemic-dever
description: Use when 实现、修改、审查、排查或维护 Dever 项目的 model、page JSON、Service、API、Provider、front plugin、component/package/module、framework、CLI、runtime、config 或 Dever skill。与 Dever 无关的通用问答不触发。
---

# shemic-dever

本 skill 是 Dever 项目的薄入口。先判断角色，再只读取相关 reference。不要把普通 CRUD、普通页面或普通配置升级成 Service/API/front plugin。

## 角色路由

| 角色 | 触发 | 必读 |
| --- | --- | --- |
| `dever-app` | 业务功能、module、model、普通后台、配置 | `references/app.md`、`references/model.md`；涉及 Service/API 再读 `references/service-api.md`；涉及页面再读 `references/front-page.md` |
| `dever-front-page` | page JSON、route/action/option、权限、菜单、站点、后台/工作台页面 | `references/front-page.md` |
| `dever-front-plugin` | `front/src/plugin.ts`、React 节点、画布、工作台、复杂交互 | `references/front-plugin.md`，再读组件 skill |
| `dever-component` | `package/<name>`、`module/<name>`、`dever.json`、组件 skill | `references/component.md`，再读组件自己的 `skills/**/SKILL.md` |
| `dever-framework` | `backend/dever`、CLI、生成器、run/build/package/skill install、`package/front` runtime | `references/framework.md`；维护 `backend/dever` 时再读 `backend/dever/SKILL.md`；涉及 front runtime 再读 `backend/package/front/skills/SKILL.md` |
| `dever-review` | bug、代码审查、精简、安全、性能、重构分析；要求按 P0/P1/P2 输出真实问题 | `references/review.md`，按问题层叠加其它 reference |
| `dever-skill-maintainer` | 修改 `skills/skills-dever`、`files/AGENTS.dever.md`、`scripts/audit.sh`、新增规则 | `references/skill-maintenance.md` |

角色可以叠加。角色一时不明时先盘点到足以判断归属；用户目标和修改位置明确时，直接进入最匹配角色并完成实现。

## 全局硬规则

- 普通业务默认只改应用 `module/*`；不要改 `backend/dever`、`backend/package/*`。如果用户明确指向框架、package、runtime、通用组件或当前项目本身就是框架/package 开发仓库，进入 `dever-framework` 或 `dever-component` 并按对应边界处理。
- 普通 CRUD 使用 `Model + package/front + page JSON`；不要写 CRUD API、CRUD Service、空 Provider。
- Page JSON 只用当前协议。能自动推导的不写；不能推导才写对应位置的 `model` 或 `service`。
- 禁止旧 page 写法和兼容分支：`_model`、`_use`、`modelName`、`modelPath`、`type:"service"`、`submit.use`、`option.use`、`childUse`、`service@...`、`transform`、`<<NewXxxModel>>`、`{{Service}}`、`/front/route/option`。
- `data.table.service`、`data.form.service` 在已有 model 时是补字段/规范化，不是替代数据源。
- Service 只承载真实业务流程：事务、状态流转、外部调用、异步编排、跨表规则。API 必须薄。
- 新增 Service/API/front plugin/framework runtime 前必须说明为什么不能用更低层能力。普通局部 bugfix、组件内小改和贴近现有模式的代码，不要求长篇升层说明。
- Provider 只做真实 hook/适配/校验/规范化；不要创建透传 Provider。
- Model 标签、Options、Relations 是字段展示和选项首选来源；不要在多个 page JSON 重复写。
- 不手改生成文件：`data/router.go`、`data/load/*.go`、`data/table/*.json`。
- 不手改编译产物：`front/dist/*`、`package/front/front/html/*`、`package/front/front/html/assets/*`。
- 修改 `package/<name>` 或 `module/<name>` 前，先读该组件声明的 `skills/**/SKILL.md`。
- 组件站点运行契约写在组件 `dever.json.front.sites`；项目 `config/front.json` 或 `config/front.jsonc` 只覆盖 `sites.<site>` 展示配置。
- 自定义 API 必须按站点/用途隔离；细则归属 `references/service-api.md` 和 `references/front-page/site.md`。
- `dever skill install` 每次从 `github.com/shemic/skills-dever` 拉取；不要使用本地缓存或项目镜像作为安装来源。
- `dever skill install` 默认安装/更新 Trellis 并初始化当前项目；不需要 Trellis 时显式使用 `--trellis=false`，只管理全局 CLI 时使用 `--trellis-project=false`。
- 如果用户禁止 build/test，不运行 `npm run build`、`dever build`、`dever front build`、`go test` 或等价测试。

## 工作方式

1. 先用 `rg`/`find` 搜索现有 model、page、service、api、组件 skill 和 `dever.json`。
2. 判断最低能力层：model 元信息、page JSON、Provider、Service、API、front plugin、config、框架代码。
3. 按角色读取 reference；不要加载无关长文档。
4. 改动靠近归属 module/package；不做顺手重构。
5. 实现前后按 `references/app.md` 的"自检"清单确认；可静态检查时运行：

```bash
bash skills/skills-dever/scripts/audit.sh <changed-file-or-dir>
```

## 最终回复

多步骤任务完成后，保持简短但包含：

1. 状态：已完成 / 部分完成 / 未完成 / 阻塞。
2. 完成内容：只写实际做过的事，不把计划或推测写成完成。
3. 验证情况：写清运行过的命令和结果；用户禁止 build/test 时写明未运行。
4. 剩余事项：写清未做、未验证、需要用户手动测试或后续迁移的内容；没有则写"剩余：无"。

单步骤操作、简单排查、问答可直接回复，不需要四段式。
不要只说"已完成"。不要把未运行的 build/test、未人工验证的 UI 说成已验证。
