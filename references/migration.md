# 旧项目和旧组件增量迁移

旧项目迁移的目标是让后续改动逐步回到当前 Dever 规范，同时保持已有行为不被破坏。默认只迁移本次触达范围，不做全量重写。

## 1. 原则

- 保行为优先。已有页面、Service、API 能正常工作时，不因规范升级而整批删除。
- 小步迁移。改哪个功能，就清理哪个功能附近的重复配置和冗余代码。
- 删除前证明替代路径。确认 `package/front`、组件能力或真实业务 Service 已覆盖同等行为后再删除旧代码。
- 不使用空项目脚本覆盖已有项目。
- 不修改 `go.mod` module path。

## 2. 盘点清单

先只读盘点：

```bash
find . -maxdepth 3 -type f \( -name go.mod -o -name main.go -o -name '*.json' -o -name '*.jsonc' \)
find module package -maxdepth 4 -type f 2>/dev/null
```

重点看：

- `go.mod` 是否为 `module my`，是否有本地 `replace`。
- `main.go` 是否注册了 `data.RegisterRoutes` 和需要的 front site。
- `config/front.json(c)` 的 `sites/public/assets/access`。
- `module/*` 是否只是 package shim。
- page JSON 是否大量硬编码 `_model/_use/submit.use`。
- Service/API 是否只是 CRUD wrapper。
- 是否手改过生成文件或编译产物。
- 复杂 package 是否有 `dever.json.skills` 和组件 skill。

## 3. Page JSON 迁移

修改页面时：

- 补齐顶层 `page/layout/nodes/data/state/action`。
- 标准页能自动推导时，删除 `_model/_use/submit.use`。
- 把重复标签和选项移到 model comment、Options、Relations。
- `status/sort` 已由 package/front 列表 action 支持时，从 update form 移出。
- 左分类右列表改为本地数据容器刷新；只有确实要同步 URL 时才用 `meta.syncQuery`。
- 弹窗、抽屉、嵌入页补明确 `page.name`、`page.parent` 和 action 上下文。

除非用户明确要求，不一次性重写所有页面。

## 4. Service/API 迁移

修改 service/API 时：

- 保留真实业务 Service。
- 删除空 passthrough Provider。
- 确认 page/front 已覆盖行为后，再删除 CRUD wrapper Service。
- API 里有业务逻辑时，把 API 收薄，业务放到 Service。
- 外部调用补超时、密钥脱敏和幂等边界。

不要为了“规范化”把可运行的真实业务 Service 合并进 page JSON。

## 5. 组件迁移

复杂组件：

- 增加 `package/<name>/skills/<name>/SKILL.md`。
- 在 `dever.json.skills` 声明组件 skill。
- menu/auth/site/public/static 元数据逐步迁移到 `dever.json`。
- install/update 支持迁移前，保留旧的项目级 `front.json` 配置。
- 写清手动升级步骤，不让应用项目猜。

## 6. 资产迁移

- 把 logo/favicon 移到 `config/front/assets/<site>/images`。
- 侧栏和加载态 logo 使用透明背景。
- favicon 可以保留背景。
- 停止修改编译产物 `package/front/html`、`front/dist`、`package/*/front/dist`。

## 7. 禁止事项

- 不用 `scripts/boot.sh` 覆盖已有项目。
- 不批量删除旧 Service/API。
- 不批量重写全部 page JSON。
- 不为修权限临时开放通配权限。
- 不把旧项目私有逻辑挪进 `package/front` 或 `backend/dever`。
- 不为了通过 audit 去修改未触达的历史文件。
