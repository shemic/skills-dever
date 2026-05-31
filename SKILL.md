---
name: shemic-dever
description: Use when working on Dever Go projects, including framework setup, generated route/load files, model/service/provider/api code, config, middleware, package imports, package/front page JSON, admin pages, and Dever registration or page errors.
---

# shemic-dever

这是 Dever 项目的统一开发规则。先识别项目当前状态，缺什么补什么。

## 读取顺序

每次使用本 skill，按需求只读必要文件：

1. `references/workflow.md`：统一工作流和决策顺序。
2. `references/development.md`：通用开发规范、复用、职责、命名、清理。
3. `references/framework.md`：Dever 命令、入口、生成文件、路由、Load 注册。
4. `references/model.md`：数据表、model 命名、Options、Relations、索引。
5. `references/module.md`：Service、Provider、API、middleware、业务代码。
6. `references/page.md`：`package/front` 后台 page JSON。
7. `references/package-plugin.md`：可复用 Go package、`dever package add/update`、package/module 前端插件、`dever front build` / `dever build`。

后台、admin、CRUD、列表、编辑、详情、导入导出默认读 `page.md`。多站点 front 任务先读 `config/front.json`，确认 `siteKey/page/api/access`，再读 `page.md`。维护可复用 package 或 package 前端插件时读 `package-plugin.md`。业务规则、状态流转、跨表保存再读 `module.md`。

## 不可违反

- 不手改生成文件：`data/router.go`、`data/load/model.go`、`data/load/service.go`、`data/table/*.json`。
- 应用项目开发时不修改 `backend/dever` 和 `backend/package/*`；它们只能作为框架/package 参考或复用对象。只有明确要求维护框架或 package 本身时，才进入这些目录改源码。
- 不默认写 CRUD API；后台普通 CRUD 走 `Model + package/front + page JSON`。
- 不默认写 Service；只有真实业务规则才写 Service。
- Model 一表一文件；文件名、struct、`NewXxxModel` 对齐。
- 表 model 不写进 `main.go`。
- 长文本用 `type:text`，不要用 `longtext`。
- 标准 page path 自动推导 model；标准页不写 `_model/_use/<<Model>>/submit.use`。
- page JSON 顶层必须有 `page/layout/nodes/data/state/action` 六个对象。
- 多站点 front 以 `config/front.json.sites` 为配置来源；站点路径、API 前缀、资源、access/public 都从这里读。
- 页面目录使用 `front/page/{page}/...`；`{page}` 来自 `sites.*.page`，只隔离物理目录，不进入最终 route。
- `module/<name>/main.go` 如果只是 `// dever:import ...`，真实代码放 package，不复制到 module。
- 项目 `middleware` 可选；package/module 自带 middleware 放自己的 `middleware/init.go` 并提供 `Register()`，路由生成器会自动注册。
- Provider/API/Model 的注册名以生成规则为准，不猜、不手改 load 文件。

## 工作方式

1. 先用 `rg`/`find` 看项目现状：入口、module、package、config、model、service、api、page。
2. 对照 `workflow.md` 判断要补哪一层。
3. 对照真实代码样例写最小实现。
4. 写完清理重复、无用、临时代码。
5. 能跑静态检查时执行：

```bash
bash skills/skills-dever/scripts/audit.sh <改动文件或目录>
```

如果用户禁止 build/test，不运行 build/test；静态 audit 也要在最终回复说明是否执行。

## 错误定位

| 现象 | 先查 |
| --- | --- |
| `model 未注册` | model 初始化是否 panic、文件/构造函数/page path 是否对齐、生成注册是否刷新 |
| `expected record, received null` | page JSON 是否缺 `data/state/action` 顶层对象 |
| label/option 缺失 | model comment、Options、Relations |
| API 路由没有出现 | receiver/method 是否符合 `Get/Post/Put/DeleteXxx`，是否刷新 routes |
| Provider 调不到 | 方法是否 `ProviderXxx`，receiver 是否导出，是否刷新 service |

最终回复用中文，列改动文件、影响的 model/page/service/api、是否触及生成文件、执行过/跳过的验证。
