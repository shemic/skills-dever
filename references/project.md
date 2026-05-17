# Dever Full Project Delivery Playbook

这个文档回答：当用户只给一个业务需求时，AI 如何用 Dever skill 从 0 设计并交付一个完整项目。

目标是让 AI 不靠临时猜测，而是按统一流程完成：

1. 项目初始化
2. 业务拆解
3. 数据建模
4. 后端 Model / Service / Provider / API
5. `package/front` 后台接入
6. 复杂后台 page JSON
7. 自查和交付说明

相关文档：

- `references/boot.md`：空项目初始化
- `references/module.md`：业务后端代码
- `references/front-page.md`：后台 page JSON

## 0. 总原则

### 0.0 后台默认就是 page JSON

只要任务目标是后台、管理端、admin、资源管理、CRUD 页面、列表/编辑/详情/统计/导入导出，就默认使用：

```txt
Model + Service/Provider hook + package/front + page JSON
```

用户不需要额外说“通过 JSON 实现后台”。这是使用 `shemic-dever` skill 做后台的默认交付方式。

默认禁止：

- 因为用户没说 JSON，就改前端源码。
- 因为用户说 CRUD，就给每张表手写 CRUD API。
- 因为页面复杂，就新增临时前端组件或临时 DSL。
- 从本地项目里复制整页复杂 JSON。

只有这些情况才偏离 page JSON：

- 用户明确要求开发前端运行时或新通用组件。
- `front-page.md` 已确认现有节点/action 无法表达，并且该能力会被多个业务复用。
- 需求是第三方回调、网关、流式、文件下载等非后台页面 HTTP 能力。

### 0.1 分层边界

| 层 | 负责什么 | 不负责什么 |
| --- | --- | --- |
| Model | 表结构、字段注释、索引、Options、Relations、字段类型 | 业务流程、HTTP 入参、页面布局 |
| Service | 业务规则、事务、状态流转、跨表编排、复杂查询 | 直接处理 HTTP 响应、页面渲染 |
| Provider | 给 `Dever.Load` / page JSON 调用的数据、hook、动态 option | 对外 HTTP 路由 |
| API | 非后台 CRUD 的 HTTP 能力，取参、调 Service、返回 | 复杂业务内联在 handler |
| Page JSON | 后台页面结构、节点、数据绑定、动作编排 | 复杂校验、跨表保存、第三方协议硬编码 |
| config | 菜单分组、运行配置、开关、外部依赖配置 | 业务数据 |

优先级：

1. 能靠 Model + page JSON 表达的，不写 API。
2. 保存前后需要规范化、跨表校验、级联写入时，写 Service Provider hook。
3. 内置后台能力无法表达的 HTTP 行为，才写 API。
4. 前端已经打包时，不查、不改前端源码，只写 page JSON。
5. 只要是后台页面，page JSON 是默认方案，不需要用户在需求里显式声明。
6. 设计 Service 时只声明真实业务用例，不为每个模型默认创建 Service；普通 CRUD 继续交给 Model + page JSON，只有状态流转、跨表编排、复杂校验、外部协议、异步任务等真实业务逻辑才进入 Service。

### 0.2 不要复制复杂度

写新项目时，禁止从本地项目里整页复制复杂页面。

正确做法：

1. 从需求得到页面矩阵。
2. 按 `front-page.md` 的模板生成页面。
3. 只在必要处参考 GitHub 上的 `demo`、`package/front`、`package/bot` 局部写法。
4. 业务复杂度进 Service / Provider，不进 JSON DSL。

### 0.3 AI 必须先产出设计摘要

在写代码前，AI 先输出一个简短设计摘要：

```md
模块：
- user：用户、认证、资料
- order：订单、支付、退款

模型：
- User：账号主体
- Order：订单主表
- OrderItem：订单明细

页面：
- user/list：用户列表
- user/update：用户编辑
- order/list：订单列表
- order/view：订单详情

后台实现：
- 默认使用 package/front + page JSON
- 普通 CRUD 不写自定义 API

需要 service：
- OrderService.CancelOrder：订单取消状态流转
- OrderHook.BeforeSaveOrder：保存前规范化明细

需要 API：
- payment/callback：第三方回调，不能用后台 CRUD 表达
```

如果设计摘要无法写清，先继续查代码或向用户确认，不能直接写实现。

## 1. 需求输入模板

当用户让 AI 做完整项目时，优先让用户按下面给信息；用户没有给全时，AI 根据合理默认值继续，但要在交付中说明假设。

```md
项目名：
业务目标：
主要角色：
核心模块：
核心实体：
页面需求：
权限需求：
状态流转：
导入导出：
上传/资源库：
第三方接口：
性能/并发要求：
```

极简输入也可以：

```md
做一个合同管理后台：
- 合同、客户、付款计划、回款记录
- 合同有草稿/审核中/已生效/已作废
- 要列表、编辑、详情、回款记录子表、导出
```

AI 要把极简输入扩展成“模块、模型、页面、服务、接口”五类清单。

## 2. 项目交付矩阵

完整项目开始前先建立矩阵。矩阵不是文件，可以在回复里输出，也可以作为实施清单使用。

### 2.1 模块矩阵

| 模块 | 业务职责 | 主要模型 | 是否需要 API | 是否需要后台页面 |
| --- | --- | --- | --- | --- |
| contract | 合同主业务 | Contract, ContractPayPlan | 少量 | 是 |
| customer | 客户资料 | Customer | 否 | 是 |
| finance | 回款记录 | Receipt | 可能 | 是 |

### 2.2 模型矩阵

| 模型 | 表 | 关键字段 | Options | Relations | 索引 |
| --- | --- | --- | --- | --- | --- |
| Contract | contract | no, customer_id, status, amount | status | customer_id -> Customer | no unique, customer_id/status |
| Customer | customer | name, phone, status | status | - | phone |

设计规则：

- 每个页面字段都应尽量来自 Model 注释。
- 枚举字段优先写在 `orm.ModelConfig.Options`。
- 关联字段优先写在 `orm.ModelConfig.Relations`。
- 列表筛选字段必须有索引或能接受当前数据量。
- 状态流转字段要有明确 Options，不要用裸数字。

### 2.3 页面矩阵

| 页面 | 文件 | 类型 | model/use | parent | 关键能力 |
| --- | --- | --- | --- | --- | --- |
| 合同列表 | `module/contract/page/list.json` | 可见列表 | 默认 Contract | `business` | 搜索、筛选、导出、删除 |
| 合同编辑 | `module/contract/page/update.json` | 隐藏表单 | Contract | `contract/list` | 基本信息、付款计划子表 |
| 合同详情 | `module/contract/page/view.json` | 隐藏详情 | Contract | `contract/list` | 只读展示、回款记录 |
| 客户列表 | `module/customer/page/list.json` | 可见列表 | Customer | `business` | 搜索、编辑 |

页面设计规则：

- 可见菜单页 `type: 1`，挂一级菜单 key。
- 编辑、详情、弹窗、嵌入子页 `type: 2`，挂入口列表 page path。
- 子列表优先用父表单数组保存；真正独立生命周期的子资源才做独立页面。
- 复杂 dashboard / 统计页用 Provider 提供数据，JSON 只负责布局和展示。

### 2.4 动作矩阵

| 动作 | 实现方式 | 原因 |
| --- | --- | --- |
| 普通新增/编辑 | page `save` | front 内置能力可覆盖 |
| 普通删除 | page `delete` | front 内置能力可覆盖 |
| 保存前规范化 children | `before` service provider | JSON 不写复杂转换 |
| 状态流转 | API 或 page action + service | 需要校验当前状态 |
| 导出 | page `export` + provider | 需要指定查询/行转换 |
| 第三方回调 | API | 非后台 CRUD |

## 3. 推荐实施顺序

### 3.1 空项目

1. 读 `references/boot.md`。
2. 执行冷启动脚本。
3. 确认 `.gitignore` 已补齐，且 `data/readme.txt`、`package/readme.txt` 占位文件存在。
4. 安装并启动 `dever run`。
5. 建立模块矩阵、模型矩阵、页面矩阵。
6. 生成核心业务模块骨架。
7. 写 Model。
8. 写必要 Service / Provider。
9. 写 page JSON。
10. 补 API。
11. 自查生成文件、路由、load 注册名。

### 3.2 现有项目

1. 先查现有目录和可复用实现：
   - `module/*/model`
   - `module/*/service`
   - `module/*/api`
   - `module/*/page`
   - `package/*/page`
   - `config/front.json(c)`
2. 判断新增还是扩展。
3. 输出变更矩阵。
4. 最小范围编辑。
5. 让 `dever run` 或调试命令刷新生成文件。
6. 交付变更清单。

## 4. Model 设计细则

### 4.1 字段设计

常见字段约定：

| 业务含义 | 推荐字段 |
| --- | --- |
| 主键 | `ID uint64` |
| 名称 | `Name string` |
| 编码 | `Code string` / `No string` |
| 状态 | `Status int16` |
| 排序 | `Sort int` |
| 创建时间 | `CreatedAt time.Time` |
| 更新时间 | 按项目已有约定 |
| 归属用户 | `Uid uint64` |
| 归属组织 | `OrgID uint64` |

状态字段必须配 Options，例如：

```go
var contractStatusOptions = []map[string]any{
    {"id": 1, "value": "草稿"},
    {"id": 2, "value": "审核中"},
    {"id": 3, "value": "已生效"},
    {"id": 4, "value": "已作废"},
}
```

### 4.2 索引设计

必须考虑：

- 唯一编码：`unique:"no"`
- 父子关系：`index:"contract_id,status,sort"`
- 常用筛选：`index:"status,created_at"`
- 用户隔离：`index:"uid,status,id"`

不要为每个字段都建索引。只给查询路径建索引。

### 4.3 Relations

后台页面要展示关联名称时，优先用 Relation：

```go
Relations: []orm.Relation{
    {
        Field:      "customer_id",
        Option:     "customer.NewCustomerModel",
        OptionKeys: []string{"name"},
    },
}
```

page JSON 里再用 `show-base` / `show-select` / `meta.field` 展示，不要写一堆自定义接口。

## 5. Service / Provider 设计细则

### 5.1 什么时候必须写 Service

不要为每个模型默认创建 Service。只有 page JSON、Model 默认能力或简单 Provider 不能清楚表达业务规则时，才写 Service。

- 保存前需要规范化 children。
- 保存前要做跨表唯一校验。
- 状态流转需要检查当前状态。
- 删除不是简单软删。
- 列表需要聚合统计或批量补充字段。
- 导入导出需要特殊转换。
- 第三方接口需要签名、回调、轮询。

### 5.2 Provider 分类

| 类型 | 用途 | 命名建议 |
| --- | --- | --- |
| Save hook | 保存前后处理 | `ProviderBeforeSaveXxx` / `ProviderAfterSaveXxx` |
| Delete hook | 删除前后处理 | `ProviderBeforeDeleteXxx` |
| Load data | 页面初始化数据 | `ProviderLoadXxx` |
| Option | 动态选项 | `ProviderLoadXxxOptions` |
| Export | 导出行转换 | `ProviderXxxRows` |

Provider 必须返回 page/action 能消费的简单结构，不要返回复杂对象。

## 6. API 设计细则

优先不要为后台 CRUD 写 API。

需要 API 时，保持薄 handler：

```go
func (OrderAPI) PostCancel(c *server.Context) {
    id := util.ToUint64(c.Input("id"))
    if id == 0 {
        c.Error("订单ID不能为空")
        return
    }
    if err := (service.OrderService{}).Cancel(c.Context(), id); err != nil {
        c.Error(err.Error())
        return
    }
    c.JSON(map[string]any{"id": id})
}
```

规则：

- 入参统一 `c.Input(...)`。
- 鉴权用户按项目中间件约定取。
- Service 返回业务错误，API 只转成响应。
- 不在 API 里直接写长事务和复杂 SQL。

## 7. 复杂后台 JSON 设计流程

复杂后台不要一次写一大坨 JSON。先拆页面，再拆区域。

### 7.1 页面类型选择

| 需求 | 首选模板 |
| --- | --- |
| 普通管理 | `front-page.md` 标准列表页 + 编辑页 |
| 大表单 | 编辑页 + `nav-tab` / 分区 card / 子表单 |
| 主从表 | 父编辑页 + `form-array` 或嵌入子列表 |
| 左树右表 | 两栏分类 + 列表 |
| 配置项 | 固定配置页 / 单条 upsert |
| 统计首页 | Provider 数据 + stat card + chart |
| 导入导出 | 标准列表页 + import/export action |
| 资源管理 | 上传/资源库节点 |
| 第三方渠道参数 | 服务参数映射 + 固定值/路径 key |

### 7.2 复杂页面拆区

建议布局：

```txt
page-header
  - show-title
  - header-actions
page-main
  - search-card / toolbar-row
  - content-row
    - left-panel
    - right-panel
  - table-card / form-card
  - feedback-modal / drawer / confirm
```

规则：

- 页面标题、说明、操作按钮放 header。
- 搜索和批量操作放 toolbar。
- 主内容放 card/container。
- 弹窗/抽屉节点也挂在页面 layout 中，不写到表格列里面。
- 重复区域用 `form-array`、`show-table`、嵌入子页，不新增 DSL。

### 7.3 action 设计

先列动作，再写 JSON。

```md
动作：
- search：重置 table.page=1 后刷新列表
- reset-search：清空 search 后刷新
- open-create：打开编辑弹窗，清空 form
- open-update：把行数据写入 form，打开弹窗
- submit：save form，成功后关闭弹窗并刷新列表
- delete-row：设置 actionTarget.deleteRow，打开 confirm
- confirm-delete：delete actionTarget.deleteRow，成功后刷新列表
```

如果 action 需要复杂条件判断，写 Service / Provider，不要在 JSON 里硬凑。

### 7.4 数据路径约定

| 数据 | 推荐路径 |
| --- | --- |
| 搜索条件 | `data.search.*` |
| 表格 | `data.table.*` |
| 主表单 | `data.form.*` |
| 弹窗表单 | `data.dialogForm.*` 或复用 `data.form` |
| 当前操作行 | `data.actionTarget.*` |
| 静态选项 | `data.option.*` |
| 弹窗状态 | `state.dialog.*` |
| 抽屉状态 | `state.drawer.*` |
| 确认框状态 | `state.confirm.*` |
| 当前 tab | `state.currentTab` |

不要把业务数据放 `state`，不要把运行态开关放 `data`。

## 8. 复杂后台常用组合

### 8.1 列表 + 弹窗编辑

适合字段少、编辑上下文简单的资源。

文件：

```txt
module/<module>/page/<resource>/list.json
```

页面包含：

- `data.table`
- `data.search`
- `data.form`
- `state.dialog.open`
- `feedback-modal`
- `show-table`
- `save/delete` action

### 8.2 列表 + 独立编辑页

适合大表单、tab、多子表、复杂校验。

文件：

```txt
module/<module>/page/<resource>/list.json
module/<module>/page/<resource>/update.json
```

列表页负责入口，编辑页负责完整表单。

### 8.3 父表单 + 子表数组

适合子项只随父记录保存，没有独立生命周期。

做法：

- 父 form 持有 `children` 数组。
- 页面用 `form-array` 编辑。
- 父 `submit` 保存。
- `BeforeSave` hook 规范化 children。

### 8.4 父详情 + 子资源列表

适合子资源有独立新增、删除、审核、导出。

做法：

- 父详情页 `layout.path` 嵌入子列表页。
- 子列表通过 `parent.data.form.id` 作为筛选条件。
- 子资源单独 model 和页面。

### 8.5 第三方渠道参数后台

做法：

- host/path/model 都后台配置。
- 请求体字段用服务参数映射生成。
- 固定协议常量用固定值映射。
- 数组/对象用字段标识路径表达：
  - `content[0].type`
  - `content[0].text`
  - `content[1].image_url.url`

不要在 provider 里为单个模型写死 `task_type`、`role`、`size` 等参数。

## 9. 交付自查

### 9.1 代码自查

- 是否复用了现有模块/服务/工具？
- Model 是否包含必要 Options / Relations / Index？
- Service 是否承载业务规则？
- API 是否薄？
- Provider 名称是否可由生成文件注册？
- 是否没有手改生成文件？
- 是否考虑分页、索引、并发状态流转？

### 9.2 Page JSON 自查

- 页面归属是否正确？
- `page.parent/type/auth` 是否正确？
- model 是否能自动命中？
- 枚举列是否有 option？
- 关联列是否有 relation 或 `meta.field`？
- 搜索、表格、表单路径是否符合约定？
- 弹窗/确认框状态是否在 `state`？
- 保存/删除 action 是否使用内置能力？
- 复杂转换是否放到 service hook？
- 是否没有发明前端不支持的节点/action？

### 9.3 交付说明

最终回复至少包含：

```md
改动文件：
- ...

新增/修改模型：
- ...

新增/修改页面：
- ...

Service/Provider：
- ...

API 路由：
- ...

后台使用方式：
- ...

未执行项：
- 未执行 build/test（如用户要求不跑）
```

## 10. AI 执行提示词模板

用户可以这样让 AI 交付完整项目：

```md
使用 shemic-dever skill，按完整项目模式开发。

项目：合同管理后台
模块：
- customer：客户资料
- contract：合同主表、付款计划、回款记录

要求：
- 只要后台，不需要写前端源码
- 页面通过 page JSON 实现
- 普通 CRUD 走 package/front
- 复杂保存写 service hook
- 不要手改生成文件
- 不要复制当前本地项目页面
```

AI 收到后应先输出矩阵和实施顺序，再开始改文件。
