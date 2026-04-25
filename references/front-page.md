# package/front Module Page Playbook

这个文档专门回答：在 `module/<name>` 业务模块里，如何利用 `package/front` 提供的通用后台能力编写页面 JSON。

它不是 `backend/package/front` 源码开发手册。默认目标是消费已有 front 能力，优先写：

```txt
backend/module/<module>/model/*.go
backend/module/<module>/page/**/*.json(c)
backend/module/<module>/service/*.go  # 仅特殊逻辑需要
backend/module/<module>/api/*.go      # 仅特殊接口需要
```

## 1. 核心原则

1. 页面结构写在 `module/*/page/**/*.json(c)`。
2. 标准字段、索引、关系优先写在 model。
3. 字段文案优先来自 model 的 `comment`。
4. 选项、关联关系优先写 `frontmeta.Options` / `frontmeta.Relations`。
5. 列表、编辑、详情、导入、导出、上传、资源库优先复用 `package/front`。
6. 只有特殊业务规则才补 service / api。
7. 不要为了单个业务页面改 `package/front`；只有可复用的通用后台能力缺失时才扩展 front。
8. 页面 JSON 只描述结构、数据绑定和动作，不写复杂业务逻辑。

## 2. 参考样例优先级

写业务后台页面时，按这个顺序找参考：

1. 当前项目内最完整样例：
   - `module/user/page/list.json`
   - `module/user/page/update.json`
   - `module/user/page/view.json`
   - `module/user/page/stat.json`
   - `module/user/page/config/set.json`
2. 当前项目内简单样例：
   - `module/work/page/list.json`
   - `module/work/page/update.json`
   - `module/work/page/type/list.json`
3. 外部完整 demo：
   - https://github.com/dever-project/demo

规则：

- 优先参考当前项目，因为它最贴近正在开发的 front 版本和 UI 风格。
- 当前项目没有对应模式时，再参考 `dever-project/demo`。
- 参考外部 demo 时只借鉴页面组织、model/meta/page JSON 写法，不要直接照搬无关业务结构。
- 如果外部 demo 与当前项目源码行为冲突，以当前项目的 live 代码和 `package/front` 运行时为准。

## 3. package/front 初始化检查

在写 `module/*/page/**/*.json(c)` 之前，先确认当前项目已经接入 `package/front`。如果没有接入，先完成 front 初始化，再写业务页面。

优先方式：

```bash
dever package front
```

如果当前项目的 `dever` 版本还没有提供 `package front` 命令，就按等价接入方式补齐下面这些文件和配置。不要假设所有 Dever 版本都有该子命令；先试命令或检查 `dever/cmd/dever/main.go` 的命令列表。

### 3.1 go.mod

确认存在 front 依赖：

```go
require github.com/dever-package/front v0.0.0
```

本地联调时可以有 replace：

```go
replace github.com/dever-package/front => ./package/front
```

规则：

- 普通项目优先使用远程包版本。
- 当前仓库这种本地联调项目可以使用 `replace => ./package/front`。
- 不要在业务 module 里复制 front 的源码。

### 3.2 module/front/main.go

确认存在：

```go
package front

// dever:import github.com/dever-package/front
```

这个文件的作用是告诉 Dever 路由和生成器：当前项目要加载 `github.com/dever-package/front` 包里的 api/model/service/page 能力。

### 3.3 module/frontfs.go

确认存在：

```go
package module

import "embed"

// FrontFS 内嵌所有模块下的页面 JSON，便于直接打包进二进制。
//
//go:embed */page
var FrontFS embed.FS
```

这个文件是把 `module/*/page` 下页面 JSON 打进二进制的项目约定。

注意：以当前 front 运行时源码为准，开发期页面读取优先来自磁盘 `module/<module>/page/**/*.json(c)`；`front/*` 内置页面来自 `github.com/dever-package/front` 自身的 embedded `PageFS`。如果目标是纯二进制部署并希望业务页面也从 embed 读取，先确认当前 front 版本已经消费项目侧 `FrontFS`，不要只凭文件存在下结论。

### 3.4 config/front.json(c)

确认存在后台菜单基础配置，例如：

```json
{
  "auth": [
    {
      "key": "tongyong",
      "name": "通用",
      "icon": "layout-grid",
      "type": 1,
      "sort": 1
    }
  ]
}
```

业务页面的 `page.parent` 通常指向这里的 `key`，例如：

```json
{
  "page": {
    "name": "用户列表",
    "parent": "tongyong"
  }
}
```

### 3.5 middleware

如果使用 front 的权限、菜单和后台启动数据，确认中间件里有 front bootstrap 逻辑。

常见方式：

```go
import permissionservice "github.com/dever-package/front/service/permission"
```

并在 `/front/*` 请求时执行：

```go
permissionservice.EnsureBootstrap(c.Context())
```

规则：

- 认证仍优先复用 Dever JWT。
- front bootstrap 只做前台后台权限和菜单初始化，不要在业务 API 里重复做。

### 3.6 生成路由

接入 front 后，保持 `dever run` 运行，或调试时执行：

```bash
dever init --skip-tidy
```

生成后的 `data/router.go` 应该能看到类似路由：

```txt
/front/main/info
/front/route/info
/front/route/action
/front/route/option
/front/upload/init
/front/import/analyze
/front/export/task_create
```

不要手改 `data/router.go`。如果这些路由缺失，优先检查 `module/front/main.go`、`go.mod` 和 `dever init`。

### 3.7 初始化门禁

当用户要求“新增后台页面”“写 module page JSON”“使用 package/front 做后台”时，先做这个判断：

1. 已存在 `module/front/main.go`、`module/frontfs.go`、`config/front.json(c)`，并且 `go.mod` 有 front 依赖：直接写业务页面。
2. 缺少 front 接入文件：先执行 `dever package front`；如果命令不可用，则按本节手工补齐。
3. front 路由未生成：保持 `dever run` 运行，或调试时执行 `dever init --skip-tidy`。

## 4. 运行时事实

写页面前先记住这些运行时规则，它们直接来自 `package/front` 和 `dever` 源码。

### 4.1 页面路径

`/front/route/info?path=<path>` 会读取页面配置：

- 业务页面：`module/<module>/page/<file>.jsonc` 或 `.json`
- front 内置页面：`github.com/dever-package/front/page/**/*.json`

路径会做归一化：

```txt
/user/list        -> user/list
user/list         -> user/list
user\list         -> user/list
```

路径至少需要两段，例如 `user/list`、`work/type/list`。

### 4.2 默认模型命名

front 会根据页面路径推导 model 名称。为了让页面少写配置，model 构造函数要能被默认规则命中。

| 页面路径 | 优先候选 |
| --- | --- |
| `user/list` | `user.NewUserModel` |
| `user/update` | `user.NewUserModel` |
| `work/type/list` | `work.NewTypeModel`，然后 `work.NewWorkTypeModel` |
| `order/item/update` | `order.NewItemModel`，然后 `order.NewOrderItemModel` |

因此业务 model 推荐：

```go
func NewUserModel() *orm.Model[User] { ... }
func NewWorkTypeModel() *orm.Model[WorkType] { ... }
```

不要为要接入 front 的普通资源写成 `UserModel()`、`ArticleModel()`，否则默认列表、表单、标签、导入导出可能无法自动命中。

如果确实需要指定 model：

- 列表：`data.table.list = "<<module.NewXxxModel>>"`
- 表单：`data.form._model` 或 `data.form._use`
- action：`action.submit.use`

### 4.3 data 自动加载

列表页自动加载条件：

- 页面路径以 `/list` 结尾。
- 某个 data 容器有 `page`、`pageSize`、`total`。
- `list` 缺失或为 `null`。

常见写法：

```json
{
  "data": {
    "search": {
      "keyword": ""
    },
    "table": {
      "page": 1,
      "pageSize": 10,
      "total": 0,
      "searchFields": ["name"]
    }
  }
}
```

front 会自动补：

- `table.list`
- `table.total`
- `table.page`
- `table.pageSize`
- `option.*`

表单页自动加载条件：

- 页面路径以 `/update`、`/create`、`/view`、`/detail`、`/info` 结尾。
- 存在 `data.form`。
- URL query 或 form 模板里有 `id` 时自动读取记录。

常见写法：

```json
{
  "data": {
    "form": {}
  }
}
```

### 4.4 查询和过滤

`data.search` 会和 URL query 同步。列表查询常用：

```json
{
  "data": {
    "search": {
      "keyword": "",
      "status": ""
    },
    "table": {
      "page": 1,
      "pageSize": 10,
      "total": 0,
      "searchFields": ["name", "code"],
      "filterFields": [
        {
          "field": "status",
          "type": "exact"
        },
        {
          "field": "created_at",
          "type": "date-range",
          "startKey": "created_at_start",
          "endKey": "created_at_end"
        }
      ],
      "order": "id desc"
    }
  }
}
```

关系字段过滤会优先走 `frontmeta.BuildRelationFilter`，所以多对多字段要优先配置 `frontmeta.Relation`。

### 4.5 后端 action 边界

`/front/route/action` 当前后端只直接处理：

- `save`
- `delete`

其他页面动作，例如 `modal`、`data`、`import`、`export`，由前端运行时或对应 front API 处理：

- 导入：`/front/import/*`
- 导出：`/front/export/*`
- 选项：`/front/route/option`

所以复杂保存逻辑应该挂在 `action.submit.before/after` 的 service hook 中，而不是发明新的页面 action 类型。

### 4.6 权限和菜单

front bootstrap 会合并：

- `config/front.json(c)` 中的 `auth`
- `module/*/page/**/*.json(c)` 中的 `page`
- 页面节点里 `import`、`export`、`delete` 动作生成的普通权限
- front 包自身内置页面权限

菜单只展示 `type=1` 权限，普通操作权限是 `type=2`。

删除、导入、导出动作会按 action 的 key 自动生成权限。为避免权限 key 不稳定，给按钮或 action 显式配置稳定的 `key` / `importKey` / `exportKey`。

### 4.7 data 占位符

`data` 中支持两类后端占位符：

```json
{
  "data": {
    "stat": "{{user.StatService.LoadUserStat}}",
    "table": {
      "list": "<<user.NewUserModel>>"
    }
  }
}
```

规则：

- `{{Service.Provider}}`：调用 `load.Service(name, c)`，适合统计页、固定配置页、复杂聚合数据。
- `<<Model.Provider>>`：解析 model，常用于显式指定列表数据模型。
- 普通列表/编辑页优先使用默认模型命名规则；只有默认规则无法命中时再写占位符。

## 5. 开发顺序

新增一个后台业务页面时，按这个顺序：

0. 先按上一节确认 `package/front` 已安装和加载。
1. 先看同类页面：
   - 列表页：`module/user/page/list.json`
   - 编辑页：`module/user/page/update.json`
   - 详情页：`module/user/page/view.json`
   - 统计页：`module/user/page/stat.json`
   - 简单字典页：`module/work/page/type/list.json`
2. 定义或确认 model 字段、索引、comment。
3. 如果有选项或关联，补 `frontmeta.RegisterModelMeta(...)`。
4. 写 `page/list.json` 或 `page/update.json`。
5. 特殊保存、导入、导出、联动逻辑再补 service/provider。
6. 如新增 API / model / service，保持 `dever run` 运行，让它自动刷新生成文件。

## 6. 推荐目录

```txt
module/<name>/
  model/
    <resource>.go
  page/
    list.json
    update.json
    view.json
    stat.json
    <child>/
      list.json
      update.json
  service/
    <resource>.go
```

路径层级会参与后台页面和菜单组织。不要把多个无关资源塞进一个巨大页面。

## 7. page 基础结构

常见页面结构：

```json
{
  "page": {},
  "layout": {},
  "nodes": {},
  "data": {},
  "state": {},
  "action": {}
}
```

实际页面可以省略空字段，由 `package/front` 补默认值。

`page` 常用字段：

```json
{
  "page": {
    "name": "用户列表",
    "icon": "users",
    "parent": "tongyong",
    "sort": 1
  }
}
```

规则：

- `name` 是菜单和页面标题。
- `icon` 使用 front 支持的图标名。
- `parent` 指向 `config/front.json(c)` 或其他页面 key。
- `sort` 控制菜单排序。
- 需要特殊权限时再配置 `auth`。

## 8. layout 写法

layout 只负责页面结构，nodes 负责内容挂载。

常见列表页骨架：

```json
{
  "layout": {
    "type": "container",
    "children": {
      "page-header": {
        "type": "header",
        "children": {
          "header-actions": {
            "type": "row",
            "className": "ms-auto shrink-0 flex-nowrap items-center gap-2"
          }
        }
      },
      "page-main": {
        "type": "main",
        "className": "flex flex-1 flex-col gap-5 sm:gap-6",
        "children": {
          "toolbar-row": {
            "type": "row",
            "className": "flex-wrap items-center gap-2.5"
          },
          "table-row": {
            "type": "container",
            "className": "overflow-hidden rounded-md border bg-background"
          }
        }
      }
    }
  }
}
```

常用 layout 类型：

- `container`
- `header`
- `main`
- `row`
- `col`

约束：

- layout id 要稳定，例如 `page-header`、`toolbar-row`、`table-row`。
- Tailwind class 尽量复用现有页面风格。
- 不要把业务逻辑塞进 layout。

## 9. nodes 写法

`nodes` 的 key 对应 layout id：

```json
{
  "nodes": {
    "page-header": [],
    "header-actions": [],
    "toolbar-row": [],
    "table-row": []
  }
}
```

常用节点：

- 展示：`show-rich`、`show-base`、`show-tag`、`show-select`、`show-status`
- 操作：`show-button`、`show-button-group`
- 表格：`show-table`、`show-page`
- 表单：`form-input`、`form-textarea`、`form-select`、`form-switch`、`form-date`、`form-password`、`form-editor`、`form-cascader`、`form-array`
- 上传：`form-upload`
- 媒体：`media-image`、`media-video`、`media-audio`、`media-file-list`
- 反馈：`feedback-modal`、`feedback-drawer`、`feedback-confirm`
- 导航：`nav-tab`
- 统计：`show-stat-card`、`show-chart`

优先复用现有节点。若某个节点多个业务都需要，才考虑扩展 `package/front` 的通用节点。

## 10. 列表页模式

列表页通常包含：

1. 页面标题。
2. 顶部操作按钮。
3. 搜索区。
4. 表格。
5. 分页。
6. 新增/编辑弹窗或抽屉。

最小结构：

```json
{
  "nodes": {
    "page-header": [
      {
        "type": "show-rich",
        "value": "page.titleHtml",
        "className": "min-w-0 flex-1"
      }
    ],
    "toolbar-row": [
      {
        "type": "form-input",
        "placeholder": "请输入关键词",
        "value": "search.keyword",
        "mode": "search"
      },
      {
        "type": "show-button",
        "name": "搜索",
        "meta": {
          "variant": "outline",
          "size": "sm"
        },
        "action": {
          "click": {
            "type": "request"
          }
        }
      }
    ],
    "table-row": [
      {
        "type": "show-table",
        "value": "table.list",
        "meta": {
          "columns": [
            {
              "name": "ID",
              "value": "id",
              "type": "show-base"
            },
            {
              "name": "名称",
              "value": "name",
              "type": "show-base"
            }
          ]
        }
      },
      {
        "type": "show-page"
      }
    ]
  }
}
```

规则：

- `value` 默认从页面 data 中取值。
- 搜索字段通常绑定 `search.*`。
- 表格数据通常绑定 `table.list`；`data.table` 满足自动加载条件时，`list` 可以省略。
- 分页优先使用 `show-page`。
- 表格列可复用展示节点，如 `show-base`、`show-tag`、`show-select`。

### 10.1 列表页进阶能力

`module/user/page/list.json` 是当前最完整的列表样例，覆盖搜索、tab、远程分页、批量操作、行内编辑、媒体列、嵌套表格和确认框。

表格常用 meta：

```json
{
  "type": "show-table",
  "value": "table.list",
  "meta": {
    "pagePath": "data.table.page",
    "pageSizePath": "data.table.pageSize",
    "totalPath": "data.table.total",
    "remote": true,
    "externalPagination": true,
    "rowKey": "id",
    "selectable": true,
    "bulkActions": []
  }
}
```

规则：

- 远程列表优先设置 `remote`、`externalPagination`、`pagePath`、`pageSizePath`、`totalPath`。
- 需要批量操作时设置 `selectable: true` 和 `bulkActions`，动作里可用 `$selectedRows`。
- 行操作优先放在 `show-button` 列的 `meta.buttons`。
- 表格列支持媒体节点：`media-image`、`media-audio`、`media-video`、`media-file-list`。
- 表格列也可以嵌套 `show-table`，适合展示行内子列表。
- `show-base` 列可设置 `editor: true` 做行内编辑。
- `show-select` 列可设置 `display: "badge"` 和 `confirmValues` 做状态切换确认。
- `data.table.service` 可指定 service 对查询后的 rows 做二次加工，例如 `user.UserListService.BuildDemoTable`。

搜索区常用能力：

- `nav-tab` 可做状态 tab，`variant` 常用 `pill` / `line` / `sidebar`。
- `searchLayoutId` 用于联动搜索区域。
- `form-date` 支持 `range`、`endValue`、`inputType: "datetime-local"`。
- 重置按钮可用 `meta.to` 返回当前列表地址。

## 11. 编辑页模式

编辑页通常用于弹窗、抽屉或独立页面。

最小结构：

```json
{
  "nodes": {
    "dialog-shell": [
      {
        "type": "form-input",
        "name": "名称",
        "placeholder": "请输入名称",
        "value": "form.name",
        "mode": "form",
        "validate": [
          {
            "type": "required",
            "message": "名称不能为空。"
          }
        ],
        "meta": {
          "formLayout": "horizontal"
        }
      }
    ]
  },
  "action": {
    "submit": {
      "type": "save"
    }
  }
}
```

规则：

- 表单字段通常绑定 `form.*`。
- `mode: "form"` 交给 front 渲染表单 label、错误、说明。
- 必填、邮箱、唯一性等规则放 `validate`。
- 复杂保存前后处理优先写 service/provider，再由 action 调用。

### 11.1 编辑页进阶能力

`module/user/page/update.json` 覆盖了比较完整的表单能力。

常用表单节点：

- `form-editor`：富文本，常用 `meta.minHeight`。
- `form-upload`：上传/资源库，常用 `uploadType`、`kind`、`saveMode`、`ruleId`、`maxCount`、`bizKey`、`bizName`。
- `form-cascader`：级联选择，常用 `api`、`type: "model"`、`use`、`parentField`、`rootValue`、`placeholder`、`labelTarget`。
- `form-array`：子表/数组编辑，常用 `pageRoute`、`addText`、`drag`。
- `form-password`：密码输入，适合配合条件校验。

常用 meta：

```json
{
  "formLayout": "horizontal",
  "tab": "basic",
  "controlClassName": "max-w-[260px]",
  "multiple": true,
  "optionFilter": [
    {
      "field": "type_id",
      "path": "form.role",
      "map": {
        "Manager": 1,
        "Admin": 2
      }
    }
  ]
}
```

规则：

- 多 tab 表单优先用 `nav-tab` 写 `state.currentTab`，每个字段用 `meta.tab` 标识归属。
- 表单控件宽度用 `controlClassName`，不要在 JSON 里重复堆大段样式。
- 下拉选项随其他字段变化时优先用 `optionFilter`。
- 子表编辑优先用 `form-array + pageRoute`，子项页面单独放到 `page/<child>/update.json`。

### 11.2 校验规则

常见校验：

```json
{
  "validate": [
    {
      "type": "required",
      "message": "不能为空。"
    },
    {
      "type": "model",
      "except": "$form.id",
      "message": "已存在。"
    },
    {
      "type": "sameAs",
      "target": "form.password",
      "message": "两次输入不一致。"
    }
  ]
}
```

规则：

- 唯一性校验用 `model`，`except` 排除当前记录。
- 密码、确认密码这类场景可用 `when` 和 `condition` 控制校验触发：
  - `operator: "empty"`
  - `operator: "notEmpty"`
  - `condition: "any"`
- 常见规则包括 `required`、`email`、`min`、`sameAs`、`model`。

### 11.3 配置单页 / upsert

固定单条配置页可使用 `data.form._model` 指定模型，并在 `action.submit` 中设置 `upsert: true`。

```json
{
  "data": {
    "form": {
      "id": 1,
      "_model": "user.NewConfigModel"
    }
  },
  "action": {
    "submit": {
      "type": "save",
      "use": "user.NewConfigModel",
      "params": "form",
      "data": {
        "id": 1,
        "name": "$form.name"
      },
      "upsert": true
    }
  }
}
```

适合系统设置、站点配置、单条业务配置。

### 11.4 详情页 / 只读展示

详情页通常使用 `view.json`，仍然走 `data.form` 自动加载记录，但节点使用展示和媒体组件：

- `show-base`
- `show-select`
- `show-status`
- `show-tag`
- `show-rich`
- `media-image`
- `media-video`
- `media-audio`
- `media-file-list`

规则：

- 详情页路径通常是 `module/resource/view`，通过 query `id` 加载记录。
- 只读字段也可以使用 `mode: "form"`，这样 label、说明和横向布局可以复用表单包裹。
- 关联对象展示优先用 `show-tag`，并通过 `meta.field` 指定显示字段，如 `name`。

### 11.5 统计页

统计页通常不直接绑定 model 列表，而是通过 service provider 返回聚合数据：

```json
{
  "data": {
    "stat": "{{user.StatService.LoadUserStat}}"
  }
}
```

常用节点：

- `show-stat-card`
- `show-chart`

示例：

```json
{
  "type": "show-chart",
  "value": "stat.statusRows",
  "meta": {
    "title": "用户状态分布",
    "description": "按账户状态统计用户数量。",
    "type": "pie",
    "nameKey": "name",
    "dataKey": "value",
    "height": 320
  }
}
```

规则：

- `show-stat-card` 用于摘要指标，常用 `title`、`description`、`icon`、`format`。
- `show-chart` 用于图表，常用 `type: "pie" | "bar"`、`nameKey`、`dataKey`、`height`。
- 统计数据优先由 service provider 聚合，不要在页面 JSON 里拼复杂统计逻辑。

## 12. 选项和关联

简单静态选项写在 `frontmeta.Options`：

```go
func init() {
    frontmeta.RegisterModelMeta("user.NewUserModel", frontmeta.ModelMeta{
        Options: map[string]any{
            "status": userStatusOptions,
        },
    })
}
```

页面中使用：

```json
{
  "type": "form-select",
  "value": "form.status",
  "option": "option.status",
  "mode": "form"
}
```

关联字段写 `frontmeta.Relation`：

```go
var workTypeRelation = frontmeta.Relation{
    Field:  "type_id",
    Option: "work.NewWorkTypeModel",
}

func init() {
    frontmeta.RegisterModelMeta("work.NewWorkModel", frontmeta.ModelMeta{
        Relations: []frontmeta.Relation{workTypeRelation},
    })
}
```

页面中可使用远程 option：

```json
{
  "type": "form-select",
  "value": "form.type_id",
  "option": "/front/route/option?type=model&use=work.NewWorkTypeModel",
  "mode": "form"
}
```

规则：

- 固定枚举：优先 `Options`。
- 单表关联：优先 `Relation` + model option。
- 多对多或子表：优先 `Relation.Through`。
- 上传资源：优先使用已有 upload relation 和 `form-upload`。

## 13. 导入和导出

导入导出预设放页面 JSON，不放 model。

导入按钮示例：

```json
{
  "type": "show-button-group",
  "name": "导入",
  "meta": {
    "variant": "outline",
    "size": "sm",
    "icon": "upload"
  },
  "items": [
    {
      "key": "import-user-list",
      "name": "导入用户",
      "action": {
        "click": {
          "type": "import",
          "uploadRuleId": 4,
          "matchFields": ["username", "email"],
          "matchMode": "any",
          "fields": [
            {
              "field": "username",
              "aliases": ["账号", "登录名"]
            }
          ]
        }
      }
    }
  ]
}
```

导出按钮示例：

```json
{
  "type": "show-button-group",
  "name": "导出",
  "meta": {
    "variant": "outline",
    "size": "sm",
    "icon": "download"
  },
  "items": [
    {
      "key": "export-list",
      "name": "导出列表",
      "action": {
        "click": {
          "type": "export"
        }
      }
    }
  ]
}
```

规则：

- 字段默认标题优先来自 model comment。
- Excel 列别名、缺失值策略、导入提示放 page JSON。
- 复杂导出用 service/provider，例如 `use: "user.ExportService.PrepareUserWorkbook"`。

## 14. 弹窗、抽屉、确认框

打开弹窗通常用 `modal` action：

```json
{
  "type": "show-button",
  "name": "新增",
  "action": {
    "click": {
      "type": "modal",
      "key": "drawer.open",
      "value": true
    }
  }
}
```

弹窗节点：

```json
{
  "type": "feedback-drawer",
  "meta": {
    "stateKey": "drawer.open",
    "title": "新增用户",
    "pageRoute": "/user/update"
  }
}
```

表格行编辑常见模式：

1. `data` action 把当前行写入 `form` 或 `state.current`。
2. `modal` action 打开弹窗/抽屉。
3. 弹窗内加载 update 页面或当前页面表单。

## 15. action 使用规则

常见 action：

- `request`：刷新列表、提交搜索。
- `data`：写页面 data。
- `modal`：控制弹窗、抽屉、确认框状态。
- `save`：保存表单。
- `delete`：删除记录。
- `import`：导入。
- `export`：导出。
- `service`：调用特殊 service/provider。

规则：

- 简单页面交互写 action。
- 复杂业务规则写 service/provider。
- 多个节点重复的动作要抽到 page 的 `action` 中复用。
- 不要在页面 JSON 里堆复杂条件逻辑；复杂逻辑放 service。
- 保存 action 的标准名称优先用 `submit`，因为 front 会用它推导当前提交模型和表单选项。
- `before` hook 可以修改并返回 payload；`after` hook 只处理副作用。
- front 调 service hook 时会传 `params[0]` 作为 payload map。

保存 hook 示例：

```json
{
  "action": {
    "submit": {
      "type": "save",
      "params": "form",
      "before": {
        "type": "service",
        "use": "user.UserUpdateHook.BeforeSaveUserUpdate"
      },
      "after": {
        "type": "service",
        "use": "user.UserUpdateHook.AfterSaveUserUpdate"
      }
    }
  }
}
```

对应 Provider：

```go
func (UserUpdateHook) ProviderBeforeSaveUserUpdate(c *server.Context, params []any) any {
    payload, _ := params[0].(map[string]any)
    // 返回修改后的 payload
    return payload
}
```

## 16. 与 model / service 的分工

放 model：

- 字段。
- 索引。
- 关系。
- 标准字段文案。
- 枚举选项。

放 page JSON：

- 页面布局。
- 表格列。
- 表单字段。
- 搜索项。
- 按钮。
- 弹窗。
- 导入导出预设。

放 service/provider：

- 保存前后钩子。
- 跨表业务规则。
- 特殊导入导出。
- 特殊统计。
- 复杂权限过滤。

放 api：

- 只有通用 front action 无法覆盖的 HTTP 接口。

## 17. 自查清单

交付页面前检查：

- 项目是否已经安装/加载 `package/front`？
- `/front/main/info`、`/front/route/info`、`/front/route/action` 等 front 路由是否已生成？
- model 构造函数是否能被默认模型命名规则命中？
- 列表页的 `data.table` 是否满足自动加载条件，还是明确指定了 `<<Model>>`？
- 编辑页是否使用 `data.form`，并通过 query `id` 或 `_model/_use` 明确加载模型？
- 是否复用了同类页面结构，而不是重新发明一套？
- 字段文案是否优先来自 model comment？
- 选项/关联是否优先放 `frontmeta`？
- 列表、编辑、导入、导出是否优先使用 `package/front`？
- 是否避免把业务逻辑塞进 JSON？
- 是否只有确实需要时才新增 service/api？
- 是否没有手改 `data/router.go`、`data/load/model.go`、`data/load/service.go`？
- 如果扩展了通用节点，是否能服务多个业务，而不是只服务一个页面？
