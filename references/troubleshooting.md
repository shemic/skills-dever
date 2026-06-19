# 故障排查

不要通过放宽权限、硬编码 model/action 名或复制旧协议修表面现象。

## model 未注册

检查：

- model 是否在 active module/package 的 `model/` 下。
- 是否只有一个零参 `NewXxxModel`。
- 文件名是否匹配 `NewXxxModel`。
- 构造函数是否 panic。
- 是否刷新 `data/load/model.go`。

不要手改生成文件。

## 暂无权限

检查：

- 当前 site 的 `access.mode`。
- `dever.json.front.sites.<site>.auth/public`。
- page path、`page.parent` 和权限同步。
- action key 是否从 page path 正确推导。
- 弹窗/子表是否保留 `_inherit/_parentPath/_parent_*`。
- 自定义 API 是否显式 public。

不要临时放开通配权限。

## option 无法推导模型

检查：

- 节点 `value` 是否属于当前 form/table model。
- model 是否定义 Options/Relations。
- 跨资源 option 是否写了 `option.model` 或 `option.service`。
- 嵌入页/弹窗是否有正确 path 和父级输入。
- 是否误写旧字段。

## 页面空白或 schema 错误

检查六个顶层对象：

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

再查浏览器请求的 `route/info`、`route/data`、插件 manifest 和节点 type。

## Front 插件未加载

检查：

- 组件是否 active。
- 是否有 `front/dist/manifest.json` 或 `front/src/plugin.ts`。
- `dist/placeholder.txt` 不算有效 dist。
- `dever run` 是否启动插件 dev server。
- page JSON 是否使用已注册 node type。
- plugin `depends` 是否写 Dever plugin 名，不是 npm 包名。

## 菜单为空

检查：

- 站点 access 是否 `rbac/login/public`。
- 组件 `dever.json.front.sites.<site>.auth`。
- `page.parent` 是否指向有效分组或列表。
- 当前账号角色是否有权限。
- `dever init`/权限同步是否已执行。

不要把菜单写到项目 `config/front.json`。

## 导入循环

常见原因：`package/front` 通用 runtime import 业务 package，或 helper 同时依赖两边。

修复：把共享 helper 下沉到更底层包，或用窄接口反转依赖。不要再加一个 wrapper 包。
