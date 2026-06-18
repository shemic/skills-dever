# 服务端模板页面

公开内容站、演示站、CMS 类 SEO 页面可以使用 `package/front` 的服务端模板渲染能力。它不替代现有 JSON/React 页面，只在页面声明 `page.render: "template"` 时生效。

模板页面仍必须保留六对象规则：

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
      "description": "$data.article.summary",
      "canonical": "/article/${data.article.slug}"
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

规则：

- `page.render: "template"` 表示该 page 由 Go `html/template` 服务端输出完整 HTML。
- 模板页面直接由服务端输出，不受 `setting.runtime.shell` 影响，也不会加载 React 后台壳。
- 顶层 `template` 只放渲染元信息：`route`、`layout`、`view`。不要把模板配置塞进 `nodes`；`nodes` 保持 React/runtime 节点语义。
- SEO 数据放在 `data.seo`，渲染后模板上下文提供 `.SEO.Title`、`.SEO.Description`、`.SEO.Image`、`.SEO.Canonical`。
- `data` 支持模板站最小数据能力：`model`、`service`、`one: true`、`required: true`、`defaultFilters`、`pageSize`、`order`。
- `model` 和 `service` 不能同时作为模板 data 数据源；需要模型查询后补字段时，把补字段逻辑放普通 page data 的 `data.table.service` 或 `data.form.service`。
- `defaultFilters`、`data.seo` 等模板值支持 `$route.xxx`、`$query.xxx`、`$site.xxx`、`$data.xxx`。
- 单条数据设置 `required: true` 时，查询不到记录返回 404。
- 模板访问路径是 `/{site.api}{template.route}`。例如 site `api: "mt"` + `route: "/article/:slug"`，访问 `/mt/article/hello`。
- 模板路由不要占用站点保留根路径：`main`、`route`、`upload`、`resource`、`import`、`export`、`runtime.js`、`assets`。

模板和资源随组件发布：

```txt
module/mt/front/page/mt_content/article.json
module/mt/front/template/mt_content/layout.html
module/mt/front/template/mt_content/article.html
module/mt/front/template/mt_content/partials/header.html
module/mt/front/assets/mt_content/css/site.css
module/mt/front/assets/mt_content/images/logo.png
```

模板文件默认从当前 site 的 `page` 目录隔离读取。上例 site `page: "mt_content"`，所以 `template.view: "article.html"` 会读取 `front/template/mt_content/article.html`。

静态资源访问路径是 `/{site}/assets/{assetRef}`，模板上下文提供 `.Site.AssetBase`。资源必须显式声明来源：

```html
<link rel="stylesheet" href="{{ .Site.AssetBase }}/mt/assets/mt_content/css/site.css">
<img src="{{ .Site.AssetBase }}/config/assets/mt_content/images/logo.png" alt="">
```

资源引用规则：

```txt
config/assets/<site>/images/logo.svg      -> config/front/assets/<site>/images/logo.svg
mt/assets/mt_content/css/site.css         -> module/package mt 的 front/assets/mt_content/css/site.css
```

不做隐式覆盖查找；需要项目覆盖时写 `config/assets/...`，需要组件默认资源时写 `<component>/assets/...`。
