# 业务产品开发流程

用于新产品、业务系统、新功能模块或复杂业务页面。目标是先拆清业务边界，再决定使用 Model、page JSON、Provider、Service、API 或 front 插件。

## 1. 先拆业务

实现前先列出：

- 站点：后台、工作台、门户、C 端、独立业务前台。
- 使用者：管理员、运营、普通用户、外部系统、回调来源。
- 资源：需要持久化的核心名词，一般对应 model。
- 流程：状态流转、审批、运行、生成、导入、同步、回调。
- 页面：列表、编辑、详情、配置、工作台、图形化界面。
- 外部依赖：支付、LLM、存储、第三方 API、消息队列、定时任务。

不要一上来写大 Service、大 API 或大 React 页面。

## 2. 能力选择

| 需求 | 优先使用 |
| --- | --- |
| 普通资源维护 | Model + page JSON |
| 标签、枚举、关联选择 | model comment / Options / Relations |
| 列表搜索、分页、状态、排序、删除 | package/front 标准 action |
| 保存前规范化或单表校验 | ProviderBeforeSave |
| 保存后同步、计数、缓存失效 | ProviderAfterSave 或聚焦 Service |
| 跨表事务、状态流转、外部调用 | Service |
| 登录、注册、回调、插件交互接口 | API + Service |
| 强交互页面、画布、编辑器、工作台 Shell | front 插件节点 |

能用低层能力解决时，不升级到更重的实现。

## 3. Model 先行

每个持久化资源先确定：

- 表名和所属 module/package。
- 字段、comment、默认值、状态枚举。
- 唯一索引、查询索引、默认排序。
- Relations 和 Options。
- 是否需要 `UpdatedAt`。没有明确更新时间语义时不要默认加。

页面标签、选项、关联展示尽量来自 model，不在多个 page JSON 里复制。

## 4. 页面边界

后台和简单业务页面：

- 标准 `list/update/create/detail/info` 走自动 model 推导。
- 左分类右列表用本地数据容器刷新，不用 navigate 到 query 触发刷新。
- 状态、排序这类维护字段留在列表内联维护。
- 弹窗、抽屉、嵌入页要有明确 `page.name`、`page.parent` 和 action 上下文。

前台和工作台：

- 普通内容页仍优先 page JSON。
- 复杂交互才写 `module/<site>/front/src/plugin.ts`。
- 插件节点只做 UI 和交互；登录、保存、业务动作放 API/Service。

## 5. Service 边界

Service 只承载真实业务不变量：

- 状态流转及前置条件。
- 跨表事务。
- 外部系统调用。
- 幂等回调。
- 异步任务或 workflow 执行。
- 权限之外的业务规则。

Service 方法名用业务动词，例如 `Publish`、`RunNow`、`CreateVersion`、`SyncRelation`。不要写 `Save/List/Create/Update/Delete` 这类 CRUD wrapper。

## 6. API 边界

API 必须薄：

1. 读取和校验请求参数。
2. 调用 Service。
3. 整理返回。

公开 API 必须说明公开原因，并按 `security.md` 处理签名、幂等、日志和密钥脱敏。

## 7. 交付前检查

- 是否复用了已有 module/package/page/action。
- 是否避免了 CRUD Service/API。
- 是否把标签、枚举、关联放回 model。
- 是否只在真实业务流程中写 Service。
- 是否没有手改生成文件和编译产物。
- 是否没有把项目私有逻辑写进 package/front 或 backend/dever。
