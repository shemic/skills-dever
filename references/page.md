# Page JSON 规则

后台页面默认用 `Model + package/front + page JSON`。不要为普通 CRUD 写前端源码或自定义 API。

参考顺序：

1. 当前项目的 `package/front/page`。
2. 当前项目的 `package/bot/front/page`。
3. 当前项目的 `package/front/service/page`、`service/action`、`service/meta`、`service/record`。
4. 如果当前项目 package 里没有同类示例，再找 GitHub demo 里的 `module/*/front/page`。

不要拿当前项目的 `module/user` 页面当新页面参考源。

## 1. 文件位置和 path

文件位置决定 path：

| 文件 | path |
| --- | --- |
| `package/front/page/{page}/account/list.json` | `front/account/list` |
| `package/front/page/{page}/login.json` | `front/login` |
| `package/front/page/{page}/main.json` | `front/main` |
| `package/bot/front/page/{page}/team/workspace.json` | `bot/team/workspace` |
| `module/work/front/page/work/home.json` | `work/home` |

页面归属跟代码归属走。`module/<name>/main.go` 如果只是 `// dever:import ...`，页面仍放真实 package。

多站点 front 使用 `front/page/{page}/...` 做物理隔离。`{page}` 来自 `config/front.json.sites.*.page`，不进入最终 route。新增站点时只改 `front.json` 和对应页面目录。

`login` 和 `main` 是站点系统页，route 前缀跟当前站点的 `api` 一致：

- `admin` 的 `api` 是 `front`，所以读取 `front/login`、`front/main`。
- `work` 的 `api` 是 `work`，所以读取 `work/login`、`work/main`。
- `*/login` 未登录可读取，只用于登录界面。
- `*/main` 登录后读取，用于组合当前站点 Shell。
- 后台左右结构、前台顶部导航、全屏页面都应该通过 `main.json` 组合 `app-*` 节点实现，不要在业务页面里复制全局框架。

这里的 route 前缀不是物理 `page` 目录名。`sites.<siteKey>.api` 决定系统页逻辑路径，`sites.<siteKey>.page` 决定物理目录。比如 `api: "work", page: "work"` 时，请求的是 `work/main`，读取 `front/page/work/main.json`；如果 `api: "ops", page: "admin"`，系统页仍是 `ops/main`，不会自动变成 `front/main`。

复用 admin 样式时，不要只改 `page: "admin"`。更稳的做法是在新站点自己的 page 目录放同构 `main.json` / `login.json`：

```txt
module/work/front/page/work/main.json   # 可参考 package/front/page/admin/main.json
module/work/front/page/work/login.json  # 可参考 package/front/page/admin/login.json
```

`app-login-form` 会按当前站点 runtime 请求 `auth/login`，所以 `work` 站点会走 `/work/auth/login`。只要业务 API 返回兼容的 `{token, user}`，就可以复用 admin 登录表单；不要在页面 JSON 里写死 `/front/auth/login`。

站点展示信息、前端 setting 和资源放 `config/front.json`。`assets.logo`、`assets.favicon` 支持外部 URL、绝对路径，或相对路径；相对路径映射到 `backend/config/front/assets/{siteKey}/`。admin 默认 `logo.svg` / `favicon.svg` 模板在 `skills/skills-dever/files/config/front/assets/admin/images/`：

```json
{
  "sites": {
    "admin": {
      "name": "管理后台",
      "subtitle": "平台配置",
      "assets": {
        "logo": "assets/images/logo.svg",
        "favicon": "assets/images/favicon.svg"
      },
      "setting": {
        "appearance": {
          "theme": "light",
          "sidebar": "floating",
          "layout": "compact",
          "direction": "ltr"
        },
        "runtime": {
          "skin": "default",
          "routerMode": "history"
        }
      }
    }
  }
}
```

## 2. 顶层结构

每个页面都保留 6 个顶层对象：

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

不要省略空对象。缺 `data/state/action` 会让前端 schema 收到 `null`。

## 3. Model 推导

标准后缀自动按 path 推导 model：

- `/list`
- `/update`
- `/create`
- `/view`
- `/detail`
- `/info`

标准页不要写：

- `data.table.list: "<<xxx.NewXxxModel>>"`
- `data.form._model`
- `data.form._use`
- `action.submit.use`

推导不到时，先修 model 文件名、`NewXxxModel` 或 page path。不要靠硬写 model 兜底。

只有非标准页才显式声明 model，例如 `/set`、`/config`、固定单条配置页、跨资源嵌入页。

## 4. Page / Layout / Nodes

`page`：

- 可见列表页挂一级菜单 key。
- 编辑、详情、隐藏页挂入口列表 path。
- 隐藏页显式 `type: 2`。

`layout` 只放结构，不放业务数据。常用结构：

```json
{
  "layout": {
    "type": "container",
    "children": {
      "page-header": {"type": "header"},
      "page-main": {
        "type": "main",
        "children": {
          "toolbar-row": {"type": "row"},
          "table-row": {"type": "container"},
          "dialog-shell": {"type": "container"}
        }
      }
    }
  }
}
```

`nodes` 的 key 必须对应 layout id。

字段节点默认不写 `name`，运行时会从 model comment、Options、Relations 推导。只有按钮、操作列、弹窗标题、提示文案、覆盖默认文案时才写 `name`。

常用节点：

```txt
show-title, show-base, show-date, show-tag, show-table, show-button, show-page
form-input, form-textarea, form-number, form-switch, form-radio, form-checkbox, form-select, form-date
feedback-modal, feedback-drawer, feedback-confirm
nav-tab
app-site-brand, app-login-form, app-sidebar, app-topbar, app-outlet, app-assistant
```

不确定支持不支持时，先查现有 `package/front/page` 和 `package/bot/front/page`，不要发明节点。

表单选择控件选择：

- 固定少量单选枚举，优先 `form-radio`；通常 2-4 个选项都不要写成 `form-select`。
- 选项很多、来自 Relations/远程数据、需要搜索、将来明显会增长时，才用 `form-select`。
- 固定少量多选枚举用 `form-checkbox`。
- 二值开关型字段用 `form-switch`；如果是 `status/sort` 这类列表维护字段，按列表页内联维护规则处理，不放进 update 表单。

## 5. Data / State / Action

`data` 放业务数据：

- `data.search`
- `data.table`
- `data.form`
- `data.option`
- `data.actionTarget`

`state` 放运行态：

- `state.dialog`
- `state.drawer`
- `state.confirm`
- `state.currentTab`

`action` 放命名动作。保存动作优先叫 `submit`。

后端 route/action 由当前站点 runtime 的 API 前缀决定，例如 `runtime.apiHost + "route/action"`。页面 JSON 里不要写死 `/front/route/action`；复杂规范化、强校验、跨表保存写 service hook。

## 6. 标准列表页

```json
{
  "page": {
    "name": "用户",
    "icon": "users",
    "parent": "system",
    "sort": 1
  },
  "layout": {
    "type": "container",
    "children": {
      "page-header": {"type": "header"},
      "page-main": {
        "type": "main",
        "children": {
          "toolbar-row": {"type": "row"},
          "table-row": {"type": "container"},
          "dialog-shell": {"type": "container"}
        }
      }
    }
  },
  "nodes": {
    "page-header": [
      {"type": "show-title", "value": "page"}
    ],
    "toolbar-row": [
      {"type": "form-input", "value": "search.keyword", "mode": "search"},
      {"type": "show-button", "name": "搜索", "meta": {"searchSubmit": true}}
    ],
    "table-row": [
      {
        "type": "show-table",
        "value": "table.list",
        "meta": {
          "remote": true,
          "externalPagination": true,
          "pagePath": "data.table.page",
          "pageSizePath": "data.table.pageSize",
          "totalPath": "data.table.total",
          "rowKey": "id",
          "columns": [
            {"value": "name", "type": "show-base"},
            {"value": "status", "type": "form-switch", "meta": {"trueValue": 1, "falseValue": 2}},
            {"value": "sort", "type": "show-base", "editor": "form-number", "trigger": "doubleClick"},
            {"value": "created_at", "type": "show-date"}
          ]
        }
      }
    ],
    "dialog-shell": []
  },
  "data": {
    "search": {"keyword": ""},
    "table": {
      "page": 1,
      "pageSize": 10,
      "total": 0,
      "searchFields": ["name"]
    }
  },
  "state": {},
  "action": {}
}
```

标准列表页 `data.table` 不写 `list`。

状态、排序这类列表维护字段放在列表页内联维护，不放进编辑页表单：

- `status`：列表列用 `form-switch`。
- `sort`：列表列用 `show-base` + `editor: "form-number"` + `trigger: "doubleClick"`。

子表 `form-array` 如果已经配置 `meta.drag: "sort"`，排序由父表内的拖拽交互维护；子编辑页只保留业务字段，不再放 `form.sort` 输入框。

## 7. 标准编辑页

```json
{
  "page": {
    "name": "用户编辑",
    "parent": "user/list",
    "type": 2,
    "auth": [
      {"key": "user/create", "name": "用户新增", "query": {"id": "empty"}},
      {"key": "user/update", "name": "用户编辑", "query": {"id": "required"}}
    ]
  },
  "layout": {
    "type": "container",
    "children": {
      "form-main": {"type": "main"}
    }
  },
  "nodes": {
    "form-main": [
      {"type": "form-input", "value": "form.name", "mode": "form", "meta": {"required": true}},
      {"type": "show-button", "name": "保存", "action": {"click": "submit"}}
    ]
  },
  "data": {
    "form": {
      "id": 0,
      "name": ""
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

标准编辑页不写 `_model/_use/submit.use`。
标准编辑页只放主要业务字段；`status`、`sort` 不放进编辑表单，统一在列表页内联维护。
编辑页里来自 model Options 的固定少量单选字段用 `form-radio`，例如类型、模式、来源、是否启用某个业务能力；不要因为它是枚举就默认用 `form-select`。关系字段、账号/角色/分类等数量可能增长的选择仍用 `form-select`。
`auth` 父级优先级：单条 `auth.parent` > `page.parent` > 从 `create/update/edit` 自动推断同路径 `list`。

## 8. 非标准页显式 model

只在 path 无法推导时使用：

```json
{
  "data": {
    "form": {
      "_model": "bot.agent.NewRuntimeConfigModel",
      "id": 1
    }
  },
  "action": {
    "submit": {
      "type": "save",
      "params": "form",
      "use": "bot.agent.NewRuntimeConfigModel",
      "upsert": true
    }
  }
}
```

## 9. 自查

- 文件位置是否对应 path？
- 文件是否放在正确的 `front/page/{page}/...` 目录？
- 顶层 6 个对象是否都存在？
- 标准页是否没有显式 model？
- `data.table` 是否有 `page/pageSize/total`？
- 表单字段是否都绑定 `form.*` 且 `mode: "form"`？
- update 表单里的固定少量单选枚举是否用了 `form-radio`，而不是默认 `form-select`？
- 运行态是否放 `state`，业务数据是否放 `data`？
- 是否没有发明节点或 action？
- 复杂业务是否放 Service/Provider？
