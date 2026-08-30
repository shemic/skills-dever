# Dever 能力决策

本文件只解决三个问题：当前在维护什么、代码归谁、最低哪一层能完成需求。确定后再读专项 reference。

## 1. 判断项目模式

| 模式 | 证据 | 默认边界 |
| --- | --- | --- |
| 应用开发 | 项目以 `module/*` 组合组件，业务属于当前项目 | 只改归属 `module/<name>` 和项目配置 |
| component/package 开发 | 用户明确维护 `package/<name>`，或仓库本身就是组件源码 | 改该 component，并先读组件 skill |
| framework 开发 | 用户明确维护 Dever CLI、生成器、runtime 或 `backend/dever` | 改 framework，并先读 framework skill |
| front runtime 开发 | 用户明确维护 `package/front` 的 Page/action/option/permission 等公共能力 | 改 `package/front`，先读 front component skill |
| 空项目 | 缺少完整 `go.mod/main.go/config/module` 骨架 | 读 [quickstart.md](quickstart.md)，只补空项目骨架 |

不要仅因本地存在 framework/package 源码，就把普通应用需求写进公共组件。

## 2. 找到真实代码归属

先检查 active component：

- `module/<name>/main.go` 如果只有 `// dever:import github.com/dever-package/<name>`，真实源码在 package，不在 shim。
- 项目业务默认归属 `module/<business>`。
- 多项目可复用且边界稳定的组件才归属 `package/<name>`。
- Page、Model、Service、API 和 front plugin 随拥有该业务的 component 发布，不复制到调用方 module。
- 公共 runtime 问题才进入 `backend/dever` 或 `package/front`。

归属不清时先搜索同类资源、调用方和组件声明，不创建平行实现。

## 3. 选择最低能力层

按顺序检查，停在第一个能完整满足需求的层级：

1. **现有能力**：复用现有 Model、Service、Provider、API、Page 节点、action 或组件扩展点。
2. **Model**：字段、索引、默认排序、标签、枚举和关联能由 Model 表达时，只改 Model。
3. **Page JSON**：普通列表、新增、编辑、详情、删除、筛选和标准保存使用 Page JSON。
4. **Provider**：只有 Page 动态调用边界需要保存前后 hook、选项适配或上下文派生时增加 Provider 方法。
5. **Service**：业务不变量、事务、状态流转、跨表编排、外部调用、异步任务或幂等流程进入 Service。
6. **API**：只有真实 HTTP 边界、登录/回调/webhook、流式传输、文件传输或 front plugin 自定义接口才增加 API。
7. **front plugin**：只有 Page runtime 无法表达的复杂交互、画布、编辑器或持续客户端状态才增加插件。
8. **framework/runtime**：只有多个 component 都需要、且现有扩展点无法实现的公共能力才修改 framework 或 `package/front`。

“以后可能扩展”“先统一入口”“方便调用”“先留一层”都不是升层理由。

## 4. 常见需求映射

| 需求 | 默认实现 | 升级条件 |
| --- | --- | --- |
| 资源 CRUD | Model + Page JSON | 保存包含真实业务流程时调用 Service |
| 状态枚举、关联选择 | Model Options/Relations | 跨资源动态过滤才用 option model/service |
| 保存前规范化 | Provider before hook | 涉及事务、外部调用或跨表规则时调用 Service |
| 保存后同步关系/计数 | Provider after hook | 多步骤事务或可复用流程进入 Service |
| 发布、审批、归档、结算 | Service | 需要 HTTP 调用时外面加薄 API |
| 登录、OAuth 回调、webhook | API + Service | 不使用 Page CRUD action |
| 后台画布、富交互编辑器 | front plugin + API/Service | 不把交互状态塞进巨型 Page JSON |
| 多组件公共 Page 能力 | package/front runtime | 必须证明不是组件私有需求 |

## 5. 物理层检查

选对能力后还要放对目录：

```text
<component>/
  model/                    持久化结构和元信息
  service/                  核心业务实现
    <domain>/               稳定的多文件业务域
  api/                      HTTP 适配
  middleware/               请求链装配
  cmd/                      CLI/进程入口适配
  front/                    Page、模板、插件源码和资源
```

Provider 写在 `service/**`。不要新增根级 `provider/`、`contract/`、`internal/` 或业务动作目录。

## 6. 开工前最小结论

非简单任务在写代码前明确：

- 拥有该行为的 component。
- 选中的最低能力层及理由。
- 核心业务所在的 `service` 域。
- 需要的适配入口：Page、Provider、API、CLI、middleware 或 plugin。
- 明确不改的 framework/package/runtime 范围。

完整产品需求继续读 [product.md](product.md)；具体目录与命名读 [development.md](development.md)。
