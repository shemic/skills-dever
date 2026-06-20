# Model

Model 是 Dever 普通资源的首选来源：表结构、字段标签、枚举、关联、默认排序、索引都优先放这里。

## 注册规则

Dever 生成器只扫描 active module/package 的 `model/` 目录，只注册：

```go
func NewXxxModel() *orm.Model[Xxx]
```

要求：

- 函数名导出。
- 以 `New` 开头、以 `Model` 结尾。
- 零参数。
- 一个 model 文件只放一个 `NewXxxModel`。
- 文件名与 `NewXxxModel` 匹配，例如 `NewUserIdentityModel` -> `user_identity.go`。

不要手改 `data/load/model.go`。

## 字段元信息

优先写在 model：

- `dorm:"comment:..."`：列名、表单 label、展示标签。
- `Options`：枚举选项。
- `Relations`：外键、关联选择、展示字段。
- `Order`：默认排序。
- `default` tag：新增默认值。
- 唯一索引、查询索引：数据库约束和查询性能。

Page JSON 只有展示语义确实不同于 model 时才覆盖标签或 option。

## 字段分类

建 model 时先区分字段来源，不要把页面录入习惯倒推成表结构：

| 类型 | 例子 | 规则 |
| --- | --- | --- |
| 业务录入字段 | `name`、`title`、`summary`、`sort`、`status` | 可以配 comment、Options、Relations 供页面使用 |
| 系统生成字段 | `id`、`code`、`sn`、`no`、`slug` | 默认由数据库、Provider 或 Service 生成 |
| 审计字段 | `created_at`、`updated_at`、`created_by`、`updated_by`、`operator_id` | 默认服务端写入，页面只展示 |
| 上下文字段 | `site_id`、`tenant_id`、`department_id`、父资源 ID | 来自登录态、站点、父页面或路由 |
| 分类字段 | `cate_id`、`category_id`、`type`、`kind`、`group_id` | 用 Options/Relations/category 表达 |
| 配置标识字段 | `param_key`、`permission_key`、能力 key | 只有标识本身是业务配置时才允许人工维护 |

`code/key/slug` 不是默认字段。只有业务明确需要稳定标识时才加，并配唯一索引、生成规则或校验规则。

## 默认字段

常规资源可以有：

```txt
ID
Name
Status
Sort
CreatedAt
```

不要无脑添加 `UpdatedAt`、唯一索引或复杂状态字段。只有业务明确需要更新时间、唯一性或状态流转时才加。

不要无脑添加作者、编辑、创建人、更新人字段。需要审计时，先明确由哪个登录上下文或 hook 写入；需要业务负责人时，用 `owner_staff_id`、`assignee_id` 等业务名，不要复用审计字段。

## Options 和 Relations

枚举字段用 Options，关联字段用 Relations。这样 `form-select`、`form-radio`、`show-tag`、option runtime 都能复用。

不要在多个 page JSON 中复制同一组选项。

## 边界

- Model 不写 HTTP 请求。
- Model 不写长业务流程。
- Model hook 只做紧贴数据生命周期的校验、关系同步和字段规范化。
- 跨表事务、外部调用、状态流转放 Service。

## 常见错误

- model 未注册：检查目录、函数签名、文件名和 `dever init`。
- option 无法推导：检查 Options/Relations，而不是先硬编码 `option.model`。
- 保存字段丢失：检查 dorm 字段、列名解析和 `action.submit.data`。
