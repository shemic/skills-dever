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
