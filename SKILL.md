---
name: shemic-dever
description: Use when 修改或排查 Dever 项目：model、service、provider、api、page JSON、front 插件、package/module、dever.json、config/front、Dever CLI、生成路由/load、package/front 后台、package/bot/user/source/crm、权限、option、install、build、run、plugin、skills。
version: 1.0.0
---

# shemic-dever

本 skill 是 Dever 项目的薄入口。先判断角色，再只读取相关 reference。不要把普通 CRUD、普通页面或普通配置升级成 Service/API/front plugin。

## 角色路由

| 角色 | 触发 | 必读 |
| --- | --- | --- |
| `dever-app` | 业务功能、module、model、普通后台、配置 | `references/app.md`、`references/model.md`、涉及页面再读 `references/front-page.md` |
| `dever-front-page` | page JSON、route/action/option、权限、菜单、站点、后台/工作台页面 | `references/front-page.md` |
| `dever-front-plugin` | `front/src/plugin.ts`、React 节点、画布、工作台、复杂交互 | `references/front-plugin.md`，再读组件 skill |
| `dever-component` | `package/<name>`、`module/<name>`、`dever.json`、组件 skill | `references/component.md`，再读组件自己的 `skills/**/SKILL.md` |
| `dever-framework` | `backend/dever`、CLI、生成器、run/build/package/skill install、`package/front` runtime | `references/framework.md`，涉及 front runtime 再读 `backend/package/front/skills/SKILL.md` |
| `dever-review` | bug、代码审查、精简、安全、性能、重构分析；要求按 P0/P1/P2 输出真实问题 | `references/review.md`，按问题层叠加其它 reference |
| `dever-skill-maintainer` | 修改 `skills/skills-dever`、`files/AGENTS.dever.md`、`scripts/audit.sh`、新增规则 | `references/skill-maintenance.md` |

角色可以叠加。角色不明时先盘点，不生成、不删除。

## 全局硬规则

- 普通业务默认只改应用 `module/*`；不要改 `backend/dever`、`backend/package/*`，除非用户明确要求维护框架或 package。
- 普通 CRUD 使用 `Model + package/front + page JSON`；不要写 CRUD API、CRUD Service、空 Provider。
- Page JSON 只用当前协议。能自动推导的不写；不能推导才写对应位置的 `model` 或 `service`。
- 禁止旧 page 写法和兼容分支：`_model`、`_use`、`modelName`、`modelPath`、`type:"service"`、`submit.use`、`option.use`、`childUse`、`service@...`、`transform`、`<<NewXxxModel>>`、`{{Service}}`、`/front/route/option`。
- `data.table.service`、`data.form.service` 在已有 model 时是补字段/规范化，不是替代数据源。
- Service 只承载真实业务流程：事务、状态流转、外部调用、异步编排、跨表规则。API 必须薄。
- 新增代码前必须说明为什么不能用更低层能力；新增 Service/API/front plugin 前尤其要说明原因。
- Provider 只做真实 hook/适配/校验/规范化；不要创建透传 Provider。
- Model 标签、Options、Relations 是字段展示和选项首选来源；不要在多个 page JSON 重复写。
- 不手改生成文件：`data/router.go`、`data/load/*.go`、`data/table/*.json`。
- 不手改编译产物：`front/dist/*`、`package/front/front/html/*`、`package/front/front/html/assets/*`。
- 修改 `package/<name>` 或 `module/<name>` 前，先读该组件声明的 `skills/**/SKILL.md`。
- 组件站点运行契约写在组件 `dever.json.front.sites`；项目 `config/front.json` 只覆盖 `sites.<site>` 展示配置。
- `dever skill install` 每次从 `github.com/shemic/skills-dever` 拉取；不要使用本地缓存或项目镜像作为安装来源。
- 如果用户禁止 build/test，不运行 `npm run build`、`dever build`、`dever front build`、`go test` 或等价测试。

## 工作方式

1. 先用 `rg`/`find` 搜索现有 model、page、service、api、组件 skill 和 `dever.json`。
2. 判断最低能力层：model 元信息、page JSON、Provider、Service、API、front plugin、config、框架代码。
3. 实现前自检：归属层、复用点、是否需要更重能力、是否影响组件/权限/生成文件。
4. 按角色读取 reference；不要加载无关长文档。
5. 改动靠近归属 module/package；不做顺手重构。
6. 实现后自检：是否新增 CRUD wrapper、空 Provider、旧 page 协议、生成文件/产物改动、重复逻辑。
7. 可静态检查时运行：

```bash
bash skills/skills-dever/scripts/audit.sh <changed-file-or-dir>
```
