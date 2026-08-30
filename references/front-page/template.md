# 服务端模板页面

服务端模板用于公开内容站、SEO、CMS 和演示站，由 Go `html/template` 输出完整 HTML。普通后台和工作台继续使用客户端 Page JSON；需要强交互时按 [front-plugin.md](../front-plugin.md) 判断，不把模板当成第二套后台框架。

## 最小结构

模板页面仍保留六对象规则，并额外写顶层 `template`：

```json
{
  "page": {
    "name": "文章详情",
    "render": "template"
  },
  "layout": {},
  "nodes": {},
  "data": {
    "article": {
      "model": "mt.NewArticleModel",
      "one": true,
      "required": true,
      "defaultFilters": {
        "slug": "$route.slug",
        "status": "published"
      }
    },
    "seo": {
      "title": "$data.article.title",
      "description": "$data.article.summary"
    }
  },
  "state": {},
  "action": {},
  "template": {
    "route": "/article/:slug",
    "layout": "layout.html",
    "view": "article.html"
  }
}
```

## 规则

- `page.render: "template"` 表示 Go `html/template` 服务端输出完整 HTML。
- 顶层 `template` 只放渲染元信息：`route`、`layout`、`view`。
- SEO 数据放 `data.seo`。
- 模板 data 支持最小数据能力：`model`、`service`、`one`、`required`、`defaultFilters`、`pageSize`、`order`。
- 模板 data 的 `model` 和 `service` 不能同时作为同一数据源。
- `service` 必须指向 `service/**` 中已经注册的 Provider 名称；复杂查询和业务规则由 Provider 调用普通 Service。
- 查询不到且 `required: true` 时返回 404。
- 模板路由不要占用站点保留根路径：`main`、`route`、`upload`、`resource`、`import`、`export`、`runtime.js`、`assets`。
- 展示 `form-editor` 正文时，用模板函数 `{{ richText .Data.article.content }}`；只要内部片段时用 `{{ richTextInner .Data.article.content }}`。
- 不要在模板里手写 JSON 解析、媒体备注解析或直接输出原始 HTML。媒体备注来自 `attrs.caption`，统一渲染为 `figure > figcaption`。

## 资源

模板和资源随组件发布：

```txt
module/mt/front/page/mt/article.json
module/mt/front/template/mt/layout.html
module/mt/front/template/mt/article.html
module/mt/front/assets/mt/css/site.css
```

项目覆盖资产放 `config/front/assets/<site>/...`，组件资产放 `<component>/front/assets/...`。

## 何时不用模板

- 后台列表、表单、详情和弹窗：普通 Page JSON。
- 只需要登录的工作台：Page JSON + 对应 site access/shell。
- 画布、编辑器和实时交互：front plugin。
- 只是读取单条记录：模板 `data.<key>.model + one`，不新增 GetInfo API。

模板 data 不支持某项业务流程时，先由同组件 Service 提供聚焦结果，再通过注册 Provider 暴露；不要在模板函数中访问数据库或外部服务。
