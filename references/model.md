# Model

Model 是 Dever 普通资源的数据契约：表结构、字段标签、枚举、关联、默认排序、索引都优先放这里。Model 不是业务实现层；核心业务统一放在 `service/`。

## 注册规则

### 生成器实际识别条件

Dever 生成器递归扫描 active module/package 的 `model/` 目录，只识别同时满足以下条件的函数：

- 普通函数，无接收者。
- 函数名导出，以 `New` 开头、以 `Model` 结尾。
- 零参数。

生成器当前不校验返回类型。供 page/runtime 使用时，构造函数应返回兼容的 model 对象，可以直接返回 `*orm.Model[Xxx]`：

```go
func NewXxxModel() *orm.Model[Xxx]
```

也可以返回嵌入 `*orm.Model[Xxx]` 的 wrapper，用于承载紧贴 model 生命周期的扩展：

```go
type XxxModel struct {
    *orm.Model[Xxx]
}

func NewXxxModel() *XxxModel
```

注册名包含 `model/` 下的子目录：`module[.model-subdir...].NewXxxModel`。例如 `package/bot/model/agent/skill.go` 注册为 `bot.agent.NewSkillModel`。

### 推荐组织约定

- 一个资源保留一个清晰的 `NewXxxModel` 构造函数。
- 推荐一个 model 文件放一个资源，文件名使用对应资源的 snake_case，例如 `NewUserIdentityModel` 放在 `user_identity.go`。这些是维护性约定，不是生成器识别条件。
- 目录已表达领域时，文件名不重复目录语义。例如 `model/agent/skill.go`，不要写 `agent_skill_model.go`。
- 同一稳定领域有多个 Model 时可以使用 `model/<domain>/`；注册名必须包含对应子目录。

不要手改 `data/load/model.go`。

## 表命名

表名有两层前缀，职责不同：

- `config/setting.jsonc` 的 `database.<connection>.prefix` 是项目级前缀，必须非空，例如 `shemic`。ORM 会把 `bot_body_action` 建成 `shemic_bot_body_action`。
- `LoadModel` 第二个参数是组件/业务域表名，必须显式带组件或业务域前缀，例如 `bot_body_action`、`crm_customer`、`user_point_config`、`source_channel`。

不要依赖 ORM 自动补组件前缀。ORM 只补数据库项目级前缀，不推断 package/module 名。

普通 package/module 的表名应等于组件根表名，或以 `组件名_` 开头：

```go
return orm.LoadModel[Action]("载体动作", "bot_body_action", orm.ModelConfig{})
return orm.LoadModel[PointConfig]("积分配置", "user_point_config", orm.ModelConfig{})
return orm.LoadModel[Channel]("频道", "source_channel", orm.ModelConfig{})
```

`package/front` 是框架核心 runtime，有历史核心表白名单；不要把业务组件命名规则直接套到 `front`。

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
- Model 不实现业务流程。
- Model hook 只做紧贴数据生命周期的轻量适配和字段规范化。
- 跨表事务、外部调用、状态流转、多入口复用逻辑放在 `service/`；Model hook 需要这些能力时调用普通 Service 方法。
- 不为 Model wrapper 创建根级 helper、contract 或 internal 目录；私有实现靠近所属 Service 域。

## 常见错误

- model 未注册：检查 active module/package、`model/` 目录、导出名称、零参数、无接收者、嵌套目录对应的完整注册名，以及是否已执行 `dever init`。
- option 无法推导：检查 Options/Relations，而不是先硬编码 `option.model`。
- 保存字段丢失：检查 dorm 字段、列名解析和 `action.submit.data`。
