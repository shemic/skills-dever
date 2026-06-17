# 迁移

用这份规则把旧 Dever 项目或组件升级到当前 skill 约束，同时保持已有行为不被破坏。

## 项目升级

1. 安装或复制 `skills/skills-dever`。
2. 把 Dever managed block 加到 `AGENTS.md` / `CLAUDE.md` / 工具专属 agent 文件。
3. 如果缺少 `files/` 模板，补齐模板。
4. 先保证已有页面和 service 正常工作，不做批量删除。
5. 下一次修改具体功能时，只删除该功能里重复的 service/API/page 配置。
6. 在允许时运行静态 audit。

## Page JSON 升级

修改页面时：

- 补齐缺失的顶层 `page/layout/nodes/data/state/action`。
- 标准页能自动推导时，删除 `_model/_use/submit.use`。
- 把重复标签和选项移到 model comment、Options、Relations。
- 当 package/front 列表 action 已支持时，把 `status/sort` 从 update form 里移出。

除非用户明确要求迁移，否则不要一次性重写所有页面。

## Service/API 升级

修改 service/API 时：

- 删除空 passthrough Provider。
- 确认 page/front 已覆盖行为后，再删除 CRUD wrapper Service。
- 保留真实业务 Service。
- 如果 API 里包含业务逻辑，把 API 收薄，业务放到 Service。

## 组件升级

复杂组件：

- 增加 `package/<name>/skills/<name>/SKILL.md`。
- 组件 menu/auth/site 元数据逐步迁移到 `dever.json`。
- 组件 install/update 支持迁移前，保留旧的项目级 front 配置。
- 仍使用旧配置风格的项目，需要写清手动升级步骤。

## 资产升级

- 把 logo/favicon 移到 `config/front/assets/<site>/images`。
- 侧栏和加载态 logo 使用透明背景。
- favicon 可继续保留背景。
- 停止修改编译产物 `package/front/html`。
