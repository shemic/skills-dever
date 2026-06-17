# Provider、Service 和 API

使用能满足需求的最低后端能力。大多数后台页面只需要 model 元信息和 page JSON，不需要自定义后端。

## 决策表

| 需求 | 使用 | 不要使用 |
| --- | --- | --- |
| 普通列表/新增/编辑/删除/详情 | Model + page JSON | 自定义 API/Service |
| 标签/选项/关联 | Model comments/Options/Relations | 重复写 page 标签/选项 |
| 默认字段值 | model default 或 page default | Service |
| 简单保存规范化 | ProviderBeforeSave | API |
| 单 model 保存校验 | ProviderBeforeSave | 只靠页面校验 |
| 保存后关系同步/计数/cache 失效 | ProviderAfterSave 或聚焦 Service | 只写 API 逻辑 |
| 带业务规则的状态流转 | Service | 直接更新状态 |
| 跨表事务 | Service | page JSON action |
| 外部 HTTP/provider 调用 | Service | API 内联业务逻辑 |
| callback/webhook/login/register | API + Service | page JSON |
| async job/workflow/run action | Service，必要时加 API 触发 | CRUD wrapper |
| 复杂自定义前端交互 | 必要时 API + Service | 泛化表格 action |

## Provider 规则

Provider 用来把 Dever/page runtime 适配到 model 生命周期或 option/data hook。

允许：

- `ProviderBeforeSaveXxx`：校验、规范化、派生字段。
- `ProviderAfterSaveXxx`：关系同步、计数更新、缓存失效。
- 数据无法来自 model Options/Relations 时，写 option/list provider。
- 调用真实 Service 方法的小适配器。

禁止：

- 返回原输入的空 passthrough Provider。
- 只因为脚本生成了就保留 Provider。
- 在 Provider 里写长业务流程、HTTP client 或事务编排。
- 不检查生成注册规则就手猜 Provider 名。

## Service 规则

Service 承载业务行为。方法名必须有业务动词，并维护真实业务不变量。

好的方法名：

```txt
Publish
Archive
RunNow
CreateVersion
AssignRole
SyncRelation
RotateToken
ImportRows
ExecuteWorkflow
```

普通 CRUD wrapper 的坏方法名：

```txt
Save
List
Create
Update
Delete
GetInfo
HandleData
Process
```

Service 应该：

- 按项目约定接收 `context.Context` 或明确请求上下文。
- 尽量使用类型清晰的参数。
- 为多表变更定义事务边界。
- 返回明确错误。
- 外部调用必须设置超时。
- 记录有意义的失败日志，但不能泄露密钥。
- 能被 Provider/API/jobs 复用。

Service 不应该：

- 直接解析 HTTP request。
- 知道 page JSON layout 细节。
- 只包装一次 ORM 调用而没有业务价值。
- 变成无关 helper 的垃圾桶。

## API 规则

API 是 HTTP 适配层，必须保持薄：

1. 读取并校验请求参数。
2. 调用 Service。
3. 整理返回。

允许的 API：

- login/register/logout/refresh token
- public callbacks/webhooks
- third-party endpoints
- workflow/action trigger endpoints
- custom front plugin endpoints
- `package/front` 未覆盖的文件上传/下载端点

禁止的 API：

- 为 `package/front` 已能处理的页面写 CRUD API。
- 在 API 中内联事务/业务逻辑。
- 绕过权限检查，允许改任意表/字段。
- 没有 action registry 和权限检查的宽泛“执行 action”端点。

## 状态、排序和内联更新

`status`、`sort` 和类似列表维护字段优先使用 `package/front` 标准列表 action。不要只为了切换状态或更新排序新增 Provider/Service/API。

只有状态代表真实业务状态流转，并带前置条件、副作用、审计或锁时，才用 Service。

## 外部调用

HTTP/LLM/storage/provider 调用要求：

- 设置超时。
- 凭据放配置或密钥存储，不写源码。
- 日志里脱敏密钥。
- 重试必须显式且有边界。
- callback 和 async job 要明确幂等。

## 权限边界

所有自定义 API 和 action-like service 入口，除非明确公开，否则必须只能通过已认证、已授权路由访问。公开端点必须在代码/page/config 中说明原因。
