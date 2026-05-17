# Dever Page JSON 编写手册

本手册用于指导 AI 直接编写后台页面 JSON。

目标不是让 AI 到项目里临时找一个完整页面照抄，也不是让 AI 修改前端源码，而是让 AI 按本文的规则、模板和检查清单生成一个新的、可维护的 page JSON。

前端运行时可能已经被打包，项目里不一定存在 `front/` 源码目录。写 page JSON 时不要依赖 `front/src`，不要查找或修改前端组件，只需要使用本文约定的布局、节点、数据和动作协议。

默认规则：

- 使用 `shemic-dever` skill 做后台时，默认就是通过 `package/front + page JSON` 实现。
- 用户不需要显式说“通过 JSON 实现后台”。
- 普通 CRUD、列表、编辑、详情、统计、导入导出、上传资源等后台能力，优先写 page JSON。
- 不要因为需求里没写 JSON，就改前端源码或手写 CRUD API。

适用范围：

```txt
backend/module/<module>/page/**/*.json(c)
backend/package/<package>/page/**/*.json(c)
backend/package/front/page/**/*.json(c)
```

本文已经把 GitHub 源里的三类 page JSON 作为覆盖基线整理进文档：

- `package/front/page/**/*.json`：账号、角色、权限、资源中心、上传规则、存储、上传分类等通用后台。
- `package/bot/page/**/*.json`：来源服务、能力、参数、分类、日志、服务端点、服务参数映射等复杂后台。
- `module/user/page/**/*.json`：业务列表、编辑、详情、统计、配置、内容、来源、导入导出等业务模块页面。

后续 AI 写页面时，不需要再到当前 workspace 找完整页面照抄；如果确实要看原始样例，只能看 GitHub 上对应的 `demo`、`package/front`、`package/bot`、`module/user`，不能把本地副本当作标准。

不适用范围：

- 前端源码、组件、路由、状态管理开发。
- 后台通用运行时能力改造。
- 业务 API / service / model 的完整开发手册；这些仍以 `module.md` 为准。

## 0. JSON 如何描述一个页面

写 page JSON 时，把页面拆成 6 件事：

| 字段 | 负责什么 | 写法重点 |
| --- | --- | --- |
| `page` | 页面身份、标题、菜单、权限 | 写 `name/icon/parent/type/sort/auth` |
| `layout` | 页面区域结构 | 用 `container/header/main/row/col` 等布局搭骨架 |
| `nodes` | 每个区域里显示什么 | 按 layout id 挂载表单、表格、按钮、弹窗等节点 |
| `data` | 业务数据初始值 | 放 `search/table/form/option/actionTarget` |
| `state` | 页面临时状态 | 放弹窗开关、当前 tab、当前选中行等 |
| `action` | 用户操作后做什么 | 保存、删除、改 data/state、打开弹窗、导入导出等 |

生成页面的核心顺序：

1. 先定页面类型：列表、编辑、详情、配置页、嵌入子列表、两栏分类页。
2. 再定数据来源：默认 model、显式 `_model/use/<<Model>>`、或 service。
3. 再画布局：页面头部、工具栏、内容卡片、表格、反馈弹窗。
4. 再挂节点：字段绑定 `form.*`，搜索绑定 `search.*`，表格绑定 `table.list`。
5. 最后补动作：按钮打开弹窗、确认删除、表单 `submit` 保存。

不要在 JSON 里写复杂业务逻辑。JSON 负责描述页面，复杂校验、数据规范化、跨表保存放 service/provider。

复杂后台不要从单个 JSON 文件开始写。先做页面矩阵，再逐页落地：

| 步骤 | 输出 | 目的 |
| --- | --- | --- |
| 1 | 菜单树 | 确认一级菜单、业务分组、可见入口 |
| 2 | 页面矩阵 | 确认每个页面的 path、parent、type、model、能力 |
| 3 | 数据矩阵 | 确认每页的 `search/table/form/option/state` |
| 4 | 动作矩阵 | 确认 save/delete/modal/page/request/import/export 等动作 |
| 5 | Service 矩阵 | 把 JSON 无法表达的校验、规范化、跨表保存放到 Provider |

页面矩阵示例：

| 页面 | 文件 | parent | type | model/use | 关键节点 |
| --- | --- | --- | --- | --- | --- |
| 合同列表 | `module/contract/page/list.json` | `business` | `1` | `contract.NewContractModel` | search、show-table、export |
| 合同编辑 | `module/contract/page/update.json` | `contract/list` | `2` | `contract.NewContractModel` | form、form-array、submit |
| 合同详情 | `module/contract/page/view.json` | `contract/list` | `2` | `contract.NewContractModel` | readonly、嵌入回款列表 |

## 1. AI 写 page JSON 的优先级

写页面时按下面顺序判断，不再优先从当前项目里找完整样例。

1. **先按本文模板和规则生成。**
2. 再按 model 的 `comment`、`Options`、`Relations`、`Fields` 推导字段名、枚举、关联和表单类型。
3. 需要参考样例时，只参考 GitHub 上的官方样例，不参考当前本地项目里的页面。
4. 需要确认业务命名、父菜单、模型名、service 名时，只读取最小范围的业务代码或最小页面片段。
5. 如果本文没有列出某个节点、布局或 action，不要凭空发明；应换成本文已有能力，或明确说明需要先扩展运行时能力。

不要把当前项目里的复杂页面当成必须复制的标准。既有页面只说明“当前运行时支持这种写法”，不代表新页面也应该复制全部复杂度。

## 1.1 可参考的 GitHub 样例来源

如果需要看现成 page JSON，只允许参考 GitHub 上的这三类来源：

| 来源 | 适合参考什么 | 注意 |
| --- | --- | --- |
| GitHub 上的 `demo` | 普通业务模块页面、列表页、编辑页、统计页、配置页 | 用来理解业务 module 怎么组织 page JSON |
| GitHub 上的 `package/bot` | package 自带后台、复杂表单、父表单嵌入子列表、参数映射类页面 | 用来理解可复用 package 页面怎么写 |
| GitHub 上的 `package/front` | 内置后台页面、账号/角色/上传/资源等通用后台能力 | 用来理解通用 CRUD、权限、导入导出和上传资源页面 |

禁止把当前 workspace 里的本地页面当作参考标准，包括但不限于：

```txt
backend/module/*/page/**/*.json(c)
backend/package/bot/page/**/*.json(c)
backend/package/front/page/**/*.json(c)
```

原因：

- 本地项目可能有未提交改动、临时调试配置或业务定制。
- 本地 `package/bot`、`package/front` 可能是下载、生成或修改后的副本。
- 新页面要按 GitHub 上的标准样例和本文模板生成，避免把本地历史复杂度复制出去。

使用样例时的规则：

1. 先按本文模板写出页面骨架。
2. 只从 GitHub 样例里借鉴局部写法，例如某个节点、某类弹窗、某种表格操作列。
3. 不要整页复制 GitHub 样例；复制前必须删除无关字段、无关 action、无关 state。
4. GitHub 样例和本文冲突时，以本文为准。
5. GitHub 样例也没有覆盖时，优先退回到本文已有能力，不要发明新协议。

## 2. 页面归属和路径

页面路径由文件位置决定。

| 页面归属 | 文件位置 | URL/page path | 默认模型候选 |
| --- | --- | --- | --- |
| 项目业务模块 | `backend/module/user/page/list.json` | `user/list` | `user.NewUserModel` |
| 项目子资源 | `backend/module/user/page/content/list.json` | `user/content/list` | `user.NewContentModel`、`user.NewUserContentModel` |
| 可复用 package | `backend/package/bot/page/energon/provider/list.json` | `bot/energon/provider/list` | `bot.NewEnergonProviderModel`、`bot.energon.NewProviderModel` |
| front 内置页 | `backend/package/front/page/account/list.json` | `front/account/list` | `front.NewAccountModel` |

规则：

- 当前项目专属业务写到 `module/<module>/page`。
- package 自带后台写到 `package/<package>/page`。
- `backend/package/front` 指后端内置后台页面包，不是前端源码目录。
- `module/<name>/main.go` 如果只是 `// dever:import ...` 的 package 引入 shim，不要把 package 页面复制到 `module/<name>/page`。
- page path 不写文件后缀，例如 `/front/route/info?path=bot/energon/provider/list`。
- path 至少两段，例如 `user/list`、`front/account/list`、`bot/energon/provider/list`。

## 3. 写页面前先确认 model

page JSON 应尽量依赖 model 元信息自动推导 label、option、relation 和数据加载。

Model 推荐写法：

```go
func NewUserModel() *orm.Model[User] {
    return orm.LoadModel[User]("用户", "user", orm.ModelConfig{
        Order:    "id desc",
        Database: "default",
        Options: map[string]any{
            "status": statusOptions,
        },
        Relations: []orm.Relation{
            {
                Field:      "role_ids",
                Through:    "front.NewAccountRoleModel",
                OwnerField: "account_id",
                TargetField:"role_id",
                Option:     "front.NewRoleModel",
            },
        },
        Fields: map[string]orm.FieldConfig{
            "password": {Type: orm.FieldTypePassword},
        },
    })
}
```

规则：

- 字段中文名优先来自 struct tag 的 `comment`。
- 枚举优先放 `orm.ModelConfig.Options`。
- 关联优先放 `orm.ModelConfig.Relations`。
- 密码/隐藏字段优先放 `orm.ModelConfig.Fields`。
- model 文件不要 import `package/front/service/meta`，不要写 `frontmeta.RegisterModelMeta`。
- 页面 JSON 里不要重复写 model 已经能推导的 label 和 option，除非当前字段需要覆盖默认行为。
- 标准 `/list`、`/update`、`/create`、`/detail` 页面会按路径自动推导 model；如果页面是 `/set`、`/config`、自定义弹窗页等非标准路径，列表用 `data.table.list: "<<ModelName>>"`，表单用 `data.form._model` / `data.form._use`，保存用 `action.submit.use` 显式声明 model，让运行时继续自动推导 label、option、relation，不要为了补 label 给每个表单节点手写 `name`。

## 4. page JSON 顶层结构

标准顶层结构：

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

实际页面可以省略空对象，但新页面建议保留需要用到的部分。

### 4.1 page

```json
{
  "page": {
    "name": "用户列表",
    "icon": "users",
    "parent": "tongyong",
    "type": 1,
    "sort": 1
  }
}
```

字段：

| 字段 | 说明 |
| --- | --- |
| `name` | 菜单名、权限名、页面标题默认来源 |
| `title` | 标题备用字段；通常用 `name` 即可 |
| `icon` | 菜单图标 |
| `parent` | 父权限 key，可以是一级菜单 key，也可以是某个页面 path |
| `type` | `1` 可见菜单；`2` 隐藏页面或普通权限 |
| `sort` | 排序 |
| `auth` | 一个页面拆多个权限时使用，比如新增/编辑 |
| `init` | 页面初始化 action 名称数组 |

默认权限类型：

- `*/list` 默认是可见菜单 `type=1`。
- `*/update`、`*/view`、`*/detail` 默认是普通权限 `type=2`。
- 隐藏子列表、嵌入页、弹窗页建议显式写 `type: 2`。

编辑页常用 `auth`：

```json
{
  "page": {
    "name": "账户编辑",
    "parent": "front/account/list",
    "auth": [
      {
        "key": "front/account/create",
        "name": "账户新增",
        "query": { "id": "empty" }
      },
      {
        "key": "front/account/update",
        "name": "账户编辑",
        "query": { "id": "required" }
      }
    ]
  }
}
```

规则：

- 可见列表页挂一级分组，例如 `tongyong`、`system-settings`、`bot-energon`。
- 编辑页、详情页、隐藏子页挂入口列表，例如 `user/update` 的 parent 写 `user/list`。
- 从某个列表按钮进入的隐藏列表页也挂入口列表。例如来源服务页挂 `bot/energon/provider/list`，不要挂一级分组。

### 4.2 layout

layout 只负责结构，不放业务数据。

```json
{
  "layout": {
    "type": "container",
    "children": {
      "page-header": {
        "type": "header",
        "className": "gap-4",
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

支持类型：

- `container`
- `header`
- `footer`
- `main`
- `aside`
- `row`
- `col`

规则：

- `nodes` 的 key 必须对应 layout id。
- layout 可配置 `path` 嵌入子页面：

```json
{
  "type": "container",
  "path": "/bot/energon/service_param/list",
  "meta": {
    "updateDocumentTitle": false
  }
}
```

- 有 `path` 的 layout 会渲染子 Page，不再渲染当前 layout id 下的 nodes。
- 子页面拥有独立 store；子页访问父页用 `parent.data.*` / `parent.state.*`。
- JSON 里 Tailwind class 只放布局级或少量组件级样式，不把大量视觉细节暴露成业务配置。

### 4.3 nodes

`nodes` 按 layout id 挂载节点：

```json
{
  "nodes": {
    "page-header": [
      {
        "type": "show-title",
        "value": "page",
        "className": "min-w-0 flex-1"
      }
    ],
    "toolbar-row": [],
    "table-row": []
  }
}
```

节点统一字段：

| 字段 | 说明 |
| --- | --- |
| `id` / `key` | 稳定标识，权限、远程 option、行内编辑时建议写 |
| `name` | label、按钮名、列名 |
| `type` | 节点类型，必须使用本文列出的已支持类型；不确定时不要发明新类型 |
| `value` | 绑定路径，默认从 `data` 读写 |
| `option` | 静态数组、`option.xxx`、远程 URL |
| `mode` | `form` / `search` / `table` |
| `validate` | 表单校验 |
| `meta` | 节点扩展配置 |
| `action` | 事件动作，如 `click`、`change`、`confirm`、`submit` |

value 路径规则：

| 写法 | 读写目标 |
| --- | --- |
| `form.name` | 当前页 `data.form.name` |
| `data.form.name` | 当前页 `data.form.name` |
| `state.open` | 当前页 `state.open` |
| `parent.data.form.params` | 父页 `data.form.params` |
| `parent.state.dialog.open` | 父页 `state.dialog.open` |

常用节点类型：

```txt
show-title, show-base, show-rich, show-text, show-date, show-link,
show-button, show-button-group, show-tag, show-select, show-status,
show-table, show-page, show-stat-card, show-chart, show-category-list,
show-resource, show-resource-browser, show-stream-request, show-agent,
show-icon, show-tooltip

form-input, form-password, form-textarea, form-number, form-switch,
form-radio, form-checkbox, form-select, form-tree, form-cascader,
form-date, form-array, form-combo-mapping, form-upload, form-editor,
type-editor

media-image, media-audio, media-video, media-file-list

feedback-modal, feedback-drawer, feedback-confirm, feedback-alert

nav-tab
```

### 4.4 data

`data` 是页面业务数据。

常见结构：

```json
{
  "data": {
    "page": {
      "title": "用户列表",
      "description": "维护用户资料。"
    },
    "search": {
      "keyword": "",
      "status": ""
    },
    "table": {
      "page": 1,
      "pageSize": 10,
      "total": 0,
      "searchFields": ["name"],
      "filterFields": ["status"],
      "order": "id desc"
    },
    "form": {},
    "option": {},
    "actionTarget": {}
  }
}
```

列表自动加载条件：

- 页面 path 以 `/list` 结尾。
- `data.table` 有 `page`、`pageSize`、`total`。
- `data.table.list` 缺失或为 `null`。

表单自动加载条件：

- 页面 path 以 `/update`、`/create`、`/view`、`/detail`、`/info` 结尾。
- 存在 `data.form`。
- query 或 `form.id` 有有效 ID 时自动加载记录。

显式模型：

```json
{
  "data": {
    "table": {
      "list": "<<bot.energon.NewProviderModel>>",
      "page": 1,
      "pageSize": 10,
      "total": 0
    },
    "form": {
      "_model": "user.NewConfigModel"
    },
    "stat": "{{user.StatService.LoadUserStat}}"
  }
}
```

占位符：

- `<<ModelName>>`：解析 model，常用于列表显式指定模型。
- `{{ServiceName}}`：调用 service provider，常用于统计、远程 option、复杂初始化数据。

表单元字段：

| 字段 | 说明 |
| --- | --- |
| `_model` / `_use` | 指定 form 自动加载 model |
| `_fields` | 指定编辑时只读取/保存哪些字段；没写时会根据 form 节点自动收集 |
| `_default` / `_defaults` | 新建时默认值 |

### 4.5 state

`state` 存运行时状态：

```json
{
  "state": {
    "dialog": {
      "open": false
    },
    "confirm": {
      "delete": false
    },
    "currentTab": "basic"
  }
}
```

规则：

- 弹窗、抽屉、确认框开关放 `state`。
- 当前 tab、当前选择、临时表单副本放 `state`。
- 业务提交数据放 `data.form`，不要混进 `state`。

### 4.6 action

page JSON 可使用的 action 类型：

```txt
state, data, request, page, modal, save, delete, export, import, increment, array
```

`/front/route/action` 后端只直接处理：

```txt
save, delete
```

其他类型由已打包的页面运行时或内置 API 处理。

常用写法：

```json
{
  "action": {
    "submit": {
      "type": "save",
      "params": "form"
    },
    "delete-row": {
      "type": "delete",
      "params": "actionTarget.deleteRow"
    }
  }
}
```

保存前后 hook：

```json
{
  "action": {
    "submit": {
      "type": "save",
      "params": "form",
      "before": {
        "type": "service",
        "use": "bot.energon.ServiceHook.BeforeSaveService"
      },
      "after": {
        "type": "service",
        "use": "user.UserUpdateHook.AfterSaveUser"
      }
    }
  }
}
```

Provider 签名：

```go
func (ServiceHook) ProviderBeforeSaveService(c *server.Context, params []any) any {
    record, _ := params[0].(map[string]any)
    return record
}
```

规则：

- 保存 action 标准名优先叫 `submit`。
- 简单本地交互用 `state` / `data` / `modal`。
- 跨表规则、字段规范化、复杂校验放 service hook。
- `array` 只改本地数组，不会自动提交后台；最终仍由父表单 `save` 统一保存。
- `delete`、`import`、`export` 会生成普通权限，按钮要有稳定 `key` / `importKey` / `exportKey`。

## 5. 标准列表页模板

适合 `module/user/page/list.json`、`package/front/page/account/list.json`、`package/bot/page/energon/provider/list.json` 这类资源列表。

```json
{
  "page": {
    "name": "资源管理",
    "icon": "list",
    "parent": "tongyong",
    "type": 1,
    "sort": 1
  },
  "layout": {
    "type": "container",
    "children": {
      "page-header": {
        "type": "header",
        "className": "gap-4",
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
          },
          "feedback-shell": {
            "type": "container"
          }
        }
      }
    }
  },
  "nodes": {
    "page-header": [
      {
        "type": "show-title",
        "value": "page",
        "className": "min-w-0 flex-1"
      }
    ],
    "header-actions": [
      {
        "type": "show-button",
        "name": "新增",
        "className": "shrink-0",
        "meta": {
          "variant": "default",
          "size": "sm"
        },
        "action": {
          "click": {
            "type": "modal",
            "key": "dialog.create",
            "value": true
          }
        }
      }
    ],
    "toolbar-row": [
      {
        "type": "form-input",
        "placeholder": "筛选名称...",
        "value": "search.keyword",
        "mode": "search"
      },
      {
        "type": "form-select",
        "placeholder": "状态",
        "value": "search.status",
        "mode": "search"
      },
      {
        "type": "show-button",
        "name": "搜索",
        "meta": {
          "variant": "default",
          "size": "sm",
          "searchSubmit": true,
          "loadingText": "搜索中..."
        }
      },
      {
        "type": "show-button",
        "name": "重置",
        "meta": {
          "variant": "outline",
          "size": "sm",
          "to": "/<module>/<resource>/list"
        }
      }
    ],
    "table-row": [
      {
        "id": "resource-table",
        "type": "show-table",
        "value": "table.list",
        "meta": {
          "pagePath": "data.table.page",
          "pageSizePath": "data.table.pageSize",
          "totalPath": "data.table.total",
          "remote": true,
          "externalPagination": true,
          "rowKey": "id",
          "columns": [
            {
              "name": "ID",
              "value": "id",
              "type": "show-base"
            },
            {
              "value": "name",
              "type": "show-base"
            },
            {
              "value": "status",
              "type": "show-tag"
            },
            {
              "name": "操作",
              "type": "show-button",
              "className": "w-[1%] whitespace-nowrap px-3 text-center",
              "meta": {
                "buttons": [
                  {
                    "icon": "square-pen",
                    "variant": "outline",
                    "size": "sm",
                    "description": "编辑",
                    "action": {
                      "click": [
                        {
                          "type": "data",
                          "key": "actionTarget.editId",
                          "value": "$row.id"
                        },
                        {
                          "type": "modal",
                          "key": "dialog.edit",
                          "value": true
                        }
                      ]
                    }
                  },
                  {
                    "icon": "trash-2",
                    "variant": "outline",
                    "size": "sm",
                    "description": "删除",
                    "className": "text-destructive hover:text-destructive",
                    "action": {
                      "click": [
                        {
                          "type": "data",
                          "key": "actionTarget.deleteRow",
                          "value": "$row"
                        },
                        {
                          "type": "modal",
                          "key": "confirm.delete",
                          "value": true
                        }
                      ]
                    }
                  }
                ]
              }
            }
          ]
        }
      },
      {
        "type": "show-page"
      }
    ],
    "feedback-shell": [
      {
        "type": "feedback-modal",
        "meta": {
          "stateKey": "dialog.create",
          "pageRoute": "/<module>/<resource>/update",
          "footer": {
            "confirm": true,
            "confirmText": "保存"
          }
        }
      },
      {
        "type": "feedback-modal",
        "meta": {
          "stateKey": "dialog.edit",
          "pageRoute": "/<module>/<resource>/update",
          "pageRouteQuery": {
            "id": "data.actionTarget.editId"
          },
          "footer": {
            "confirm": true,
            "confirmText": "保存"
          }
        }
      },
      {
        "type": "feedback-confirm",
        "name": "删除",
        "info": "确认删除当前记录吗？",
        "meta": {
          "stateKey": "confirm.delete"
        },
        "action": {
          "confirm": "delete-row"
        }
      }
    ]
  },
  "data": {
    "page": {
      "title": "资源管理",
      "description": "维护资源数据。"
    },
    "search": {
      "keyword": "",
      "status": ""
    },
    "table": {
      "page": 1,
      "pageSize": 10,
      "total": 0,
      "searchFields": ["name"],
      "filterFields": ["status"]
    },
    "actionTarget": {
      "editId": "",
      "deleteRow": {}
    }
  },
  "state": {
    "dialog": {
      "create": false,
      "edit": false
    },
    "confirm": {
      "delete": false
    }
  },
  "action": {
    "delete-row": {
      "type": "delete",
      "params": "actionTarget.deleteRow"
    }
  }
}
```

替换项：

- `<module>/<resource>` 改成真实 path，例如 `user`、`front/account`、`bot/energon/provider`。
- `parent` 改成真实父菜单 key。
- 表格列按 model 字段调整。
- 如果字段 option 能从 model 推导，不必手写 `option`。

## 6. 标准编辑页模板

适合弹窗、抽屉或独立表单页。

```json
{
  "page": {
    "name": "资源编辑",
    "parent": "<module>/<resource>/list",
    "sort": 10,
    "auth": [
      {
        "key": "<module>/<resource>/create",
        "name": "资源新增",
        "query": {
          "id": "empty"
        }
      },
      {
        "key": "<module>/<resource>/update",
        "name": "资源编辑",
        "query": {
          "id": "required"
        }
      }
    ]
  },
  "layout": {
    "type": "container",
    "children": {
      "page-main": {
        "type": "main",
        "className": "p-0",
        "children": {
          "dialog-shell": {
            "type": "container",
            "className": "w-full"
          }
        }
      }
    }
  },
  "nodes": {
    "dialog-shell": [
      {
        "type": "form-input",
        "value": "form.name",
        "mode": "form",
        "placeholder": "请输入名称",
        "validate": [
          {
            "type": "required",
            "message": "名称不能为空。"
          },
          {
            "type": "model",
            "except": "$form.id",
            "message": "名称已存在。"
          }
        ],
        "meta": {
          "formLayout": "horizontal"
        }
      },
      {
        "type": "form-switch",
        "value": "form.status",
        "mode": "form",
        "meta": {
          "formLayout": "horizontal",
          "trueValue": 1,
          "falseValue": 0
        }
      }
    ]
  },
  "data": {
    "form": {
      "id": "",
      "name": "",
      "status": 1
    }
  },
  "state": {},
  "action": {
    "submit": {
      "type": "save",
      "params": "form"
    }
  }
}
```

规则：

- 字段绑定 `form.*`。
- `mode: "form"` 由运行时统一渲染 label、错误和说明。
- `form.id` 留空表示新增；query 传 `id` 时自动加载记录。
- 保存前需要改 payload 时用 `action.submit.data`。
- 保存前需要复杂规范化或校验时用 `action.submit.before`。

## 7. 表单节点常用写法

### 7.1 下拉、单选、多选

```json
{
  "type": "form-select",
  "value": "form.role_ids",
  "mode": "form",
  "option": "option.role",
  "validate": [
    {
      "type": "required",
      "message": "角色不能为空。"
    }
  ],
  "meta": {
    "multiple": true,
    "controlClassName": "max-w-[320px]"
  }
}
```

option 来源：

```json
{
  "option": [
    { "id": 1, "value": "启用" },
    { "id": 0, "value": "停用" }
  ]
}
```

```json
{
  "option": "option.status"
}
```

```json
{
  "option": "/front/route/option?type=model&use=user.NewSourceModel"
}
```

远程 option 需要带当前表单值时，用 `meta.optionParams`，值写路径即可：

```json
{
  "type": "form-select",
  "value": "form.option_id",
  "option": "/front/route/option?type=model&use=demo.NewOptionModel&parentField=param_id",
  "meta": {
    "optionParams": {
      "parentId": "form.param_id"
    }
  }
}
```

字段联动优先用通用能力，不要写业务专用组件：

```json
{
  "id": "role",
  "type": "form-select",
  "value": "form.role",
  "option": "option.role",
  "meta": {
    "control": [
      {
        "value": "Manager",
        "hide": ["source"]
      }
    ],
    "clearOnChange": ["form.source_id"]
  }
}
```

- `meta.control`: 当前字段等于某值时隐藏其他节点，`hide` 填目标节点 id。
- `meta.hiddenWhen` / `meta.showWhen`: 目标节点自己声明显示或隐藏条件，适合复杂条件。
- `meta.hiddenCondition` / `meta.showCondition`: 条件组合方式，默认 `all`，需要任一条件命中时填 `any`。
- `meta.optionFilter`: 根据其他字段过滤当前 option，`form-select`、`form-radio`、`form-checkbox` 等都应走这套通用 option。
- `meta.clearOnChange`: 当前字段值变化后清空其他路径；常用于切换类型、规则、分类后清理下游字段。

`optionFilter` 示例：

```json
{
  "type": "form-select",
  "value": "form.param_id",
  "option": "/front/route/option?type=model&use=demo.NewParamModel&extraFields=type",
  "meta": {
    "optionFilter": [
      {
        "field": "type",
        "path": "form.rule",
        "map": {
          "option": ["select", "checkbox"],
          "file": ["upload"]
        }
      }
    ]
  }
}
```

需要“分类 + 项目”的二级选择时，用已有 `form-cascader`，不要写业务专用组件：

```json
{
  "type": "form-cascader",
  "value": "form.param_id",
  "mode": "form",
  "placeholder": "请选择参数",
  "meta": {
    "api": "/front/route/option",
    "use": "demo.NewParamCateModel",
    "childUse": "demo.NewParamModel",
    "childParentField": "cate_id",
    "valueMode": "leaf",
    "placeholder": ["选择分类", "选择参数"],
    "childExtraFields": "type,key",
    "optionFilter": [
      {
        "field": "type",
        "path": "form.rule",
        "map": {
          "option": ["select", "checkbox"]
        }
      }
    ]
  }
}
```

`form-cascader` 二级模型选择规则：

- `use`: 第一级模型。
- `childUse`: 第二级模型。
- `childParentField`: 子模型关联父模型的字段。
- `valueMode: "leaf"`: 表单只保存最后一级 id；不填时保存完整路径数组，适合地区这类层级值。
- `optionFilter`: 过滤第二级选项，规则和 `form-select` 一样。
- 不要把业务规则、字段拼装、保存结构写进组件；复杂保存放 service hook。

需要“多个参数选项组合 -> 一个字段值”的动态列映射时，可以用 `form-combo-mapping`。它只负责表格编辑和输出标准 JSON，不负责业务校验：

```json
{
  "type": "form-combo-mapping",
  "name": "字段值",
  "value": "form.mapping",
  "mode": "form",
  "meta": {
    "mainParamPath": "form.param_id",
    "extraParamsPath": "form.combo_params",
    "optionSource": "/front/route/option?type=model&use=demo.NewParamOptionModel&parentField=param_id&valueField=id&labelField=name",
    "paramSource": "/front/route/option?type=model&use=demo.NewParamModel&valueField=id&labelField=name",
    "addText": "添加字段值",
    "addAllText": "添加全部字段值",
    "clearText": "清空"
  }
}
```

输出格式：

```json
{
  "params": [1, 2],
  "rows": [
    {
      "values": {
        "1": 10,
        "2": 20
      },
      "native_value": "2048x2048"
    }
  ]
}
```

规则：

- `mainParamPath`: 主参数 id 路径。
- `extraParamsPath`: 额外参与参数数组路径，支持 `[{ "param_id": 2 }]` 或 `[2]`。
- `optionSource`: 按 `parentId` 拉取参数选项。
- `paramSource`: 用 `selected` 拉取参数名称，用于表头展示。
- 动态列这种场景不要硬塞进 `form-array`，避免把通用数组组件做复杂。

### 7.1.1 类型编辑器

需要“左侧选择类型，右侧维护该类型的一组字段”时用 `type-editor`，不要为每个类型复制一套表单页：

```json
{
  "id": "setting-type-editor",
  "type": "type-editor",
  "value": "state.selected_type",
  "option": "option.setting_type",
  "meta": {
    "typeField": "type",
    "primaryKey": "id",
    "loadApi": "/front/route/option?type=service&use=<module>.OptionService.LoadSettings",
    "loadParams": {
      "parentId": "state.route.query.id"
    },
    "savePath": "<module>/<resource>/update",
    "saveBefore": {
      "type": "service",
      "use": "<module>.Hook.BeforeSaveSetting"
    },
    "context": {
      "parent_id": "state.route.query.id"
    },
    "defaultRecord": {
      "status": 1
    },
    "fields": [
      {
        "type": "form-textarea",
        "name": "内容",
        "value": "content",
        "validate": [{ "type": "required" }]
      }
    ]
  }
}
```

规则：

- `option` / `meta.typeOptions` 提供类型列表。
- `loadApi` 返回已有记录列表，组件按 `typeField` 找当前类型记录。
- `context` 会合并进保存 payload；适合放父 id、租户 id 等固定上下文。
- `fields` 只支持 `form-input`、`form-radio`、`form-select`、`form-textarea` 这类内置编辑字段。
- 复杂校验和保存前规范化放 `saveBefore` 对应的 service hook。

### 7.2 上传

```json
{
  "type": "form-upload",
  "name": "头像",
  "value": "form.avatar_id",
  "mode": "form",
  "meta": {
    "uploadType": "pic",
    "kind": "image",
    "ruleId": 1,
    "bizKey": "user.avatar",
    "bizName": "用户头像"
  }
}
```

常用 meta：

- `uploadType`: `pic` / `file`
- `kind`: `image` / `video` / `audio` / `file`
- `saveMode`: `id` / `url`
- `maxCount`: 最大文件数
- `ruleId`: 上传规则 ID
- `bizKey` / `bizName`: 资源归属说明

### 7.3 富文本

```json
{
  "type": "form-editor",
  "value": "form.content",
  "mode": "form",
  "meta": {
    "minHeight": 260,
    "uploadRules": [
      {
        "ruleId": 1,
        "kind": "image",
        "bizKey": "article.content.image",
        "bizName": "正文图片"
      }
    ]
  }
}
```

### 7.4 数组子表单

字段少、可行内录入时用 `form-array`：

```json
{
  "type": "form-array",
  "value": "form.items",
  "mode": "form",
  "meta": {
    "pageRoute": "/<module>/<resource>/item/update",
    "addText": "添加条目",
    "drag": "sort"
  }
}
```

子项模板页只写字段：

```json
{
  "layout": {
    "type": "container",
    "children": {
      "dialog-shell": {
        "type": "container"
      }
    }
  },
  "nodes": {
    "dialog-shell": [
      {
        "type": "form-input",
        "value": "form.name",
        "mode": "form"
      }
    ]
  },
  "data": {
    "form": {
      "name": "",
      "sort": 100
    }
  },
  "action": {
    "submit": {
      "type": "save",
      "params": "form"
    }
  }
}
```

需要“添加全部/清空”时仍用 `form-array`，不要写专用组件。`fillFromOption` 会按 option 批量生成行：

```json
{
  "type": "form-array",
  "value": "form.mappings",
  "mode": "form",
  "meta": {
    "pageRoute": "/demo/mapping/update",
    "addText": "添加字段值",
    "addAllText": "添加全部字段值",
    "clearText": "清空",
    "valueFormat": "json",
    "fillFromOption": {
      "source": "/front/route/option?type=model&use=demo.NewOptionModel&parentField=param_id",
      "targetField": "option_id",
      "params": {
        "parentId": "form.param_id"
      },
      "defaultRow": {
        "native_value": ""
      }
    }
  }
}
```

规则：

- 普通“添加”会生成一行模板；配置 `fillFromOption` 后会优先添加第一个未使用 option。
- `addAllText` 显示“添加全部”按钮，把未使用 option 全部生成行。
- `clearText` 显示“清空”按钮。
- `valueFormat: "json"` 表示保存为 JSON 字符串；不填则保存数组。
- 复杂保存、跨字段拼装、强校验放 service hook，不要塞到前端节点组件里。

字段多、需要列表式维护时，不要继续堆 `form-array`，改用“父 update 嵌入子 list”的模式，见第 10 节。

## 8. 表格列常用写法

### 8.1 普通列

```json
{
  "value": "name",
  "type": "show-base"
}
```

`name` 可省略，运行时会根据 model comment 自动补。

### 8.2 枚举列

```json
{
  "value": "status",
  "type": "show-tag"
}
```

规则：

- 如果 model `Options` 有 `status`，会自动补 `option.status`。
- `show-base`、`show-tag`、`show-select`、`show-status` 都应显示 option 文案。
- 如果字段名不能自动匹配 option，用：

```json
{
  "value": "enabled",
  "type": "show-tag",
  "meta": {
    "option": "option.status"
  }
}
```

禁止没有任何 option 映射就展示状态、分类、类型、策略字段；否则会显示 `1`、`0`、`image`、`round_robin` 等内部值。

### 8.3 关联对象列

```json
{
  "value": "roles",
  "type": "show-tag",
  "meta": {
    "field": "name"
  }
}
```

### 8.4 行内编辑

```json
{
  "value": "sort",
  "type": "show-base",
  "editor": "form-number",
  "trigger": "doubleClick",
  "meta": {
    "controlClassName": "w-24"
  }
}
```

远程表格中建议在 `show-table.meta` 写：

```json
{
  "savePath": "<module>/<resource>/update"
}
```

本地数组表格中用 `array` action：

```json
{
  "name": "启用",
  "value": "status",
  "type": "form-switch",
  "action": {
    "change": {
      "type": "array",
      "key": "parent.data.form.params",
      "op": "patch",
      "index": "$rowIndex",
      "value": {
        "status": "$value"
      }
    }
  },
  "meta": {
    "trueValue": 1,
    "falseValue": 2
  }
}
```

### 8.5 操作列

```json
{
  "name": "操作",
  "type": "show-button",
  "className": "w-[1%] whitespace-nowrap px-3 text-center",
  "meta": {
    "buttons": [
      {
        "icon": "square-pen",
        "variant": "outline",
        "size": "sm",
        "description": "编辑",
        "action": {
          "click": [
            {
              "type": "data",
              "key": "actionTarget.editId",
              "value": "$row.id"
            },
            {
              "type": "modal",
              "key": "dialog.edit",
              "value": true
            }
          ]
        }
      }
    ]
  }
}
```

## 9. 搜索、分页、过滤

搜索区字段绑定 `search.*`。

```json
{
  "data": {
    "search": {
      "keyword": "",
      "status": "",
      "created_at_start": "",
      "created_at_end": ""
    },
    "table": {
      "page": 1,
      "pageSize": 10,
      "total": 0,
      "searchFields": ["name", "key"],
      "filterFields": [
        "status",
        {
          "field": "created_at",
          "type": "date-range",
          "startKey": "created_at_start",
          "endKey": "created_at_end",
          "valueType": "datetime"
        }
      ],
      "order": "id desc"
    }
  }
}
```

规则：

- `searchFields` 是关键词搜索字段。
- `filterFields` 是精确过滤或特殊过滤。
- 关系字段过滤优先依赖 model Relation。
- 搜索按钮优先用 `show-button.meta.searchSubmit: true`，不用手写 request action。
- 重置按钮用 `meta.to` 指向当前列表 path。

## 10. 父表单嵌入子列表

适合 `package/bot` 的来源服务编辑：父表单保存 `form.endpoints`、`form.params`，子页面只维护父表单数组。

父 `update.json`：

```json
{
  "layout": {
    "type": "container",
    "children": {
      "page-main": {
        "type": "main",
        "className": "p-0",
        "children": {
          "dialog-shell": {
            "type": "container",
            "children": {
              "child-list-page": {
                "type": "container",
                "path": "/<module>/<child>/list",
                "className": "mt-5"
              }
            }
          }
        }
      }
    }
  },
  "data": {
    "form": {
      "_fields": ["name", "children"],
      "name": "",
      "children": []
    }
  },
  "action": {
    "submit": {
      "type": "save",
      "params": "form",
      "before": {
        "type": "service",
        "use": "<module>.Hook.BeforeSave"
      }
    }
  }
}
```

子 `list.json`：

```json
{
  "page": {
    "parent": "<module>/<parent>/list",
    "type": 2,
    "sort": 11
  },
  "layout": {
    "type": "container",
    "className": "rounded-md border bg-background",
    "children": {
      "page-header": {
        "type": "header",
        "className": "gap-4 border-b px-4 py-3",
        "children": {
          "header-actions": {
            "type": "row",
            "className": "ms-auto shrink-0 flex-nowrap items-center gap-2"
          }
        }
      },
      "table-row": {
        "type": "container",
        "className": "overflow-hidden"
      }
    }
  },
  "nodes": {
    "header-actions": [
      {
        "type": "show-button",
        "name": "添加",
        "meta": {
          "variant": "outline",
          "size": "sm"
        },
        "action": {
          "click": [
            {
              "type": "state",
              "key": "rowIndex",
              "value": -1
            },
            {
              "type": "state",
              "key": "rowForm",
              "value": {}
            },
            {
              "type": "modal",
              "key": "dialog.row",
              "value": true
            }
          ]
        }
      }
    ],
    "table-row": [
      {
        "type": "show-table",
        "value": "parent.data.form.children",
        "meta": {
          "rowKey": "id",
          "columns": [
            {
              "value": "name",
              "type": "show-base"
            },
            {
              "name": "操作",
              "type": "show-button",
              "meta": {
                "buttons": [
                  {
                    "icon": "square-pen",
                    "variant": "outline",
                    "size": "sm",
                    "action": {
                      "click": [
                        {
                          "type": "state",
                          "key": "rowIndex",
                          "value": "$rowIndex"
                        },
                        {
                          "type": "state",
                          "key": "rowForm",
                          "value": "$row"
                        },
                        {
                          "type": "modal",
                          "key": "dialog.row",
                          "value": true
                        }
                      ]
                    }
                  }
                ]
              }
            }
          ]
        }
      },
      {
        "type": "feedback-modal",
        "meta": {
          "stateKey": "dialog.row",
          "pageRoute": "/<module>/<child>/update",
          "footer": {
            "confirm": true,
            "confirmText": "确定"
          },
          "pageDataPatches": {
            "form": "state.rowForm"
          }
        },
        "action": {
          "submit": {
            "type": "array",
            "key": "parent.data.form.children",
            "op": "upsert",
            "index": "state.rowIndex",
            "value": "$modalForm"
          }
        }
      }
    ]
  },
  "data": {},
  "state": {
    "rowIndex": -1,
    "rowForm": {},
    "dialog": {
      "row": false
    }
  },
  "action": {}
}
```

规则：

- 子 list 使用 `parent.data.form.<field>` 读写父表单数组。
- 子弹窗确认用 `array` action，不直接 `save`。
- 父 `submit` 统一保存整个 form。
- 父 hook 负责规范化 children，处理重复、默认值和自然键复用。

## 11. 两栏分类 + 列表

适合参数、分类、字典等页面。

核心布局：

```json
{
  "layout": {
    "type": "container",
    "children": {
      "page-main": {
        "type": "main",
        "className": "flex flex-1 flex-col gap-5 sm:gap-6",
        "children": {
          "content-shell": {
            "type": "container",
            "className": "front-two-pane-layout",
            "children": {
              "category-column": {
                "type": "container",
                "className": "min-w-0",
                "path": "/<module>/<cate>/list",
                "meta": {
                  "updateDocumentTitle": false
                }
              },
              "list-column": {
                "type": "container",
                "className": "flex min-w-0 flex-col gap-4",
                "children": {
                  "content-toolbar": {
                    "type": "row",
                    "className": "flex-wrap items-center gap-3"
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
      }
    }
  }
}
```

分类页通常用 `show-category-list`，点击后写入父页搜索条件：

```json
{
  "type": "show-category-list",
  "value": "table.list",
  "meta": {
    "target": "parent.data.search.cate_id",
    "defaultFirst": true
  }
}
```

列表页 `data.search` 保留分类字段：

```json
{
  "data": {
    "search": {
      "cate_id": "",
      "keyword": ""
    },
    "table": {
      "page": 1,
      "pageSize": 10,
      "total": 0,
      "filterFields": ["cate_id"],
      "searchFields": ["name", "key"]
    }
  }
}
```

新增弹窗可通过 query 带入当前分类：

```json
{
  "type": "feedback-modal",
  "meta": {
    "stateKey": "dialog.create",
    "pageRoute": "/<module>/<resource>/update",
    "pageRouteQuery": {
      "cate_id": "data.search.cate_id"
    },
    "footer": {
      "confirm": true,
      "confirmText": "保存"
    }
  }
}
```

## 12. 固定配置页 / 单条 upsert

适合系统配置、站点配置、模块单例配置。

```json
{
  "page": {
    "name": "配置管理",
    "icon": "settings",
    "parent": "tongyong",
    "type": 1,
    "sort": 5
  },
  "layout": {
    "type": "container",
    "children": {
      "page-header": {
        "type": "header",
        "className": "gap-4",
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
          "form-card": {
            "type": "container",
            "className": "rounded-md border bg-background p-6"
          }
        }
      }
    }
  },
  "nodes": {
    "page-header": [
      {
        "type": "show-title",
        "value": "page",
        "className": "min-w-0 flex-1"
      }
    ],
    "header-actions": [
      {
        "type": "show-button",
        "name": "保存配置",
        "meta": {
          "variant": "default",
          "size": "sm",
          "loadingText": "保存中...",
          "successMessage": "配置已保存"
        },
        "action": {
          "click": "submit"
        }
      }
    ],
    "form-card": [
      {
        "type": "form-input",
        "value": "form.name",
        "mode": "form",
        "validate": [
          {
            "type": "required",
            "message": "名称不能为空。"
          }
        ]
      }
    ]
  },
  "data": {
    "page": {
      "title": "配置管理",
      "description": "固定保存 ID=1 的配置记录。"
    },
    "form": {
      "id": 1,
      "_model": "<module>.NewConfigModel",
      "name": ""
    }
  },
  "state": {},
  "action": {
    "submit": {
      "type": "save",
      "use": "<module>.NewConfigModel",
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

规则：

- `data.form.id` 写固定 ID。
- `data.form._model` 保证页面加载时按该 model 读取记录。
- `action.submit.use` 保证保存时按该 model 写入。
- `upsert: true` 表示不存在就新增，存在就更新。

## 13. 导入导出

导入：

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

导出：

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
      "key": "export-user-list",
      "name": "导出列表",
      "action": {
        "click": {
          "type": "export"
        }
      }
    },
    {
      "key": "export-user-workbook",
      "name": "导出工作簿",
      "action": {
        "click": {
          "type": "export",
          "use": "user.ExportService.PrepareUserWorkbook"
        }
      }
    }
  ]
}
```

规则：

- `key` 要稳定，用于权限生成。
- 普通导出不需要 service。
- 多 sheet、复杂数据、特殊样式才用 `use` 指向 service。
- 导入字段别名、缺失策略、提示写在 page JSON；复杂校验写 service。

### 13.1 流式测试与智能体面板

能力测试用 `show-stream-request`，它负责参数加载、请求发起、流式读取和停止：

```json
{
  "id": "power-stream-test",
  "type": "show-stream-request",
  "meta": {
    "powerPath": "data.actionTarget.testPower.key",
    "paramApi": "/bot/energon/power_params",
    "requestApi": "/bot/energon/request",
    "streamApi": "/bot/energon/stream",
    "stopApi": "/bot/energon/stream_stop",
    "blockMs": 1000,
    "uploadRules": [
      { "ruleId": 1, "kind": "image", "bizKey": "energon", "bizName": "AI生成" }
    ]
  }
}
```

智能体临时对话/执行面板用 `show-agent`，通常放在弹窗或抽屉内部：

```json
{
  "id": "agent-stream",
  "type": "show-agent",
  "meta": {
    "agentPath": "data.actionTarget.testAgent.key",
    "agentNamePath": "data.actionTarget.testAgent.name",
    "openPath": "state.dialog.test",
    "requestApi": "/bot/agent/run",
    "streamApi": "/bot/agent/stream",
    "stopApi": "/bot/agent/stop",
    "paramApi": "/bot/energon/power_params",
    "blockMs": 1000
  }
}
```

规则：

- 这两个节点复用已有 bot/energon/agent 流式运行时；不要为测试面板新写前端组件。
- `powerPath` / `agentPath` 必须能读到当前行或当前上下文的 key。
- 如果业务不是 bot/energon/agent，但需要同类流式能力，先补后端 service/api 协议，再复用这些节点的 `requestApi` / `streamApi` / `stopApi`。

## 14. 弹窗、抽屉、确认框

弹窗：

```json
{
  "type": "feedback-modal",
  "meta": {
    "stateKey": "dialog.edit",
    "pageRoute": "/user/update",
    "pageRouteQuery": {
      "id": "data.actionTarget.editId"
    },
    "title": "编辑用户",
    "description": "更新用户信息。",
    "size": "lg",
    "footer": {
      "confirm": true,
      "confirmText": "保存"
    }
  }
}
```

抽屉：

```json
{
  "type": "feedback-drawer",
  "meta": {
    "stateKey": "drawer.open",
    "pageRoute": "/user/update",
    "side": "right",
    "title": "新增用户",
    "footer": {
      "confirm": true,
      "confirmText": "保存"
    },
    "drawerClassName": "sm:max-w-xl"
  }
}
```

确认框：

```json
{
  "type": "feedback-confirm",
  "name": "删除用户",
  "info": "确认删除当前用户吗？",
  "meta": {
    "stateKey": "confirm.delete"
  },
  "action": {
    "confirm": {
      "type": "delete",
      "params": "actionTarget.deleteUser"
    }
  }
}
```

## 15. package/front、package/bot、module/user 的写法差异

### 15.1 `backend/package/front/page`

用于 front 内置后台能力。

规则：

- path 前缀是 `front/...`。
- model 注册名通常是 `front.NewAccountModel`、`front.NewRoleModel`。
- 可见菜单通常挂 `system-settings`。
- 这类页面应保持通用，不写项目业务逻辑。
- 修改 package/front 页面时要避免依赖 `module/user` 或 `package/bot`。

示例：

```json
{
  "page": {
    "name": "账户管理",
    "icon": "users-round",
    "parent": "system-settings",
    "sort": 1
  }
}
```

### 15.2 `backend/package/bot/page`

用于 bot package 自带后台。

规则：

- path 前缀是 `bot/...`。
- 多级目录会参与 model 推导，例如 `bot/energon/provider/list` 可命中 `bot.energon.NewProviderModel`。
- 可见页挂 package 菜单分组，例如 `bot-energon`。
- 隐藏子页挂入口列表，例如 `bot/energon/service/list` 挂 `bot/energon/provider/list`。
- hook/service 名使用 package namespace，例如 `bot.energon.ServiceHook.BeforeSaveService`。
- 父表单嵌入子列表时，子页用 `parent.data.form.*`，最终由父页 `submit` 保存。

示例：

```json
{
  "page": {
    "parent": "bot/energon/provider/list",
    "type": 2,
    "sort": 10
  }
}
```

### 15.3 `backend/module/user/page`

用于当前项目业务模块。

规则：

- path 前缀是 `user/...`。
- 主资源 `user/list` 命中 `user.NewUserModel`。
- 子资源 `user/source/list` 命中 `user.NewSourceModel`，也会尝试 `user.NewUserSourceModel`。
- 业务页面可以引用业务 service，例如 `user.UserListService.BuildDemoTable`。
- demo 或项目专属复杂交互可以放在 module 页面里，不要上升到 package/front。

示例：

```json
{
  "data": {
    "table": {
      "service": "user.UserListService.BuildDemoTable",
      "page": 1,
      "pageSize": 10,
      "total": 0
    }
  }
}
```

## 16. 何时写 service / api

优先只写 model + page JSON。

需要 service/provider 的情况：

- 保存前规范化复杂 children 数据。
- 跨表校验或字段级错误。
- 统计聚合数据。
- 导入导出特殊处理。
- 列表查询后追加派生字段。
- 动态 option 需要复杂上下文。

不需要 service 的情况：

- 普通列表查询。
- 普通新增/编辑/删除。
- 普通静态枚举。
- 普通单表关联。
- 普通弹窗/抽屉/确认框。

需要 api 的情况：

- 内置 `save/delete/import/export/option/upload` 不能表达的 HTTP 能力。
- 网关、流式、文件下载、第三方回调等非后台 CRUD。

## 17. AI 生成页面的步骤

每次写一个 page JSON，按顺序执行：

1. 确认页面归属：`module` / `package` / `package/front`。
2. 确认 page path 和文件位置。
3. 确认默认 model 是否能命中；不能命中就写 `_model` / `use` / `<<Model>>`。
4. 判断页面类型：
   - visible list
   - update form
   - detail/view
   - embedded child list
   - category two-pane
   - config upsert
   - stat page
5. 从本文选择对应模板。
6. 填 `page`：name/icon/parent/type/sort/auth。
7. 填 `layout`：先用标准结构，必要时加 `path` 嵌入子页。
8. 填 `nodes`：字段按 model comment/Options/Relations 推导，少写冗余。
9. 填 `data`：search/table/form/state/actionTarget。
10. 填 `state`：只放运行时状态。
11. 填 `action`：复用命名 action，保存用 `submit`。
12. 自查 JSON 格式、路径、权限、option、保存模型、parent 访问。

## 18. 自查清单

交付前逐项检查：

- 文件位置是否和页面归属一致？
- path 是否至少两段，且与文件位置一致？
- `page.parent` 是否指向正确父菜单或入口列表？
- 隐藏页是否显式 `type: 2`？
- model 是否能按默认规则命中？
- 列表页 `data.table` 是否有 `page/pageSize/total`？
- 表单页是否有 `data.form`？
- 表单字段是否绑定 `form.*`？
- 是否避免重复写 model 已能推导的 label？
- 枚举/状态列是否有 option 映射？
- 关联对象列是否用 `meta.field` 指定展示字段？
- `show-table.value` 是否是数组路径？
- 子页是否正确使用 `parent.data.*` 或 `parent.state.*`？
- `array` action 是否只用于本地数组，最终由父表单保存？
- 删除、导入、导出按钮是否有稳定 key？
- `action.submit` 是否使用正确的 `params`、`data`、`use`、`before`？
- 是否没有发明本文未列出的节点类型？
- 是否没有发明后端不支持的 action 类型？
- 是否没有把复杂业务逻辑塞进 JSON？
- 是否没有手改生成文件：`data/router.go`、`data/load/model.go`、`data/load/service.go`？

## 19. 常见错误

### 错误：package 页面放到 module

错误：

```txt
backend/module/bot/page/energon/provider/list.json
```

正确：

```txt
backend/package/bot/page/energon/provider/list.json
```

### 错误：隐藏子页挂一级分组

错误：

```json
{
  "page": {
    "parent": "bot-energon",
    "type": 2
  }
}
```

正确：

```json
{
  "page": {
    "parent": "bot/energon/provider/list",
    "type": 2
  }
}
```

### 错误：枚举列无 option

错误：

```json
{
  "value": "status",
  "type": "show-tag"
}
```

但 model 没有 `Options["status"]`。

正确：

- 优先给 model 加 `Options["status"]`。
- 或页面补 `data.option.status`。

### 错误：子列表直接 save

嵌入父表单的子列表不要直接 `save` 子记录。它还没有独立 owner id，且会绕开父表单统一保存。

正确做法：

- 子列表用 `array` action 改 `parent.data.form.children`。
- 父表单 `submit` 统一 save。
- 父 hook 规范化 children。

### 错误：为了一个页面扩展前端运行时

如果只是某个业务的特殊字段、特殊保存、特殊展示，优先写业务 service/provider 或自定义业务页面结构。

只有多个业务都会复用的能力，才考虑扩展通用节点或运行时；单个页面不要靠新增前端能力解决。

## 20. 复杂后台 JSON 交付模式

当用户要求“通过 JSON 实现一个复杂后台”时，AI 不要一次生成所有页面。按下面方式分批交付。

### 20.1 信息架构先行

先输出菜单和页面矩阵：

```md
菜单：
- business：业务管理
  - contract/list：合同
  - customer/list：客户
- system：系统设置
  - front/account/list：账号

页面：
- contract/list：可见列表，合同搜索、表格、导出、删除
- contract/update：隐藏编辑，合同主信息、付款计划数组
- contract/view：隐藏详情，合同只读信息、回款记录子列表
- customer/list：可见列表，客户搜索、表格、编辑
```

然后逐页写 JSON。每次只写一个列表页或一个编辑页，避免复制错误扩散。

### 20.2 页面组合优先级

| 需求 | 首选 JSON 组合 | 不推荐 |
| --- | --- | --- |
| 普通资源管理 | `list.json` + `update.json` | 手写 CRUD API |
| 小表单弹窗编辑 | `list.json` 内放 `feedback-modal` + `form` | 单独加前端页面 |
| 大表单编辑 | 独立 `update.json` | 在列表页塞超大 modal |
| 父子项一起保存 | 父 `update.json` + `form-array` + before hook | 子项单独 save |
| 子资源独立生命周期 | 父详情嵌入子 `list.json` | 父表单数组硬塞全部流程 |
| 左侧分类右侧列表 | `aside` + `main` + `state.currentCate` | 写多个重复列表页 |
| 固定配置 | 单条 upsert 模板 | 为每个配置写 API |
| 统计面板 | Provider 数据 + `show-stat-card/show-chart` | JSON 里计算统计 |

### 20.3 数据路径规范

复杂页面统一使用这些路径，减少 AI 乱写：

```json
{
  "data": {
    "page": {},
    "search": {},
    "table": {},
    "form": {},
    "detail": {},
    "option": {},
    "actionTarget": {},
    "import": {},
    "export": {}
  },
  "state": {
    "dialog": {},
    "drawer": {},
    "confirm": {},
    "currentTab": "",
    "currentCate": ""
  }
}
```

规则：

- `search` 只放筛选条件。
- `table` 只放列表数据、分页、排序、过滤配置。
- `form` 是保存数据。
- `detail` 是只读详情数据；如果详情也能编辑，仍使用 `form`。
- `option` 放枚举和选项。
- `actionTarget` 放当前操作行，例如删除、复制、导出选中项。
- 弹窗开关只放 `state.dialog.*`。

### 20.4 action 命名规范

复杂页面 action 命名要稳定：

| 动作 | 推荐名称 |
| --- | --- |
| 初始化 | `init` / `load-page` |
| 搜索 | `search` |
| 重置搜索 | `reset-search` |
| 打开新增 | `open-create` |
| 打开编辑 | `open-update` |
| 打开详情 | `open-view` |
| 提交表单 | `submit` |
| 删除行 | `delete-row` |
| 确认删除 | `confirm-delete` |
| 打开导入 | `open-import` |
| 执行导出 | `export` |
| 子数组新增 | `add-child` |
| 子数组删除 | `remove-child` |

同一个项目里不要一会儿叫 `save`，一会儿叫 `submit-form`，一会儿叫 `doSubmit`。

### 20.5 什么时候停止写 JSON，改写 Service

出现以下情况，不要继续堆 JSON：

- 一个 action 需要 if/else 条件判断。
- 保存前需要把多个数组转成多张表。
- 字段值依赖数据库查询。
- 删除前要检查状态或子记录。
- 列表需要聚合统计、批量补充派生字段。
- 导入需要复杂映射、校验、错误报告。
- 第三方协议需要签名、轮询、回调。

这些放到 `module/*/service` 的业务方法或 Provider hook。

### 20.6 复杂后台交付清单

交付复杂后台时，最终回复必须列出：

```md
菜单：
- ...

页面：
- path -> 文件 -> 类型 -> model/use

模型：
- ...

Service/Provider：
- ...

JSON 能力：
- 列表/搜索/分页/表单/子表/弹窗/导入导出/统计

需要手动验证：
- 打开页面
- 新增
- 编辑
- 删除
- 筛选
- 导入/导出
```

如果没有写前端源码，要明确说明：本次只通过 page JSON 使用已打包后台运行时。

## 21. 完整覆盖索引：按 bot / front / user 现有 JSON 反向整理

本节用于回答“AI 是否可以只看本文档就写出完整后台 JSON”。结论：可以。下面把 `package/front`、`package/bot`、`module/user` 现有页面里出现过的页面结构、节点类型、动作、字段和 meta 按能力归类列出来。

注意：

- 这是能力索引，不是让 AI 复制这些页面。
- 写新后台时仍先选模板，再按本节确认字段是否已支持。
- 如果本节没有列出的节点、action、meta，不要凭空写；要么换成已有能力，要么先扩展通用运行时。

### 21.1 顶层协议字段完整表

所有 page JSON 顶层只使用下面 6 个字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `page` | object | 页面菜单、标题、权限、排序、类型 |
| `layout` | object | 页面布局树 |
| `nodes` | object | 按 layout id 挂载节点数组 |
| `data` | object | 业务数据初始值、表格、表单、选项、统计数据 |
| `state` | object | 临时 UI 状态，如弹窗、抽屉、tab、confirm |
| `action` | object | 页面动作字典 |

### 21.2 `page` 字段完整表

| 字段 | 用途 | 常见写法 |
| --- | --- | --- |
| `id` | 页面唯一标识；可省略，通常由 path 决定 | `"user-list"` |
| `name` | 菜单名、页面名 | `"用户列表"` |
| `title` | 页面标题；部分旧协议/外部页面使用 | `"用户列表"` |
| `route` | 固定路由；多数 Dever 后台页面由文件路径推导，不必写 | `"/admin/users"` |
| `icon` | 菜单图标 | `"User"` |
| `parent` | 父菜单或父页面 path | `"system"`、`"user/list"` |
| `type` | 页面类型；`1` 常见可见菜单页，`2` 常见隐藏/弹窗/子页 | `"1"` / `"2"` |
| `sort` | 菜单排序 | `100` |
| `auth` | 权限声明；不常手写，优先由按钮/action 推导 | `[]` |
| `init` | 初始化动作数组；普通 CRUD 通常不需要 | `["load-page"]` |

### 21.3 `layout` 完整能力

已注册布局类型：

```txt
container, header, footer, main, aside, row, col
```

布局节点字段：

| 字段 | 说明 |
| --- | --- |
| `type` | 布局类型 |
| `name` | 可读名称 |
| `value` | 布局参数，例如 `col` 栅格宽度 |
| `path` | 子页面路径或 `state.xxx` / `data.xxx` 路径 |
| `children` | 子布局节点 |
| `className` | 额外样式 |
| `meta` | 布局扩展配置 |

常见布局模式：

| 模式 | 写法 |
| --- | --- |
| 普通页 | `container -> header + main` |
| 搜索表格页 | `container -> header + main`，`main` 内挂搜索区、表格、分页 |
| 两栏分类页 | `container -> row -> col(aside) + col(main)` |
| tab 页 | 顶部放 `nav-tab`，节点通过 `meta.tab` 绑定 tab |
| 子页面容器 | 布局节点写 `path: "state.currentPage"` 或固定 path |

### 21.4 节点统一字段完整表

| 字段 | 说明 |
| --- | --- |
| `id` | 节点实例 id，建议稳定 |
| `key` | 权限、按钮、导入导出、操作项稳定标识 |
| `auth` | 节点权限 |
| `name` | label / 列名 / 按钮名 |
| `icon` | 图标 |
| `tip` | 短提示 |
| `placeholder` | 输入提示 |
| `info` | 说明文字 |
| `value` | 绑定路径，默认读写 `data` |
| `option` | 静态选项、data 路径、远程 URL |
| `mode` | `form` / `search` / `table` |
| `type` | 节点类型 |
| `meta` | 节点扩展配置 |
| `validate` | 校验规则 |
| `className` | 样式 |
| `action` | 事件动作 |
| `items` | 子项；常用于按钮组、tab、复杂节点配置 |

### 21.5 已支持节点类型完整表

| 类型 | 节点 | 用途 |
| --- | --- | --- |
| 展示 | `show-title` | 页面标题/区块标题 |
| 展示 | `show-base` | 普通文本、数字、字段展示 |
| 展示 | `show-rich` | 富文本展示 |
| 展示 | `show-text` | 文本块/说明 |
| 展示 | `show-date` | 日期时间格式化展示 |
| 展示 | `show-link` | 链接 |
| 展示 | `show-button` | 单按钮 |
| 展示 | `show-button-group` | 按钮组、导入导出入口、批量操作 |
| 展示 | `show-tag` | 标签、枚举标签 |
| 展示 | `show-select` | 只读枚举值转文本 |
| 展示 | `show-status` | 状态标签、状态切换展示 |
| 展示 | `show-stat-card` | 统计卡片 |
| 展示 | `show-chart` | 图表 |
| 展示 | `show-table` | 表格 |
| 展示 | `show-page` | 分页 |
| 展示 | `show-icon` | 图标展示 |
| 展示 | `show-tooltip` | tooltip 包裹说明 |
| 展示 | `show-category-list` | 左侧分类/树形分类列表 |
| 展示 | `show-resource` | 资源中心 |
| 展示 | `show-resource-browser` | 资源选择/浏览；和 `show-resource` 共用实现 |
| 展示 | `show-stream-request` | 流式测试/请求结果展示 |
| 展示 | `show-agent` | 智能体对话/执行面板 |
| 导航 | `nav-tab` | tab 切换 |
| 表单 | `form-input` | 单行输入 |
| 表单 | `form-icon` | 图标选择 |
| 表单 | `form-password` | 密码输入 |
| 表单 | `form-textarea` | 多行输入 |
| 表单 | `form-upload` | 上传 |
| 表单 | `form-editor` | 富文本编辑器 |
| 表单 | `form-number` | 数字输入 |
| 表单 | `form-switch` | 开关 |
| 表单 | `form-radio` | 单选按钮组 |
| 表单 | `form-checkbox` | 多选 |
| 表单 | `form-select` | 下拉选择 |
| 表单 | `form-tree` | 树选择，如权限树 |
| 表单 | `form-cascader` | 二级/多级选择，如分类 + 参数、地区 |
| 表单 | `form-date` | 日期/日期范围 |
| 表单 | `form-array` | 子表单数组 |
| 表单 | `form-combo-mapping` | 多参数选项组合映射成字段值 |
| 表单 | `type-editor` | 按类型切换字段组并保存单条配置 |
| 媒体 | `media-image` | 图片展示 |
| 媒体 | `media-audio` | 音频展示 |
| 媒体 | `media-video` | 视频展示 |
| 媒体 | `media-file-list` | 文件列表展示 |
| 反馈 | `feedback-modal` | 弹窗 |
| 反馈 | `feedback-alert` | 警告提示 |
| 反馈 | `feedback-confirm` | 确认框 |
| 反馈 | `feedback-drawer` | 抽屉 |

### 21.6 `action` 完整表

顶层 `action` 字典支持这些类型：

| type | 用途 | 关键字段 |
| --- | --- | --- |
| `state` | 写入 `state` | `key`、`value` |
| `data` | 写入 `data` | `key`、`value` |
| `request` | 调 HTTP 接口并回写 | `api`、`method`、`params`、`target`、`then` |
| `page` | 切换子页面 path | `target`、`value` |
| `modal` | 控制 `state.dialog.*` / `state.confirm.*` | `key`、`value` |
| `save` | 走 `/front/route/action` 保存 | `params`、`use`、`path`、`before`、`after`、`then` |
| `delete` | 走 `/front/route/action` 删除 | `params`、`key`、`path`、`then` |
| `export` | 创建导出任务 | `exportKey`、`tableId`、`source`、`scope` |
| `import` | 打开/返回导入任务配置 | `importKey`、`tableId`、`uploadRuleId` |
| `increment` | 本地数字自增，常用于刷新版本号 | `key` |
| `array` | 修改本地数组 | `key`、`op`、`index`、`value` / `params` |

`array.op` 常用值：

```txt
append, upsert, patch, update, remove, delete
```

`before` / `after` 里的 `type: "service"` 是保存 hook，不是顶层 action 类型：

```json
{
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
```

覆盖索引里可把这两类 hook 记为 `before:service`、`after:service`。

事件写法：

| 位置 | 示例 |
| --- | --- |
| 节点点击 | `"action": { "click": "open-create" }` |
| 节点 change | `"action": { "change": ["clear-child", "reload-option"] }` |
| 确认框 | `"action": { "confirm": "delete-row" }` |
| 内联 action 对象 | `"click": { "type": "modal", "key": "dialog.open", "value": true }` |

### 21.7 `data` / `state` 路径完整约定

常见 `data`：

| 路径 | 说明 |
| --- | --- |
| `data.page` | 页面标题、描述、帮助文案 |
| `data.search` | 搜索条件 |
| `data.table` | 表格数据、分页、排序、过滤 |
| `data.form` | 表单数据 |
| `data.option` | 枚举/远程 option 缓存 |
| `data.stat` | 统计卡片和图表数据 |
| `data.actionTarget` | 当前操作行、删除对象、弹窗上下文 |
| `data.resourceMeta` | 资源中心配置 |
| `data.requestParams` | 请求/测试面板参数 |
| `data.channelRequest` | 通道请求结果 |
| `data.attempts` | 请求尝试/日志结果 |

常见 `state`：

| 路径 | 说明 |
| --- | --- |
| `state.dialog.*` | 弹窗开关 |
| `state.drawer.*` | 抽屉开关 |
| `state.confirm.*` | 确认框开关 |
| `state.currentTab` | 当前 tab |
| `state.currentCate` | 当前分类 |
| `state.serviceParamForm` | 服务参数临时表单 |
| `state.serviceEndpointForm` | 服务端点临时表单 |
| `state.*Index` | 本地数组当前编辑/删除下标 |

### 21.8 常见 `meta` 索引

这些 key 都已经在 bot/front/user 的页面中出现过或由对应通用节点消费。不要把它们都塞进一个节点；按节点类型选择需要的字段。

```txt
addAllText, addText, allowBatchSelect, allowCategoryAssign, allowClear,
allowUpload, api, back, bizKey, bizName, blockMs, bodyClassName, bodyScroll,
bulkActions, buttons, cardDensity, categoryIdPath, changeVersionPath,
childExtraFields, childParentField, childUse, clearLabel, clearOnChange,
clearText, columns, confirm, content, control, controlClassName, countField,
createButton, dataKey, defaultFirst, description, descriptionPath, drag,
drawerClassName, emptyText, endValue, errorMessage, externalPagination,
extraParamsPath, fallback, falseValue, field, fillFromOption, footer,
formLayout, formSection, format, height, hiddenCondition, hiddenWhen, hideCategoryFilter,
icon, inputType, itemName, kind, labelField, labelTarget, leafLayout,
loadingText, mainParamPath, maxCount, maxLength, minHeight, multiple,
nameKey, optionDirection, optionFilter, optionParams, optionReloadPaths,
optionSource, orientation, pageDataPatches, pagePath, pageRoute, pageRouteQuery,
pageSizePath, paramApi, paramSource, parentField, patchPayloadPath,
patchRowKey, patchTargetPath, placeholder, powerPath, queryKey, range,
remote, remoteOptionSearch, remoteSearch, requestApi, rootValue, rowKey,
rows, ruleId, saveMode, savePath, searchLayoutId, searchPlaceholder,
searchSubmit, selectable, showCondition, showCount, showWhen, side, size,
stateKey, statusCases, statusChangeAction, statusDisplay, statusField,
streamApi, successMessage, tab, tabs, target, template, title, titleKeyPath,
titleNamePath, titlePath, to, totalPath, tree, treeClassName, trueValue,
type, uncategorized, uncategorizedLabel, uploadRules, uploadType, use,
valueFormat, valueMode, variant, width, withBack
```

常用 meta 按功能分组：

| 功能 | meta |
| --- | --- |
| 远程 option | `api`、`use`、`labelField`、`nameKey`、`parentField`、`rootValue`、`extraFields`、`childExtraFields` |
| option 联动过滤 | `optionParams`、`optionReloadPaths`、`optionFilter`、`remoteOptionSearch`、`remoteSearch` |
| 字段联动显示 | `hiddenWhen`、`showWhen`、`hiddenCondition`、`showCondition`、`control`、`tab` |
| 表单布局 | `formLayout`、`controlClassName`、`placeholder`、`clearOnChange`、`clearLabel` |
| 二级/级联选择 | `childUse`、`childParentField`、`valueMode`、`saveMode`、`labelTarget`、`leafLayout` |
| 子数组 | `pageRoute`、`pageRouteQuery`、`addText`、`addAllText`、`clearText`、`drag`、`valueFormat`、`fillFromOption` |
| 组合映射 | `mainParamPath`、`extraParamsPath`、`optionSource`、`paramSource`、`addText`、`addAllText`、`clearText` |
| 上传/资源 | `uploadType`、`kind`、`ruleId`、`bizKey`、`bizName`、`uploadRules`、`allowUpload`、`allowBatchSelect` |
| 表格 | `columns`、`rowKey`、`remote`、`selectable`、`bulkActions`、`externalPagination`、`pagePath`、`pageSizePath`、`totalPath`、`tree` |
| 弹窗/抽屉 | `stateKey`、`pageRoute`、`pageDataPatches`、`pageStatePatches`、`size`、`width`、`bodyClassName`、`footer` |
| 流式请求 | `streamApi`、`requestApi`、`paramApi`、`loadingText`、`successMessage`、`errorMessage`、`blockMs` |
| 统计/图表 | `rows`、`columns`、`countField`、`countUnit`、`format`、`cardDensity` |

### 21.9 表格 column 完整字段

表格列字段：

| 字段 | 说明 |
| --- | --- |
| `name` | 列名 |
| `value` | 行数据字段路径 |
| `type` | 列渲染节点类型 |
| `editor` | 是否行内编辑，或指定编辑器类型 |
| `trigger` | 行内编辑触发方式，`click` / `doubleClick` |
| `action` | 列内动作 |
| `meta` | 列扩展 |
| `className` | 列样式 |
| `tip` / `info` | 列说明 |
| `auth` | 列权限 |

现有列类型：

```txt
show-base, show-tag, show-select, show-date, show-rich, show-icon,
show-button, show-table, form-switch, media-image, media-audio,
media-video, media-file-list
```

常见 column meta：

```txt
align, buttons, cases, columns, compact, confirmValues, controlClassName,
countUnit, description, display, editable, falseValue, field, fixed,
format, height, label, maxVisible, preview, size, titlePath, trueValue,
variant, width
```

列表页中，参数为空或值为 `0` 时显示 `-`，优先用列 `meta.cases` 或后端格式化，不要让表格裸显示 `0`：

```json
{
  "name": "参数",
  "value": "param_id",
  "type": "show-base",
  "meta": {
    "cases": [
      { "value": 0, "text": "-" },
      { "value": "", "text": "-" }
    ]
  }
}
```

### 21.10 校验规则完整字段

`validate` 是数组，每项支持：

| 字段 | 说明 |
| --- | --- |
| `type` | 校验类型，如 `required`、`min`、`max`、`pattern`、`service` |
| `message` | 错误提示 |
| `pattern` | 正则 |
| `target` | 目标路径 |
| `min` / `max` | 长度或数值范围 |
| `use` | service 校验 |
| `field` | 字段名 |
| `operator` | 条件操作符 |
| `except` | 排除值 |
| `params` | 额外参数 |
| `when` | 条件校验数组 |
| `condition` | `all` / `any` |

`when.operator` 支持：

```txt
equals, notEquals, empty, notEmpty, includes, notIncludes
```

### 21.11 现有 page JSON 覆盖矩阵

`package/front` 覆盖通用后台：

| 页面 | 覆盖能力 |
| --- | --- |
| `front/account/list` | 账号列表、搜索、表格、弹窗编辑、确认删除、分页 |
| `front/account/update` | 账号编辑、密码字段、角色选择、保存 |
| `front/account/profile` | 个人资料、当前账号加载、保存前 service hook |
| `front/auth/list` | 权限树/权限列表、图标、弹窗编辑 |
| `front/auth/update` | 权限编辑、图标、排序、radio |
| `front/role/list` | 角色列表、弹窗编辑、确认删除 |
| `front/role/update` | 角色编辑、权限 `form-tree` |
| `front/resource/list` | 资源中心、上传、资源浏览 |
| `front/upload_accept_type/list` | 上传允许类型列表 |
| `front/upload_accept_type/update` | 允许类型编辑 |
| `front/upload_file_cate/list` | 资源分类、左侧分类列表、局部刷新 |
| `front/upload_file_cate/update` | 资源分类编辑、service hook |
| `front/upload_rule/list` | 上传规则列表、枚举展示 |
| `front/upload_rule/update` | 上传规则编辑、radio/checkbox/select/switch |
| `front/upload_storage/list` | 存储方式列表 |
| `front/upload_storage/update` | 存储方式编辑、密码/密钥字段 |

`package/bot` 覆盖复杂 package 后台：

| 页面 | 覆盖能力 |
| --- | --- |
| `bot/energon/account/update` | package 账号配置、开关、保存 |
| `bot/energon/log/list` | 日志列表、日期列、日志详情弹窗 |
| `bot/energon/log/view` | 日志详情、富文本、嵌套表格、媒体展示 |
| `bot/energon/provider_cate/list` | 来源分类，两栏分类模式 |
| `bot/energon/provider_cate/update` | 分类编辑 |
| `bot/energon/provider/list` | 来源列表、开关、弹窗、service hook |
| `bot/energon/provider/update` | 来源编辑、数组配置、单选/下拉 |
| `bot/energon/service/list` | 来源服务列表、服务弹窗、开关 |
| `bot/energon/service/update` | 来源服务编辑、接口 path、协议参数、service hook |
| `bot/energon/service_endpoint/list` | 服务端点子列表、本地数组弹窗、确认删除 |
| `bot/energon/service_endpoint/update` | 服务端点数组项编辑 |
| `bot/energon/service_endpoint/param` | 服务端点参数二级选择 |
| `bot/energon/service_param/list` | 服务参数子列表、规则展示、参数为空显示 `-` |
| `bot/energon/service_param/update` | 服务参数映射、固定值、选项、附件、组合映射 |
| `bot/energon/service_param/combo_param` | 组合映射参与参数二级选择 |
| `bot/energon/service_param/option_mapping` | 参数选项到来源字段值映射 |
| `bot/energon/param_cate/list` | 参数分类列表 |
| `bot/energon/param_cate/update` | 参数分类编辑 |
| `bot/energon/param/list` | 参数列表、选项子表、开关、service hook |
| `bot/energon/param/update` | 参数编辑、`form-array` 选项维护 |
| `bot/energon/param_option/update` | 参数选项编辑 |
| `bot/energon/power_cate/list` | 能力分类 |
| `bot/energon/power_cate/update` | 能力分类编辑 |
| `bot/energon/power/list` | 能力列表、开关、弹窗 |
| `bot/energon/power/update` | 能力编辑、参数数组、目标数组、service hook |
| `bot/energon/power_param/update` | 能力参数二级选择 |
| `bot/energon/power_target/update` | 能力目标二级选择 |

`module/user` 覆盖业务模块后台：

| 页面 | 覆盖能力 |
| --- | --- |
| `user/list` | 用户列表、搜索、日期范围、导入导出、drawer、modal、confirm、delete |
| `user/update` | 用户编辑、tab、角色/地区级联、富文本、上传、数组、保存 hook |
| `user/view` | 用户详情、富文本、媒体、文件列表 |
| `user/stat` | 统计卡片、图表 |
| `user/config/set` | 固定配置页、tab、上传、富文本、保存 |
| `user/content/list` | 内容列表、搜索、枚举、弹窗 |
| `user/content/update` | 内容编辑、富文本、枚举 |
| `user/source/list` | 来源列表 |
| `user/source/update` | 来源编辑 |
| `user/title/update` | 简单编辑页 |

### 21.12 AI 生成复杂后台时的完整工作流

1. 先写菜单和页面矩阵，不直接写 JSON。
2. 每个资源至少拆成：
   - `list.json`：可见入口。
   - `update.json`：隐藏编辑页或弹窗页。
   - `view.json`：需要只读详情时再加。
3. 普通 CRUD 不写 API，依赖 model + `package/front`。
4. 子项字段少时用 `form-array`；子项字段多或有独立生命周期时，用父页嵌入子 `list.json`。
5. 选项、单选、多选、二级选择优先由 model `Options` / `Relations` / `form-cascader` 解决。
6. 弹窗、抽屉、确认框只控制 `state`，实际保存/删除走 action。
7. 导入导出走 `show-button-group` + `import/export` action。
8. 复杂保存前规范化、跨表保存、校验、第三方协议都写 service hook。
9. 写完每个 JSON 后自查：
   - 节点类型是否在 21.5。
   - action 类型是否在 21.6。
   - `meta` 是否符合对应节点。
   - 表格枚举列是否有 option 或 cases。
   - 弹窗/抽屉 stateKey 是否存在。
   - `form`、`search`、`table`、`option` 路径是否一致。
