# 文件和模板

`files/` 是确定性模板来源。不要把大段 heredoc 模板散落在脚本里。

## 目录

```txt
files/
  AGENTS.dever.md
  gitignore
  config/setting.jsonc.tmpl
  go/
    go.mod.tmpl
    main.go.tmpl
    model.go.tmpl
    package-shim.go.tmpl
    data/readme.txt
    middleware/readme.txt
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

## 模板规则

- 模板必须生成当前 Dever 协议。
- 标准 page 模板必须保留 `page/layout/nodes/data/state/action` 六对象。
- 标准 page 模板使用路径自动推导 model，不写旧字段。
- list 页必须显式 `page.parent`。
- update 页只写最小 `action.submit`。
- Go module 固定 `module my`。
- 普通项目入口使用 `github.com/dever-package/front/service/site`，不 import 本地 `package/front`。
- package shim 只写 `// dever:import github.com/dever-package/<name>`。

## 旧写法禁止

模板不能生成：

```txt
_model
_use
modelName
modelPath
type: "service"
submit.use
option.use
childUse
service@...
transform
<<NewXxxModel>>
{{Service}}
/front/route/option
/front/route/action
```

## 资产

- `logo.svg` 默认透明背景。
- `favicon.svg` 可以带背景。
- 站点展示配置在组件 `dever.json.front.sites.<site>.config`。
- 项目覆盖只写 `config/front.json.sites.<site>` 的展示配置。
- 不修改 `package/front/front/html` 或 `front/dist` 产物。

## 脚本

- `boot.sh` 只用于空项目。
- `module.sh` 只生成 model 骨架，不生成 Service/API。
- `page.sh` 只生成标准 page JSON。
- `component-skill.sh` 生成 `package` 或 `module` 组件 skill。

新增模板字段时，同步检查：

```bash
bash skills/skills-dever/scripts/audit.sh <generated-file>
```
