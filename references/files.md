# 文件、配置和资产

`skills/skills-dever/files` 是模板和静态资源来源。不要把大段 heredoc 模板散落在脚本里，也不要通过修改编译产物来改配置或品牌展示。

## files 目录

期望结构：

```txt
files/
  gitignore
  AGENTS.dever.md
  config/
    setting.jsonc.tmpl
    front/assets/admin/images/logo.svg
    front/assets/admin/images/favicon.svg
    front/assets/work/images/logo.svg
    front/assets/work/images/favicon.svg
  go/
    go.mod.tmpl
    main.go.tmpl
    package-shim.go.tmpl
    model.go.tmpl
    middleware/readme.txt
    data/readme.txt
    package/readme.txt
  page/standard/
    list.json.tmpl
    update.json.tmpl
    detail.json.tmpl
  component/
    dever.json.tmpl
    skills/SKILL.md.tmpl
    skills/README.md.tmpl
```

脚本可以替换这些简单占位符：

```txt
{{APP_NAME}}
{{PORT}}
{{MODULE_NAME}}
{{PACKAGE_NAME}}
{{TYPE_NAME}}
{{RESOURCE_FILE}}
{{MODEL_FUNC}}
{{TABLE_NAME}}
{{SITE_KEY}}
{{PAGE_NAME}}
{{RESOURCE_NAME}}
{{COMPONENT_NAME}}
{{COMPONENT_TITLE}}
```

除非当前仓库已经使用复杂模板引擎，否则不要引入新的模板引擎。

## 配置

从模板生成配置：

- `config/setting.jsonc` 来自 `files/config/setting.jsonc.tmpl`。
- 空项目 `go.mod` 来自 `files/go/go.mod.tmpl`。
- 空项目 `main.go` 来自 `files/go/main.go.tmpl`，默认注册 `data.RegisterRoutes` 和 `frontsite.Register`。

目标配置已存在时，默认不覆盖。使用 `--force` 时必须先备份旧文件。

规则：

- 模板里不放真实密钥。
- 占位值使用 `replace_me`。
- `go.mod.tmpl` 是普通外部项目模板，不能包含 `replace github.com/shemic/dever => ./dever`。
- `go.mod.tmpl` 不写死 Dever 版本；空项目初始化脚本用 `go get github.com/shemic/dever@main` 写入当前 main 对应的真实版本。
- `go.sum` 由 Go 工具生成，不能作为模板维护。
- 日志默认写文件：`data/log/access.log`、`data/log/error.log`。
- front 站点配置放组件 `dever.json.front.sites`，全局公开路径放 `dever.json.front.public`。
- `config/front/assets/<site>` 只放站点静态资产；不要用项目级 `config/front.json(c)` 维护站点。
- 项目运行数据放 `data/`，不放 `package/`。

## Logo 和 Favicon

品牌资产属于站点配置资产：

```txt
config/front/assets/<site>/images/logo.svg
config/front/assets/<site>/images/favicon.svg
```

组件 `dever.json.front.sites.<site>.assets` 使用相对路径引用它们：

```jsonc
{
  "front": {
    "sites": {
      "admin": {
        "assets": {
          "logo": "assets/images/logo.svg",
          "favicon": "assets/images/favicon.svg"
        }
      }
    }
  }
}
```

规则：

- `logo.svg` 通常应为透明背景，适合侧栏和加载态。
- `favicon.svg` 可以自带背景，因为它需要在浏览器标签页独立展示。
- 不要通过编辑 `package/front/html/assets/index*.js` 修改 logo。
- 不要编辑 `package/front/html` 或插件 `front/dist` 下的构建产物。
- 不要按站点复制一套 logo 展示代码；复用 package/front 的站点品牌/runtime 行为。

## AGENTS 提示块

使用 `files/AGENTS.dever.md` 作为 `AGENTS.md`、`CLAUDE.md`、`.codex/AGENTS.md` 和 `.opencode/AGENTS.md` 的 managed block。

不要覆盖整个文件。只插入或替换：

```md
<!-- dever-skill:start -->
...
<!-- dever-skill:end -->
```

提示块必须说明：处理 Dever 任务时必须读取 `shemic-dever` skill；如果 skill 不可用，就手动读取 `skills/skills-dever/SKILL.md` 和相关 references。

## 公开文件和上传文件

- 公开静态资源必须放在所属 site/component 路径下，并通过配置/runtime 引用。
- 上传文件必须走 package/front 上传规则，或走有文档说明的自定义上传 API。
- 上传要校验大小、扩展名、可用时校验 MIME 和存储目标。
- 不要提交运行时上传文件、日志、导出文件或用户数据。
