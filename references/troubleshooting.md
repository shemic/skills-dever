# 故障排查

先从问题所属层开始查。不要通过放宽权限或硬编码 model/action 名来修表面现象。

## `model 未注册`

检查：

- model 文件在 `module/<name>/model` 或 `package/<name>/model` 下。
- 文件内只有一个零参数 `NewXxxModel`。
- 文件名和 `NewXxxModel` 匹配。
- 构造函数不会 panic。
- `dever init` / `dever run` 已刷新生成的 `data/load/model.go`。

不要手改 `data/load/model.go`。

## `暂无权限`

检查：

- 当前登录账号和站点访问模式。
- page path 和 menu/auth 注册。
- action key 是否从 page path 正确推导。
- 子弹窗/子表是否保留 action 上下文。
- 自定义 API route 的 auth/public 配置。
- 如果使用组件元数据，检查组件 `dever.json` 的 menu/auth 条目。

不要用通配权限修复，除非用户明确接受不安全的后台快捷方式。

## `option 无法推导模型`

检查：

- 字段路径属于当前 form/table model。
- model 是否为该字段定义了 Options 或 Relations。
- 嵌入行/弹窗是否带着正确 model 上下文。
- page 是否误复用了其他 model 的分类/search 状态。
- 标准页是否错误硬编码 `_model/_use`。

## 页面 Schema 空值错误

检查顶层对象：

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

## 导入循环

检查 package/service 依赖。常见原因是 package/front 的 service 包 import 某个子包，而该子包又 import package/front service。

修复方式：把共享小 helper 移到更底层的包，或通过窄接口反转依赖。不要再加一个同时 import 两边的 wrapper 包。

## Logo 黑色背景

检查：

- `config/front/assets/<site>/images/logo.svg` 用作侧栏/加载态 logo 时是否透明。
- `favicon.svg` 可以带背景。
- 组件 `dever.json.front.sites.<site>.assets.logo` 是否指向正确文件。
- 是否误改了编译产物 `package/front/html/assets/index*.js`。
- front 源码是否故意把 logo 包在固定深色 icon 容器里。

## Front 插件未加载

检查：

- 所属 package/module 下存在 `front/src/plugin.ts`。
- page JSON 使用的是已注册 node type。
- 插件 dev server 只由 `dever run` 启动。
- 没有手动修改构建产物。

## 生成路由缺失

检查：

- API 方法已导出，命名为 `Get/Post/Put/DeleteXxx`。
- receiver 类型已导出。
- 文件位于 `api` 目录下。
- 已通过 `dever routes` 或 `dever run` 刷新生成路由。

不要手改 `data/router.go`。
