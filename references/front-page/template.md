# 服务端模板页面

服务端模板用于公开内容站、SEO、CMS、演示站。普通后台和工作台仍优先 page JSON；强交互用 front plugin。

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
- 查询不到且 `required: true` 时返回 404。
- 模板路由不要占用站点保留根路径：`main`、`route`、`upload`、`resource`、`import`、`export`、`runtime.js`、`assets`。

## 资源

模板和资源随组件发布：

```txt
module/mt/front/page/mt/article.json
module/mt/front/template/mt/layout.html
module/mt/front/template/mt/article.html
module/mt/front/assets/mt/css/site.css
```

项目覆盖资产放 `config/front/assets/<site>/...`，组件资产放 `<component>/front/assets/...`。
