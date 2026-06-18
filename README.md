# shemic-dever

`shemic-dever` 是 Dever 项目的 AI 开发约束 skill。它的核心目标不是让 AI “多写代码”，而是让 AI 按 Dever 框架已有能力做事：

- 普通后台 CRUD 走 `Model + package/front + page JSON`。
- 真实业务流程才写 Provider / Service / API。
- 复杂前端交互才写 package/module front 插件。
- 配置、logo、favicon、AGENTS 提示、标准 page 骨架走 `files/` 模板。
- 修改复杂组件前先读组件自己的 skill。

这套约束的重点是减少随意 Service/API、复杂 page JSON、编译产物改动和重复实现。

## 目录结构

```txt
skills/skills-dever/
  SKILL.md
  README.md
  references/
    workflow.md
    product.md
    framework.md
    development.md
    model.md
    front-page-quick.md
    front-page.md
    template-page.md
    service-api.md
    files.md
    component.md
    package-plugin.md
    security.md
    troubleshooting.md
  scripts/
    audit.sh
    boot.sh
    module.sh
    page.sh
    component-skill.sh
  files/
    gitignore
    AGENTS.dever.md
    config/
    go/
    page/
    component/
```

`SKILL.md` 是 AI 入口，只放硬规则和阅读顺序。
`references/` 是按任务读取的详细规范。
`scripts/` 只做确定性校验和最小骨架生成。
`files/` 是配置、静态资源、page 骨架、组件 skill 的模板中心。

## 安装

`github.com/shemic/skills-dever` 是 `shemic-dever` 的唯一源。Dever 框架不维护第二份完整 skill 副本，避免版本漂移。

首次手动安装：

```bash
tmp="$(mktemp -d)"
git clone --depth 1 --branch main https://github.com/shemic/skills-dever.git "$tmp/skills-dever"
rm -rf ~/.agents/skills/shemic-dever
mkdir -p ~/.agents/skills
cp -a "$tmp/skills-dever/." ~/.agents/skills/shemic-dever
for target in \
  ~/.codex/skills/shemic-dever \
  ~/.claude/skills/shemic-dever \
  ~/.opencode/skills/shemic-dever \
  ~/.trae/skills/shemic-dever \
  ~/.qoder/skills/shemic-dever \
  ~/.codebuddy/skills/shemic-dever
do
  rm -rf "$target"
  mkdir -p "$(dirname "$target")"
  ln -s ~/.agents/skills/shemic-dever "$target"
done
rm -rf "$tmp"
```

Dever CLI 已提供：

```bash
dever skill install         # 每次从 github.com/shemic/skills-dever 临时拉取并同步
dever skill doctor
dever install              # 默认调用 dever skill install，同步全局 skill 和 agent 提示
dever install --skip-skills
```

`dever skill install` 做三件事：

1. 每次按 `--repo` 和 `--ref` 从 `github.com/shemic/skills-dever` 拉取临时副本；不读取项目本地 skill、不读取已安装全局 skill、不使用缓存或备用来源。
2. 把真实 skill 同步到 `~/.agents/skills/shemic-dever`，再为 Codex、Claude、OpenCode、Trae、Qoder、CodeBuddy 等常见工具 skill 目录创建 symlink 引用。
3. 用 `files/AGENTS.dever.md` 的 managed block 更新 `AGENTS.md`、`CLAUDE.md`、`.codex/AGENTS.md`、`.opencode/AGENTS.md`、`.trae/AGENTS.md`、`.qoder/AGENTS.md`、`.codebuddy/AGENTS.md`，不覆盖用户原内容。

默认不复制项目本地 `skills/skills-dever` 镜像。只有确实需要项目副本时才显式执行：

```bash
dever skill install --project=true
```

`dever skill doctor` 检查：

1. 项目 agent 提示文件是否包含 Dever managed block。
2. active module/package 的 `dever.json.skills` 是否指向真实组件 skill 文件。
3. `~/.agents/skills/shemic-dever` 是否完整。
4. 常见工具 skill 目录是否是指向 `~/.agents/skills/shemic-dever` 的 symlink 引用。

`dever install` 默认会执行 `dever skill install`，可用 `--skip-skills` 跳过。

## 参考顺序

不确定实现时，按当前项目源码优先：

1. 当前 `package/front`
2. 当前 `package/bot`
3. 当前 `package/user`
4. 当前项目已有 `package/*` / `module/*`
5. 当前 `backend/dever`
6. 外部 demo 只作为补充参考

不要默认先看 demo。当前项目代码才是事实来源。

## 按任务读取

| 任务 | 必读 |
| --- | --- |
| 空项目、新后台、新站点 | `SKILL.md`、`workflow.md`、`empty-project.md`、`files.md` |
| 新产品或业务模块 | `SKILL.md`、`workflow.md`、`product.md`、`model.md`、`front-page-quick.md` |
| 后台 CRUD | `SKILL.md`、`front-page-quick.md`、`model.md` |
| 复杂 page JSON、左分类右列表、弹窗、内联编辑 | `SKILL.md`、`front-page-quick.md`、`front-page.md` |
| 服务端模板、SEO、公开内容站 | `SKILL.md`、`front-page-quick.md`、`template-page.md`、`security.md` |
| 状态流转、跨表事务、外部调用 | `SKILL.md`、`service-api.md`、`security.md` |
| 组件维护 | `SKILL.md`、`component.md`、组件自己的 `skills/**/SKILL.md` |
| Dever 框架维护 | `SKILL.md`、`framework.md`、`troubleshooting.md` |

## 后台页面开发

普通后台页面流程：

1. 写或检查 model。
2. 把字段注释、Options、Relations 写进 model。
3. 写 `front/page/<site>/<resource>/list.json`。
4. 写 `front/page/<site>/<resource>/update.json`。
5. 让标准 page path 自动推导 model。

普通 CRUD 先按 `references/front-page-quick.md` 写；遇到左分类右列表、嵌入弹窗、内联编辑、站点壳或复杂权限上下文，再读 `references/front-page.md`。

禁止为了普通 CRUD 新增：

- CRUD API
- CRUD Service
- 空 Provider
- `submit.use`
- `_model`
- `_use`
- `<<NewXxxModel>>`
- `{{Service}}`
- `type: "service"`
- `option.use`
- `/front/route/option`
- `childUse`
- `modelName`

状态、排序等列表维护字段优先使用 package/front 标准列表动作。

## Provider、Service 和 API 决策

| 场景 | 应该用 |
| --- | --- |
| 普通增删改查 | Model + page JSON |
| 标签/选项/关联 | Model comments / Options / Relations |
| 保存前规范化/校验 | ProviderBeforeSave |
| 保存后同步/缓存失效 | ProviderAfterSave 或 Service |
| 跨表事务 | Service |
| 状态流转 | Service |
| 外部接口调用 | Service |
| 登录注册/回调/自定义前端交互 | API + Service |

Service 方法必须表达业务行为，不写 `Save/List/Create/Update/Delete` 这种 CRUD wrapper。

## 配置、logo、favicon

模板来源：

```txt
files/config/setting.jsonc.tmpl
files/config/front/assets/<site>/images/logo.svg
files/config/front/assets/<site>/images/favicon.svg
```

规则：

- `logo.svg` 默认透明背景，用于侧栏和加载态。
- `favicon.svg` 可以带背景。
- 不改 `package/front/front/html/assets/index*.js`。
- 不改 `front/dist`。
- 站点展示配置放组件 `dever.json.front.sites.<site>.config`，项目覆盖放 `config/front.json.sites.<site>`。
- 资源使用 `config/assets/...` 或 `<component>/assets/...` 显式引用。

## 脚本

### `scripts/boot.sh`

初始化最小 Dever 项目骨架：

```bash
bash skills/skills-dever/scripts/boot.sh my my-app 8082
```

它会生成：

- `go.mod`
- `main.go`，包含 `frontsite.Register`
- `config/setting.jsonc`
- `config/front/assets/admin/images/*`
- `config/front/assets/work/images/*`
- `module/front/main.go`
- `module/bot/main.go`
- `middleware/readme.txt`
- `data/readme.txt`
- `package/readme.txt`

它不会生成业务 API 或 Service。
`boot.sh` 只用于空项目；检测到已有项目时会拒绝执行。确实要给已有项目补齐骨架时，显式加 `--adopt-existing`。
`go.mod` 来自 `files/go/go.mod.tmpl`，是正式项目模板，不包含本地 `replace github.com/shemic/dever => ./dever`。
`boot.sh` 会执行 `go get github.com/shemic/dever@main`，把当前 main 对应的真实版本写入 `go.mod` / `go.sum`。

### `scripts/module.sh`

只生成 model 骨架：

```bash
bash skills/skills-dever/scripts/module.sh demo product
```

它故意不支持 `--provider` / `--api`。Provider/API/Service 必须人工按 `references/service-api.md` 判断后再写。

### `scripts/page.sh`

生成标准 page JSON 骨架：

```bash
bash skills/skills-dever/scripts/page.sh module/demo admin product list 产品 --parent=product-center
bash skills/skills-dever/scripts/page.sh module/demo admin product update 产品
```

生成的标准页面使用 model 自动推导，不写 Service/API。`list` 页必须显式传 `--parent=<menu_key>`，避免权限同步把页面错误放到顶层菜单；`update/detail` 页默认把 `page.parent` 指向同资源 list route。

### `scripts/component-skill.sh`

生成组件 skill 骨架：

```bash
bash skills/skills-dever/scripts/component-skill.sh package bot Bot
bash skills/skills-dever/scripts/component-skill.sh package user User
```

复杂组件必须带自己的 skill，例如：

```txt
package/bot/skills/bot/SKILL.md
package/user/skills/user/SKILL.md
```

组件要在 `dever.json` 声明 skill，路径必须相对组件目录：

```json
{
  "skills": [
    "skills/bot/SKILL.md"
  ]
}
```

`dever skill doctor` 会检查 active 组件里的这些路径，防止以后组件搬迁或升级时丢掉开发约束。

### `scripts/audit.sh`

静态检查常见反模式：

```bash
bash skills/skills-dever/scripts/audit.sh --changed
bash skills/skills-dever/scripts/audit.sh package/bot module/work
```

检查内容包括：

- 手改生成文件。
- 手改编译产物。
- 标准 page 硬编码 model。
- 标准 page 缺少 `page.parent`。
- 标准 update/create 缺少最小 `action.submit`。
- 标准 list 使用内联编辑但缺少 `show-table.meta.savePath` 或显式 `action.change`。
- 禁止手写字符串 option URL：`/front/route/option`。
- `optionParams` 塞入 `parentField`、`valueField`、`labelField`、`extraFields`、`pageSize`、`order` 等静态 option 配置。
- page JSON 缺顶层对象。
- 硬编码 `/front/route/action`。
- 空 Provider。
- CRUD wrapper Service/API。
- model 文件命名问题。
- `longtext` 使用问题。

推荐日常使用 `--changed` 只检查本次改动文件。直接传文件或目录时，所有禁止项都会按错误处理。它不是 build/test，不会启动项目。

## 组件规则

`package` 和 `module` 都按组件看待：

- `package` 是可复用组件。
- `module` 是项目业务组件或 package shim。
- `module/<name>/main.go` 只有 `// dever:import my/package/<name>` 时，真实代码在 package。

复杂组件规则放组件内，不塞进全局 skill：

```txt
package/<name>/skills/<name>/SKILL.md
```

修改组件前先读组件 skill。

## 不要做的事

- 不手改 `data/router.go`、`data/load/*.go`、`data/table/*.json`。
- 不手改 `package/front/front/html/assets/index*.js`。
- 不为禁止字段保留适配代码，不保留双路径备用实现。
- 不为普通 CRUD 写 API/Service。
- 不生成空 Provider。
- 不把复杂业务塞进 page JSON。
- 不在 page JSON 里硬编码模型、route/action URL。
- 不把组件业务规则塞进全局 `shemic-dever`。
- 不把真实密钥写进模板或源码。

## 维护原则

每次更新这个 skill，都要检查：

- `SKILL.md` 是否仍然短而硬。
- 详细说明是否放进了 `references/`。
- 可复制文件是否放进了 `files/`。
- 脚本是否只做确定性工作。
- 是否减少了 AI 自由发挥空间。
