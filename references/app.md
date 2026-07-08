# 应用开发

本文件用于普通 Dever 应用项目：业务 module、model、后台页面、少量业务 Service/API、项目配置。

## 先判定归属

- 业务代码放 `module/<name>`。
- `module/<name>/main.go` 只有 `// dever:import github.com/dever-package/<name>` 时，真实源码来自 package；不要在 shim 里写业务代码。
- 普通应用开发不要改 `backend/dever`、`backend/package/*` 或复制 package 源码。
- 当前 `/data/project/shemic/backend` 是框架/package 开发态，允许维护本地 `backend/dever` 和 `backend/package/*`，但外部新项目不应照搬本地 replace。

## 能力选择

| 需求 | 优先使用 | 不要使用 |
| --- | --- | --- |
| 普通列表/新增/编辑/删除/详情 | Model + page JSON | CRUD API/Service |
| 标签、枚举、关联选项 | Model comment / Options / Relations | page JSON 重复硬编码 |
| 保存前规范化或单表校验 | Provider hook | API 内联逻辑 |
| 保存后关系同步、计数、缓存失效 | Provider hook 或聚焦 Service | 空 Provider |
| 状态流转、事务、外部调用、异步任务 | Service | 直接 page action 更新状态 |
| 登录、注册、回调、插件交互接口 | API + Service | 泛化 CRUD action |
| 画布、编辑器、CRM 工作台等强交互 | front plugin | 巨型 page JSON |

优先选择能满足需求的最低层级。

## 最小可维护实现阶梯

最小不是最少行数，而是最少不必要层级、最少重复、最少平行实现。新增代码前按顺序停在第一个能满足需求的层级：

1. 现有 model、page、service、api、provider 或组件扩展点能复用，先复用或小幅扩展。
2. Model comment、Options、Relations、索引、默认排序能表达，就不要在 page JSON 重复硬编码。
3. page JSON 和 package/front 标准 action 能表达，就不要写 Provider。
4. Provider hook 或 `submit.before/after` 能表达，就不要写 API。
5. 只有事务、状态流转、外部调用、异步编排、跨表规则才写 Service。
6. API 只在需要 HTTP 边界、登录/站点/API key 上下文或 front plugin 自定义接口时出现。
7. front plugin 只处理 page JSON 无法表达的复杂交互；framework/package 只处理公共 runtime 问题。

不能用“以后可能扩展”“先留个接口”“方便统一”作为升层理由。安全校验、权限、错误处理、事务边界和脱敏日志不能为了少写代码省略。

## 实现流程

1. 先搜索同类 model、page、service、api、provider、组件 skill。
2. 持久化资源先写 model：字段、comment、Options、Relations、索引、默认排序。
3. 普通后台写 page JSON，标准路径交给 front 自动推导 model。
4. 真实业务流程再写 Service，API 只做请求适配。
5. 改 model/service/api 后让 `dever run` 或 `dever init --skip-tidy` 刷新生成文件；不要手改生成文件。

## 自检

编写前后确认：

- 改动是否在最低能力层（model > page JSON > Provider > Service > API > front plugin）。
- 是否新增了不必要的 Service/API、空 Provider、CRUD wrapper 或平行实现。
- 是否手改了生成文件、编译产物或使用了旧 page 协议。
- Model 元信息（Options/Relations）是否能替代 page JSON 中的重复配置。
- 是否影响组件权限、public route 或 `package/front` 通用 runtime。

不确定时优先复用现有实现，不创建平行版本。必要时运行 `bash skills/skills-dever/scripts/audit.sh <changed-file-or-dir>` 静态检查。

## 空项目

空项目固定 `module my`。不要按项目名、域名或目录名改 Go module。

从零开始先读 `references/quickstart.md`。本节只记录应用侧边界。

最小骨架来自 `files/`：

```txt
go.mod
main.go
config/setting.jsonc
data/readme.txt
module/front/main.go
module/bot/main.go
```

引入 package 使用：

```bash
dever package front
dever package bot
dever package
```

`dever package <name>` 会安装或更新单个 `github.com/dever-package/<name>@latest`、写入 `module/<name>/main.go` shim，并刷新注册文件。`dever package` 会更新当前项目已启用的全部 package。普通项目不保留 `package/<name>` 源码。

普通项目默认使用稳定版本，不追 main。维护 package 或验证未发布提交时才使用：

```bash
dever package front --ref=main
dever package front --ref=v0.1.1
```

`scripts/boot.sh` 只用于空项目；已有项目不要用它覆盖骨架。

## 代码质量

- 先复用，再新增；不要创建平行实现。
- 不创建 `Xxx2`、`XxxNew`、`XxxEx`、`XxxV2`。
- 不创建无意义 `Helper`、`Manager`、`Util`、单实现 interface 或空 Base 类。
- 同一流程第二次出现就考虑抽函数/配置；第三次必须抽公共路径。
- 函数保持单一职责，优先早返回，避免深层嵌套。
- 名字表达业务意图，不用 `data/item/thing/handleData/processThing`。
- 抽象必须消除真实重复、降低分支复杂度或稳定公共契约；否则保留直观实现。
