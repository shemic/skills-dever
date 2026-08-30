# Skill 维护

维护 `skills/skills-dever`、`files/AGENTS.dever.md`、模板或 `scripts/audit.sh` 时使用本文件。目标是让规则有单一归属，并且能从当前源码验证。

## 1. 事实优先级

发生冲突时按以下顺序处理：

1. 当前 `backend/dever` 生成器和 runtime 源码。
2. 当前 `backend/package/front` 服务端 Page/action/option 实现与宿主 `front/src` schema/runtime。
3. 当前 component 的 `dever.json`、源码和组件 skill。
4. 当前 shemic-dever reference。
5. 历史 skill 和示例代码。

历史提交只能恢复仍然有效的结构和原则，不能整版 checkout。旧 Page 教程、旧命令或旧生成器与当前源码冲突时直接删除旧说法，不写兼容规范。

## 2. 文档归属

| 内容 | 唯一归属 |
| --- | --- |
| 角色路由、全局硬边界 | `SKILL.md` |
| 项目模式、归属、最低能力层 | `references/decide.md` |
| 目录、命名、职责、清理 | `references/development.md` |
| 产品资源、动作、页面拆解 | `references/product.md` |
| 应用项目实施 | `references/app.md` |
| 空项目和安装顺序 | `references/quickstart.md` |
| Model 协议 | `references/model.md` |
| Service/Provider/API | `references/service-api.md` |
| Page 任务入口 | `references/front-page.md`、`references/front-page/guide.md` |
| Page schema/action/option/field/site/template | `references/front-page/*.md` 对应专题 |
| front plugin | `references/front-plugin.md` |
| component/dever.json/组件 skill | `references/component.md` |
| CLI、生成器、framework/runtime | `references/framework.md` |
| 审查 | `references/review.md` |
| 安全 | `references/security.md` |
| 已验证故障模式 | `references/troubleshooting.md` |
| 可可靠静态判断的规则 | `scripts/audit.sh` |
| 确定性骨架 | `files/` 和对应脚本 |
| 组件私有事实 | 组件自己的 `skills/SKILL.md` |

不要因一条专项规则修改多个入口。`SKILL.md` 只在角色路由或全局硬边界变化时修改。

## 3. 源码核对位置

修改规则前先定位事实所有者：

| 契约 | 主要源码 |
| --- | --- |
| active module/package、shim | `backend/dever/util/module_source.go` |
| Model 扫描和注册名 | `backend/dever/cmd/model.go` |
| Provider 扫描和注册名 | `backend/dever/cmd/service.go`、`backend/dever/load` |
| API 扫描和路由 | `backend/dever/cmd/router.go` |
| component/dever.json/embed FS | `backend/dever/cmd/component.go`、component manifest 类型 |
| Page Model 推导 | `backend/package/front/service/page/model.go` |
| Page action/save/delete | `backend/package/front/service/action`、`service/page/action.go` |
| option 解析 | `backend/package/front/service/page/resolver.go`、`front/src/page/option.ts` |
| Page schema/action 类型 | `front/src/lib/schema.ts`、`front/src/lib/action.ts` |
| plugin 契约 | `front/src/lib/plugin` 和 component plugin 源码 |

不能从一个示例反推全局协议。复杂节点字段必须同时核对服务端 resolver 和客户端节点实现。

## 4. 加规则流程

1. 写清失败行为和真实风险，不从个人命名偏好出发。
2. 用 `rg` 搜索当前 skill 是否已有同义规则。
3. 按事实优先级核对源码、调用方和现有组件。
4. 区分全局协议、component 私有约定和历史坏结构。
5. 把规则写入唯一归属文档；入口只添加必要路由。
6. 能可靠静态判断时同步 audit；需要业务语义判断时只给可解释警告。
7. 同步受影响的模板和生成脚本。
8. 删除冲突、重复、失效引用和旧正向示例。

## 5. 审计分级

适合硬错误：

- 手改生成文件或编译产物。
- 明确旧 Page 协议。
- 缺少 Page 必需顶层结构。
- 明确非法的 component 根级业务目录。
- 可确定不存在的 Markdown 本地引用。

适合警告：

- `Create/List/GetInfo/Update/Delete` 等通用方法名。
- 多段下划线、父目录语义重复、泛化类型名。
- 可能是透传 Provider 或 CRUD API 的代码形态。

Shell/regex 无法证明方法是否维护业务不变量，不能把方法名警告升级成硬错误。

## 6. 文档与模板风格

- `SKILL.md` 保持薄入口；详细模式按需进入 reference。
- 规则写“什么时候选择什么、禁止什么、由谁承接”，不堆泛化教程。
- 示例只解释非显然协议，不复制完整项目。
- 不把历史问题列表写进所有文档；稳定结论写规范，排障过程留任务研究记录。
- 不新增重复 README、quick reference 或第二套 `.trellis/spec` 正文。
- 模板只生成当前协议和最低层骨架，不生成 Service/API/Provider 占位代码。

## 7. 必查一致性

检查 Markdown 本地引用：

```bash
bash skills/skills-dever/scripts/audit.sh skills/skills-dever
```

检查旧 Page 协议：

```bash
rg -n '_model|_use|modelPath|service@|transform|submit\.use|option\.use|childUse|/front/route/option' skills/skills-dever
```

允许命中禁止说明和 audit 规则，不能命中正向模板或正向示例。

检查业务层结论是否一致：

```bash
rg -n '业务.*service|Provider.*service|CRUD' skills/skills-dever/SKILL.md skills/skills-dever/references
```

检查 shell 和 skill 结构：

```bash
for file in skills/skills-dever/scripts/*.sh; do bash -n "$file"; done
python3 /root/.codex/skills/.system/skill-creator/scripts/quick_validate.py skills/skills-dever
```

修改 audit 时用项目根 `test/` 的最小夹具先观察失败，再实现并观察通过；一次性夹具在交付前删除。

## 8. 完成条件

- 所有链接可解析，入口能路由到新增 reference。
- 当前源码事实与文档、模板、audit 一致。
- 普通 CRUD 没有 Service/API/Provider 生成路径。
- 核心业务物理归属 `service/`，Provider 未被描述成目录或独立层。
- 方法名检查不会误把合法业务 CRUD 当作确定错误。
- 未修改 backend/package/front 业务源码来迎合文档。
