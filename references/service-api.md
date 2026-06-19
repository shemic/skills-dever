# Provider、Service、API

大多数后台页面不需要自定义后端。只有真实业务不变量存在时才升级到 Provider、Service 或 API。

## 生成和调用事实

- Model 注册来自零参 `New*Model`。
- 当前 service 生成器扫描 `service/` 目录，只注册接收者方法 `Provider*`。
- Provider 名称形如 `module.Type.Method`，实际引用的是方法 `Provider<Method>`。
- Page action hook 只接受 `{ "service": "module.Type.Method" }`。
- 普通 Service 方法如果没有被注册或被 API/Provider 显式调用，page JSON 不能凭空调用它。

## 选择表

| 需求 | 使用 | 不要使用 |
| --- | --- | --- |
| 普通 CRUD | Model + page JSON | API/Service |
| 字段标签、枚举、关联 | Model metadata | page 重复写 |
| 保存前校验/规范化 | Provider hook 或 submit.before | API |
| 保存后关系同步/计数 | Provider hook 或小 Service | page 硬编码副作用 |
| 状态流转/跨表事务 | Service | 直接 update 状态 |
| 外部 HTTP/provider | Service | API 内联 |
| 登录/注册/回调/webhook | API + Service | page action |
| front plugin 交互接口 | API + Service | 通用 CRUD action |

## Provider

Provider 是给 Dever/page runtime 调用的适配层。

允许：

- `ProviderBeforeSaveXxx`：校验、规范化、派生字段。
- `ProviderAfterSaveXxx`：关系同步、计数、缓存失效。
- option/list 数据无法由 model metadata 提供时的适配。
- 调用真实 Service 的薄适配器。

禁止：

- 返回原输入的空透传。
- 只因为生成器能识别就保留。
- 在 Provider 里写长流程、HTTP client 或事务编排。

## Service

Service 承载业务行为，方法名用业务动词：

```txt
Publish
Archive
RunNow
AssignRole
SyncRelation
RotateToken
ImportRows
ExecuteWorkflow
```

避免 CRUD wrapper 名：

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

Service 应该有清晰事务边界、错误返回、超时控制、幂等设计和脱敏日志。

## API

API 必须薄：

1. 读取和校验请求。
2. 获取登录/站点/API key 上下文。
3. 调用 Service。
4. 整理响应。

不要把业务流程、SQL 拼接、状态流转或外部调用直接写在 API。

公开 API 必须在组件 `dever.json.front.public` 或 `front.sites.<site>.public` 中明确声明。
