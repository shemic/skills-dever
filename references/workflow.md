# Dever 统一工作流

先判断项目模式，再选择最低成本的 Dever 能力。不要从“写代码”开始，要先判断 Model、page JSON、package/front 标准 action、Provider、Service、API、front 插件、配置模板哪一层能解决问题。

## 1. 判断项目模式

先用只读命令盘点：

```bash
find . -maxdepth 3 -type f \( -name go.mod -o -name main.go -o -name '*.json' -o -name '*.jsonc' \)
find module package -maxdepth 4 -type f 2>/dev/null
```

按现状归类：

| 模式 | 判断 | 默认策略 |
| --- | --- | --- |
| `empty-project` | 没有 `go.mod`，或只有空目录/最小骨架 | 读 `empty-project.md`，允许使用 `boot.sh` 和 package 安装流程 |
| `app-feature` | 在应用项目里新增或修改业务功能 | 业务放 `module/<name>`，优先 Model + page JSON |
| `package-dev` | 明确维护 `package/front`、`package/bot`、`package/user` 或其他 package | 读 `component.md` 和组件 skill，改 package 源码 |
| `framework-dev` | 明确维护 `backend/dever`、Dever CLI、生成器、框架中间件 | 读 `framework.md` 和 `troubleshooting.md`，改框架源码 |

模式不明时继续盘点，不生成、不删除。

## 2. 通用决策顺序

1. 项目能否被 Dever 启动？
   - `empty-project`：初始化固定 `module my`。
   - 非空项目：先确认已有 `module my`、`main.go`、配置和组件边界；若不是 `my`，先说明组件 import 风险，不继续生成 package shim。
   - 缺 `main.go` 或配置时，只补当前任务明确需要的文件，不用空项目脚本覆盖已有内容。
2. 代码归属在哪里？
   - 应用业务放 `module/<name>`。
   - `module/<name>/main.go` 只有 `// dever:import ...` 时，真实代码在 package。
   - 应用开发不要复制 package 代码，也不要为了业务功能改 `backend/dever`。
3. front 页面属于哪个站点？
   - 读 active 组件的 `dever.json.front.sites`，确认 `siteKey/page/api/access/public`。
   - 页面放 `front/page/{page}/...`，`page` 只选物理目录，不进入 route。
4. 是否是业务产品或新功能？
   - 先读 `product.md`，拆资源、流程、角色、页面和服务边界。
   - 普通资源先写 model，再写 page JSON。
5. 是否是后台页面？
   - 默认 `Model + package/front + page JSON`，快速规则见 `front-page-quick.md`，复杂页面见 `front-page.md`。
   - 普通 CRUD 不写 API/Service。
   - 标准页优先自动推导 model，不写 `_model/_use/submit.use/option.use/childUse`；不能推导时只写对应位置的 `model` 或 `service`。
6. 是否有真实业务规则？
   - 状态流转、跨表保存、强校验、外部协议、异步任务、聚合查询才写 Provider/Service/API，细则见 `service-api.md`。
7. 是否需要刷新生成文件？
   - 改 model/service/api 后让 `dever run` 自动刷新，或手动用 `dever init --skip-tidy` 调试。
   - 不手改生成文件。

## 3. 模式约束

### empty-project

- 可以使用 `scripts/boot.sh`。
- 先安装 `front` 和业务组件；站点细节由组件 `dever.json.front.sites` 声明，项目配置只保留 `setting.json(c).frontSite` 静态服务开关。
- 业务页面放 `module/<biz>/front/page/{page}`。
- 不生成业务 API/Service。

### app-feature

- 先搜索同类实现。
- 先写或检查 model，字段注释、Options、Relations 放 model。
- 标准后台 CRUD 用 page JSON。
- 真实业务流程再写 Service，API 只做 HTTP 适配。

### package-dev

- 先读组件自己的 `skills/**/SKILL.md`。
- 组件专属行为留在组件内，不散落到全局。
- package 的 page JSON、front 插件、middleware、dever.json 都随组件维护。

### framework-dev

- 先查已有 cache、runtimecache、middleware、生成器机制。
- 不新增平行缓存或硬编码接口。
- 修改 Dever CLI 或 package/front runtime 时，检查是否影响 module/package 组件。

## 4. 快速路径

后台 admin：

```txt
module/<biz>/model/<resource>.go
module/<biz>/front/page/admin/<resource>/list.json
module/<biz>/front/page/admin/<resource>/update.json
```

前台 work：

```txt
module/work/dever.json                   # front.sites.work 声明 api/page/access/public/entry
module/work/front/page/work/main.json
module/work/front/page/work/home.json
module/work/front/src/plugin.ts          # 只有复杂 React 节点才需要
module/work/api/*.go                     # 只有登录、注册、业务动作等真实 API 才需要
```

配置、logo、favicon、AGENTS block、标准页面骨架都从 `files/` 模板生成，规则见 `files.md`。不要在脚本里复制大段 heredoc。

## 5. 交付格式

```md
结构风险：
- ...

实现：
- ...

复用点：
- ...

验证：
- ...
```

验证里明确说是否没有跑 build/test。
