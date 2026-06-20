# 审查、排障和精简

`dever-review` 用于 bug、代码审查、安全、性能、精简和重构分析。目标是发现真实问题，不做低收益优化。

## 角色职责

- 先定位所属层：model、page JSON、Provider、Service、API、front plugin、component、framework。
- 读取对应源码、组件 skill 和相关 reference。
- 找根因，不靠放宽权限、硬编码 model/action、复制 package 代码修表面现象。
- 只报告真实存在或高概率存在的问题。
- 不推荐教科书式重构，不做风格洁癖。
- 宽范围重构、公共协议变化、数据库结构变化必须先给方案。

## 审查轮次

首轮审查先收敛完整问题清单，再建议修复。不要发现一个问题就停，也不要边修边扩大范围。

首轮必须完成：

- 写清审查范围：用户指定文件、已改文件、同组件相关 model/page/service/api/provider、`dever.json`、权限/public/站点配置。
- 涉及 create/update/page JSON 时，同时审查 form 节点、`data.form`、`action.submit.data`、model 字段、Options、Relations。
- 对每个问题模式用 `rg` 搜同组件或同层级是否还有同类写法；同根问题合并报告。
- 按审查清单过一遍 P0/P1 风险；P2 只报收益明确、和当前范围相关的问题。
- 范围外但可疑的问题只放“未覆盖/后续风险”，不要混进本轮结论。

修复后复审必须完成：

- 先复核首轮问题是否真的消失，再看修复 diff 引入的新风险。
- 复审范围包括修复文件、调用方/被调用方、相关 page/model/service/api/provider 和权限配置。
- 新问题必须标注来源：修复引入、首轮范围外、还是首轮漏审。若属于漏审，立即用同类模式再扫一遍，避免继续分批冒出。
- 不在复审中新增无关 P2；无关优化单独列为后续，不阻塞本轮收敛。

## 输出格式

代码审查必须按优先级分组：

```txt
P0（必须立即修复）
影响稳定性、安全性或数据正确性。

P1（建议尽快修复）
明显风险、维护成本高、容易继续引入错误。

P2（可择机优化）
收益明确的质量、性能或可维护性改进。
```

每次审查先写：

```txt
审查范围
未覆盖/后续风险
```

每个问题必须包含：

```txt
文件路径
代码位置
问题描述
风险分析
修改建议
预估收益
```

没有发现问题时，明确说明“无需优化”，并说明剩余风险或未覆盖范围。复审发现新增问题时，必须写明新增问题来源。

## 审查清单

### 代码结构

- 是否创建了平行实现。
- 是否有重复业务逻辑。
- 是否有 `Xxx2/XxxNew/XxxEx/XxxV2`。
- 是否有无意义 `Helper/Manager/Util/Base/Interface`。
- 是否有巨大函数、巨大文件、混合职责。
- 是否把组件私有逻辑放进 `package/front`。

### Dever 分层

- 普通 CRUD 是否错误新增 API/Service。
- Provider 是否只是透传。
- Service 是否只是 CRUD wrapper。
- API 是否内联业务流程。
- page JSON 是否承担了状态流转、事务或外部调用。
- front plugin 是否替代了 page JSON 能力。

### 冗余和过度工程

- 新增层级是否有明确业务不变量；没有就回退到更低能力层。
- 是否为了单个调用点创建 interface、factory、manager、base class 或 helper。
- 是否存在双路径兼容、备用实现或旧协议适配分支。
- 是否把同一字段标签、Options、Relations、option 或权限配置写在多个地方。
- 是否因为“以后可能扩展”增加配置、抽象、Service/API 或 front plugin。
- 是否能删除代码而不丢失当前需求、安全校验、权限、错误处理或事务边界。

### Front Page

- 是否缺六个顶层对象。
- 是否使用旧协议字段。
- 是否能自动推导却硬编码 model/service。
- create/update 页是否把系统字段、审计字段、派生字段或分类名做成手填。
- `data.form` 是否机械搬入整张表字段，而不是当前表单字段。
- 固定少量单选枚举是否误用了 `form-select`；2-4 个固定选项优先 `form-radio`。
- `action.submit.data` 是否破坏 partial save。
- `action.submit.data` 是否提交 `created_at/updated_at/created_by/updated_by/author_id/editor_id/operator_id` 或服务端生成的 `code/key/slug/sn/no`。
- option 是否能从 Options/Relations 推导。
- `option.model` 和 `option.service` 是否互斥。
- 分类、类型、分组是否用 Options/Relations/category，而不是自由输入。
- 作者、编辑、创建人、更新人是否只展示或由服务端写入；真实负责人/指派人是否使用业务字段名。
- 是否手写 `/front/route/option` 或 `/front/route/action`。
- `page.parent/auth/public` 是否正确。

### 安全

- public route 是否显式且必要。
- 是否绕过 site access、RBAC、登录或 API key 范围。
- 是否泄露 secret、token、password、API key。
- 上传是否有大小、类型、路径和权限限制。
- 外部 URL/import 是否有 SSRF、超时、大小限制。
- webhook/callback 是否有签名、幂等和脱敏日志。

### 性能

- 列表是否分页。
- 是否有明显 N+1。
- 是否重复查询相同数据。
- 是否不必要地加载大对象或全表。
- 是否频繁 IO、无缓存或缓存失效不一致。
- 是否在请求路径中做阻塞外部调用且无超时。

## 处理原则

- P0 优先于任何重构。
- P1 只处理真实风险或高维护成本。
- P2 只处理收益明确的问题。
- 首轮先完整盘点再修复；同根问题合并，避免多轮挤牙膏。
- 发现重复模式时优先修公共路径，但不要扩大到无关范围。
- 精简建议必须说明删除后由哪个现有层级或公共路径承接。
- 用户禁止 build/test 时，不运行 build/test。

## 静态检查

可运行：

```bash
bash skills/skills-dever/scripts/audit.sh --changed
```

或检查指定文件/目录。`audit.sh` 是静态约束检查，不替代人工审查。
