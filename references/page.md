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
| `package/front/page/account/list.json` | `front/account/list` |
| `package/front/page/account/update.json` | `front/account/update` |
| `package/bot/front/page/agent/agent/list.json` | `bot/agent/agent/list` |
| `package/bot/front/page/brain/brain/list.json` | `bot/brain/brain/list` |
| `module/user/front/page/list.json` | `user/list` |
| `module/work/front/page/type/list.json` | `work/type/list` |

页面归属跟代码归属走。`module/<name>/main.go` 如果只是 `// dever:import ...`，页面仍放真实 package。

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
form-input, form-textarea, form-number, form-switch, form-select, form-date
feedback-modal, feedback-drawer, feedback-confirm
nav-tab
```

不确定支持不支持时，先查现有 `package/front/page` 和 `package/bot/front/page`，不要发明节点。

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

后端 `/front/route/action` 只直接处理 `save/delete`。复杂规范化、强校验、跨表保存写 service hook。

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
            {"value": "status", "type": "show-tag"},
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
      {"type": "form-switch", "value": "form.status", "mode": "form"},
      {"type": "show-button", "name": "保存", "action": {"click": "submit"}}
    ]
  },
  "data": {
    "form": {
      "id": 0,
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

标准编辑页不写 `_model/_use/submit.use`。

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
- 顶层 6 个对象是否都存在？
- 标准页是否没有显式 model？
- `data.table` 是否有 `page/pageSize/total`？
- 表单字段是否都绑定 `form.*` 且 `mode: "form"`？
- 运行态是否放 `state`，业务数据是否放 `data`？
- 是否没有发明节点或 action？
- 复杂业务是否放 Service/Provider？
