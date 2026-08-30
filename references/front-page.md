# Front Page 入口

普通后台、配置页、列表、编辑、详情和简单工作台优先使用 `package/front` Page JSON。第一次实现一项页面功能先读 [任务式指南](front-page/guide.md)，遇到专项问题再读下面的协议文档。

## 能力选择

按最低可用能力逐级判断：

1. 字段标签、枚举、关联和默认排序：Model comment、Options、Relations、Order。
2. 普通列表、表单、详情、搜索、弹窗和标准保存删除：Page JSON。
3. Page 数据补充、远程 option、保存前后校验或规范化：`service/**` 中的 Provider。
4. 事务、状态流转、跨表规则和外部调用：普通 Service；Page Provider 只做边界适配。
5. 真实 HTTP、文件、流式协议或外部回调：薄 API + Service。
6. Page runtime 没有对应交互能力：front plugin。

普通 CRUD 到第 2 步为止，不新增 CRUD Service、API 或空 Provider。

## 阅读路由

| 任务 | 必读 |
| --- | --- |
| 从 Model 到 list/update/detail 的完整实施顺序 | [guide.md](front-page/guide.md) |
| 顶层结构、路径推导、数据来源和禁止旧字段 | [protocol.md](front-page/protocol.md) |
| submit/save/delete、partial save、Provider hook | [action.md](front-page/action.md) |
| Options、Relations、本地与远程 option、复杂节点来源 | [option.md](front-page/option.md) |
| 表单字段、系统字段、分类字段、富文本边界 | [field.md](front-page/field.md) |
| 站点、权限、菜单、public、shell、插件发现 | [site.md](front-page/site.md) |
| 服务端模板、SEO、公开内容站 | [template.md](front-page/template.md) |
| 数据模板这一项专用能力 | [data-template.md](front-page/data-template.md) |
| Page runtime 无法表达，需要 React 节点 | [front-plugin.md](front-plugin.md) |

`data-template.md` 是 `package/front` 数据模板的专用契约，不是普通业务数据的通用替代方案。

## 稳定骨架

Page 源文件统一保留六个顶层对象：

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

客户端 schema 要求 `page` 和 `layout`，并会为 `nodes/data/state/action` 提供默认空对象；源文件仍显式保留六项，避免经过服务端 `RawMessage` 封装后产生 `null`，也方便审查页面的数据和动作边界。

标准推导只发生在固定容器和路径组合：

- `.../list` 的 `data.table` 推导列表 Model。
- `.../create|update|view|detail|info` 的 `data.form` 推导表单 Model。
- 标准保存和删除从 action path 推导 Model。

能推导的不写；非标准路径、跨资源或真实自定义数据才在所属 `data/action/option/meta` 位置声明当前协议的 `model` 或 `service`。

## 旧协议隔离

以下内容只能出现在禁止说明或审计脚本中，不能进入正向示例和模板：

```txt
_model  _use  modelName  modelPath  type:"service"
submit.use  option.use  childUse  service@...  transform
<<NewXxxModel>>  {{Service}}  /front/route/option  /front/route/action
```

`loadApi`、`optionSource`、`paramSource`、`fillFromOption` 不是上述旧协议。它们是少数复杂节点仍在使用的当前 `meta` 字段，只能按 [option.md](front-page/option.md) 和节点源码使用，不能扩展为普通 option 的默认写法。

## 事实来源

实现前按以下顺序核对：

1. `backend/package/front/service/page` 与 `service/action`。
2. `front/src/lib/schema.ts`、`front/src/lib/action.ts`、`front/src/page/option.ts`。
3. 目标节点在 `front/src/page/nodes` 下的实现。
4. 当前组件已有 Page JSON 和 `dever.json`。

已有页面只是例子，不高于 runtime/schema。不要从旧 demo 复制字段，也不要因为某个历史页面仍存在某种写法就把它提升为全局协议。
