---
name: shemic-dever
description: Use when working on Dever Go projects, including framework setup, generated route/load files, model/service/provider/api code, config, middleware, package imports, package/front page JSON, admin pages, and Dever registration or page errors.
---

# shemic-dever

这是 Dever Go 项目的开发 skill。目标是让 AI 按真实框架规则做事：先看项目现状，复用已有 module/package，用最小代码补齐业务，不手改生成文件，不为普通后台 CRUD 乱写 API/Service。

## 读取顺序

每次使用本 skill，只读当前任务需要的文件：

1. `references/workflow.md`：统一工作流和决策顺序。
2. `references/framework.md`：Dever 命令、入口、源码位置、生成文件、路由、Load 注册。
3. `references/development.md`：复用、职责、命名、清理。
4. `references/model.md`：数据表、model 命名、Options、Relations、索引。
5. `references/page.md`：`package/front` 后台 page JSON。
6. `references/module.md`：Service、Provider、API、middleware。
7. `references/empty-project.md`：空项目、多站点、安装 `front` + `bot`。
8. `references/package-plugin.md`：Go package、package/module front 插件、`dever front build` / `dever build`。

触发规则：

- “空项目 / 新建项目 / 搭系统 / 搭站点 / 搭后台 / admin / work / 前台站点”：先读 `empty-project.md`。
- “后台 / CRUD / 列表 / 编辑 / 详情 / 导入导出”：先读 `page.md`，默认 `Model + package/front + page JSON`。
- “front 插件 / React 节点 / 自定义前端 / package 插件”：读 `package-plugin.md`。
- “状态流转 / 跨表保存 / 业务动作 / 回调 / 登录注册 API”：读 `module.md`。
- “model 未注册 / 路由没有 / Provider 找不到 / dever run”：读 `framework.md`。

## 不可违反

- 不手改生成文件：`data/router.go`、`data/load/model.go`、`data/load/service.go`、`data/table/*.json`。
- 应用项目开发时不修改 `backend/dever` 和 `backend/package/*`；它们只能作为框架/package 参考或复用对象。只有明确要求维护框架或 package 本身时，才进入这些目录改源码。
- 不默认写 CRUD API；后台普通 CRUD 走 `Model + package/front + page JSON`。
- 不默认写 Service；只有真实业务规则才写 Service。
- 空项目 site 系统基线不要只装 `front`；按当前约定 `front` 和 `bot` 两个 package 都要通过 `dever package add` 引入，除非用户明确排除。
- 空项目默认日志写文件：`log.output=file`，`successFile=data/log/access.log`，`errorFile=data/log/error.log`；不要让常规请求日志刷到 `dever run` 屏幕。
- Model 一表一文件；文件名、struct、`NewXxxModel` 对齐。
- 表 model 不写进 `main.go`。
- 长文本用 `type:text`，不要用 `longtext`。
- 标准 page path 自动推导 model；标准页不写 `_model/_use/<<Model>>/submit.use`。
- page JSON 顶层必须有 `page/layout/nodes/data/state/action` 六个对象。
- 多站点 front 以 `config/front.json.sites` 为配置来源；站点路径、API 前缀、资源、access/public 都从这里读。
- 页面目录使用 `front/page/{page}/...`；`{page}` 来自 `sites.*.page`，只隔离物理目录，不进入最终 route。
- `module/<name>/main.go` 如果只是 `// dever:import ...`，真实代码放 package，不复制到 module。
- 项目 `middleware` 可选；package/module 自带 middleware 放自己的 `middleware/init.go` 并提供 `Register()`，路由生成器会自动注册。
- 维护 `backend/dever` 或 `backend/package/front` 性能问题时，先查已有 cache、runtimecache、middleware 机制，不新增平行缓存或硬编码接口。
- Provider/API/Model 的注册名以生成规则为准，不猜、不手改 load 文件。

## 快速决策

1. 先用 `rg` / `find` 看入口、config、module、package、model、service、api、page、front 插件。
2. 空项目：补 `go.mod/main.go/config`，安装 `front` + `bot`，配置 `frontSite` 和 `config/front.json.sites`。
3. 后台资源：先写 model，再写 `front/page/{page}/...`，普通 CRUD 不写 API/Service。
4. 前台站点：先确认 `sites.<siteKey>.api/page/access/public`，页面放 `front/page/{page}`，复杂交互才写插件或 API。
5. 真实业务规则：Service 承载业务，API/Provider 只适配。
6. 改 model/service/api 后刷新生成文件，或让 `dever run` 自动刷新。
7. 写完删除重复、临时代码，保持职责边界。

能跑静态检查时执行：

```bash
bash skills/skills-dever/scripts/audit.sh <改动文件或目录>
```

如果用户禁止 build/test，不运行 `dever build`、`dever front build`、`npm run build`、测试命令。静态 audit 是否执行要在最终回复说明。

## 错误定位

| 现象 | 先查 |
| --- | --- |
| `model 未注册` | model 初始化是否 panic、文件/构造函数/page path 是否对齐、生成注册是否刷新 |
| `expected record, received null` | page JSON 是否缺 `data/state/action` 顶层对象 |
| label/option 缺失 | model comment、Options、Relations |
| API 路由没有出现 | receiver/method 是否符合 `Get/Post/Put/DeleteXxx`，是否刷新 routes |
| Provider 调不到 | 方法是否 `ProviderXxx`，receiver 是否导出，是否刷新 service |

最终回复用中文，列改动文件、影响的 model/page/service/api、是否触及生成文件、执行过/跳过的验证。
