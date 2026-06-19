# Skill 维护

维护 `skills/skills-dever` 时使用本文件。目标是让核心入口稳定，新增规则有固定归属。

## 不动核心入口

不要因为新增一条 page 规则就改 `AGENTS.dever.md` 或 `SKILL.md`。

只在以下情况修改核心入口：

- 新增一级角色。
- 改变角色路由。
- 新增全局硬边界。
- skill 安装/读取机制变化。

## 新规则归属

| 新规则类型 | 放置位置 |
| --- | --- |
| Dever 应用判断、业务边界 | `references/app.md` |
| model 命名、Options、Relations | `references/model.md` |
| Provider/Service/API 边界 | `references/service-api.md` |
| page 当前协议、旧字段禁止 | `references/front-page/protocol.md` |
| action、submit、partial、hook | `references/front-page/action.md` |
| option、meta、Relations/Options | `references/front-page/option.md` |
| site、auth、public、shell、plugin 自动发现 | `references/front-page/site.md` |
| 服务端模板、SEO | `references/front-page/template.md` |
| front plugin | `references/front-plugin.md` |
| package/module/dever.json/组件 skill | `references/component.md` |
| CLI、生成器、run/build/package/skill install | `references/framework.md` |
| 安全 | `references/security.md` |
| bug 经验 | `references/troubleshooting.md` |
| 可机器检查规则 | `scripts/audit.sh` |
| 生成骨架 | `files/` 和对应 `scripts/*.sh` |
| 组件私有规则 | 组件自己的 `skills/SKILL.md` |

## 加规则流程

1. 先确认是框架/runtime 行为，还是组件业务约定。
2. 能用代码或 audit 防住的，不只写文档。
3. 用 `rg` 搜索是否已有同义规则，避免重复和冲突。
4. 每条规则写清“禁止什么”和“推荐什么”。
5. 模板、脚本、reference 必须一致。
6. 删除旧写法时不保留兼容分支，除非用户明确要求迁移期。

## 文档风格

- 入口短，reference 按需读。
- 不写长教程，不堆历史说明。
- 少量必要示例即可。
- 不把组件私有行为写成全局规则。
- 不把可 regex 检查的问题只写成自然语言。

## 必查一致性

维护完成后至少静态检查：

```bash
rg -n "<本次删除的入口名>" skills/skills-dever
rg -n "_model|_use|modelPath|service@|transform|submit.use|option.use|childUse|/front/route/option" skills/skills-dever
```

第二条允许出现在“禁止旧写法”的说明和 audit 中，不能出现在模板生成内容中。
