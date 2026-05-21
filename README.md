# shemic-dever

Dever Go 项目开发 skill。目标是简单、稳定、和真实框架一致。

## 目录

- `SKILL.md`：入口规则。
- `references/workflow.md`：统一工作流。
- `references/development.md`：通用开发规范、复用、职责、命名、清理。
- `references/framework.md`：Dever 入口、命令、生成文件、路由、Load 注册。
- `references/model.md`：Model 文件、字段、Options、Relations、索引。
- `references/module.md`：Service、Provider、API、middleware。
- `references/page.md`：`package/front` 后台 page JSON。
- `scripts/boot.sh`：补齐最小 Dever 项目骨架。
- `scripts/module.sh`：默认只生成 model；可选 `--provider` / `--api`。
- `scripts/audit.sh`：静态检查常见 Dever skill 错误。
- `files/gitignore`：Dever 项目 `.gitignore` 模板。

## 使用

对 AI 说：

```text
使用 shemic-dever skill，按当前项目状态继续开发。
```

后台页面、普通 CRUD、admin 默认使用：

```txt
Model + package/front + page JSON
```

不要默认写 CRUD API/Service。

## 常用命令

```bash
bash skills/skills-dever/scripts/boot.sh my main my-app 8082
bash skills/skills-dever/scripts/module.sh user profile
bash skills/skills-dever/scripts/module.sh order order --provider
bash skills/skills-dever/scripts/audit.sh module/profile/model module/profile/page
```

日常开发：

```bash
dever run
```

发布构建：

```bash
dever build
```

如果用户要求不跑 build/test，就不要跑。
