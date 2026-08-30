---
name: shemic-dever
description: Use when 实现、修改、审查或排查 Dever 项目的 component/package/module、Model、Page JSON、Service、Provider、API、front plugin、framework、CLI、runtime、config 或 Dever skill。与 Dever 无关的通用开发不触发。
---

# shemic-dever

先确认代码归属和最低能力层，再读取对应 reference。不要把普通 CRUD、普通页面或组件私有问题升级成 Service、API、front plugin 或 framework 改动。

## 必读路由

实现、重构或审查 Dever 代码时，先读：

- [decide.md](references/decide.md)：判断项目模式、代码归属和最低能力层。
- [development.md](references/development.md)：业务物理目录、命名、职责和质量约束。

纯问答或只读排查可直接读取最相关 reference，不必加载全部开发规范。

| 任务 | 继续读取 |
| --- | --- |
| 应用业务、module、配置 | [app.md](references/app.md)；完整产品需求再读 [product.md](references/product.md) |
| Model、Options、Relations | [model.md](references/model.md) |
| Provider、Service、API | [service-api.md](references/service-api.md) |
| Page JSON、菜单、权限、action、option | [front-page.md](references/front-page.md) |
| React 节点、复杂交互、插件 | [front-plugin.md](references/front-plugin.md)，再读组件 skill |
| package/module/dever.json | [component.md](references/component.md)，再读组件自己的 `skills/**/SKILL.md` |
| Dever CLI、生成器、framework、package/front runtime | [framework.md](references/framework.md)，再读对应 framework/component skill |
| bug、审查、重构、安全、性能 | [review.md](references/review.md)，并叠加问题所属 reference |
| 维护本 skill、模板或 audit | [skill-maintenance.md](references/skill-maintenance.md) |

## 全局硬规则

- 普通应用业务默认改 `module/*`。只有用户明确维护 framework/package，或仓库本身处于对应开发态，才改 `backend/dever`、`backend/package/*`。
- 普通 CRUD 使用 `Model + package/front + Page JSON`，禁止 CRUD API、CRUD Service 和空 Provider。
- 核心业务规则、事务、状态流转、跨表编排、外部调用及其私有辅助实现必须放在 `service/` 或 `service/<domain>/`。
- `api/`、`cmd/`、`middleware/` 和 Model 生命周期方法只做适配并调用 Service，不承载核心业务流程。
- Provider 不是目录或独立层，而是 `service/**` 接收者上的 `ProviderXxx` 动态调用适配方法；禁止透传 Provider。
- 不为业务创建组件根级 `internal/`、`contract/`、`manager/`、`helper/`、`updater/`、`installer/` 或其它平行业务目录。私有类型、接口和 helper 放在所属 `service/<domain>` 附近。
- Page JSON 只用当前协议。能推导的不写；不能推导才在当前协议规定的位置写 `model` 或 `service`。
- 旧 Page 写法只能出现在禁止说明：`_model`、`_use`、`modelName`、`modelPath`、`type:"service"`、`submit.use`、`option.use`、`childUse`、`service@...`、`transform`、`<<NewXxxModel>>`、`{{Service}}`、手写 `/front/route/option`。
- Model comment、Options、Relations 是字段标签和选项的首选来源，不在多个 Page JSON 重复配置。
- 不手改生成文件：`data/router.go`、`data/load/*.go`、`data/table/*.json`。
- 不手改编译产物：`front/dist/*`、`package/front/front/html/*`。
- 修改 component/package/module 前先读其 `skills/**/SKILL.md`；组件私有规则不得上升成全局规则。
- 测试统一放当前仓库根目录 `test/`；一次性验证结束后删除。
- `dever skill install` 只同步 shemic-dever skill 和项目 agent 提示；Trellis 与 Codex 调度由 DAI 管理。
- 用户或项目禁止 build/test 时，不运行 `npm run build`、`dever build`、`dever front build`、`go test` 或等价命令。

## 工作顺序

1. 用 `rg`/`find` 搜索现有 Model、Page、Service、Provider、API、组件 skill 和 `dever.json`。
2. 按 [decide.md](references/decide.md) 选择最低能力层，并确认物理归属。
3. 只读取当前任务需要的专项 reference 和组件 skill。
4. 实现最小完整路径，删除被替代的重复、空层和临时代码。
5. 运行允许的最小定向检查；可用时执行：

```bash
bash skills/skills-dever/scripts/audit.sh <changed-file-or-dir>
```

最终回复写清实际改动、验证结果、未运行项和剩余阻塞，不把计划或推测写成已完成。
