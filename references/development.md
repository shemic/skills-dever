# Dever 开发规范

本文件定义 Dever 业务代码的物理归属、命名和实现质量。Model、Page、Provider、API 的协议细节由各自 reference 维护。

## 1. 业务代码归属

所有核心业务实现必须放在 component 的 `service/` 下：

- 业务校验和不变量。
- 状态流转、事务和幂等。
- 跨表查询与写入编排。
- 外部系统调用、重试和超时。
- 导入、导出、任务、安装、升级、签名、发布等业务流程。
- 为上述流程服务的私有类型、接口、转换和校验。

小领域可以直接放 `service/*.go`；同一稳定领域出现多个文件时收进 `service/<domain>/`。不要为一两个函数创建微目录。

```text
service/
  release.go
  client/
    check.go
    download.go
    install.go
  release/
    publish.go
    package.go
```

不要把业务拆成 component 根级目录：

```text
contract/
internal/
manager/
helper/
installer/
updater/
serveridentity/
serverdeploy/
```

这些名字如果表达真实业务域，改成 `service/<domain>`；如果只是一个 helper，与调用它的 Service 同文件或同包放置。

## 2. 适配层边界

| 目录/入口 | 允许职责 | 禁止职责 |
| --- | --- | --- |
| `model/` | 表结构、索引、Options、Relations、轻量生命周期适配 | HTTP、外部调用、长业务流程 |
| `service/` | 所有核心业务行为 | HTTP 响应格式、Page 节点配置 |
| `api/` | 取参、鉴权上下文、调用 Service、返回 HTTP | SQL、事务、状态流转、外部调用 |
| Provider 方法 | 动态调用参数/结果适配、Page hook、option 适配 | 独立业务实现、空透传 |
| `middleware/` | 请求链装配、通用访问控制 | 复制业务判断和数据流程 |
| `cmd/` | 参数解析、进程生命周期、调用 Service | 安装/升级/任务核心流程 |
| Model hook | 数据生命周期入口、调用 Service | 跨表长流程和外部调用 |
| front plugin | Page 无法表达的客户端交互 | 后端业务规则和权限决策 |

适配层可以做边界校验，但业务规则只有一个实现，放在 Service 并被所有入口复用。

## 3. 文件和目录命名

- Go 文件名使用小写 snake_case，表达一个明确业务主题。
- 一个或两个业务词很正常；出现多段下划线时先检查文件是否混合职责。
- 目录已经提供的上下文不在文件名重复。例如 `service/client/download.go`，不要写 `client_download_service.go`。
- 同一业务域已有子目录时，新文件继续放该目录，不在 `service/` 根创建平行版本。
- 不使用 `service_`、`runtime_`、`common_` 等实现前缀掩盖归属不清。
- 不创建 `Xxx2`、`XxxNew`、`XxxEx`、`XxxV2`；替换旧实现时迁移调用方并删除旧实现。
- 不把业务放进 `helper.go`、`utils.go`、`common.go`、`manager.go`、`value.go` 等桶文件。

文件名是审查信号，不是机械长度竞赛。合法资源名可以包含多个业务词；关键是一个文件有一个清晰主题。

## 4. 类型和方法命名

- package/目录已经表达语义时，类型名不重复 package stutter。例如 `client.Installer`，不要写 `client.ClientInstaller`。
- `Service` 后缀只给真实业务入口；没有业务行为的结构体不要命名为 Service。
- `Hook` 用于一组真实生命周期或 Page 适配方法，不创建空 Hook。
- 请求、结果、选项等类型靠近拥有它们的 Service 或适配入口，不创建全局 DTO/contract 层。
- 接口放在需要替换实现的消费方附近；只有存在多个实现或稳定外部边界时才创建，不为单实现包装。

普通 Service 方法表达业务动作，例如：

```text
Publish
Approve
Archive
RotateToken
InstallRelease
BindInstance
SyncRelations
```

`Create`、`List`、`GetInfo`、`Update`、`Delete` 可以用于真实业务用例。判断标准不是名字，而是方法是否维护业务不变量、权限、事务、派生凭据、跨表一致性或外部协议。只转调 Model CRUD 的方法应删除，让 Model + Page JSON 处理。

框架协议名保持完整：

- Model：`New<Resource>Model`。
- Provider：`Provider<Action>`。
- API：`Get/Post/Put/Delete<Action>`。

不要为了缩短名字破坏生成器协议。

## 5. 函数结构

- 函数只承担一个可命名职责；验证、持久化、转换和副作用不要混成巨型过程。
- 优先早返回，避免深层嵌套。
- 编排函数保持可读顺序，复杂细节拆成同领域私有函数。
- 不写只调用一次且不提升意图的单行 wrapper。
- 同一转换、校验或查询出现第二次时检查是否应收敛；第三次必须有单一实现。
- 同一流程只因类型/状态不同而分支时，优先使用明确映射或小型 dispatch，不堆重复 if/switch。

不要为了减少行数创建 BaseService、Manager、抽象父类或泛型框架。

## 6. Service 契约

- 普通业务方法优先接收 `context.Context` 和明确参数，不直接依赖 HTTP 请求对象。
- Provider/API 从 `*server.Context` 提取必要上下文后调用普通 Service 方法。
- Service 返回明确结果和 `error`；Provider 再适配成 runtime 所需返回形态。
- 事务边界由拥有完整业务不变量的 Service 方法控制，不分散在 API/Provider。
- 状态流转校验当前状态和目标状态，并通过数据库约束、事务、锁或幂等键保证并发正确性。
- 外部调用必须有超时；重试只用于幂等操作；日志不得包含密码、token、卡密、验证码、私钥或完整敏感响应。
- 列表和批量操作必须有边界、索引和分页，避免 N+1 和无条件全表加载。

## 7. Model 与 Service 的边界

Model wrapper 和生命周期方法是 runtime 支持的适配入口，不是第二个 Service 层：

- 简单字段规范化或与单条记录紧密相关的生命周期适配可以留在 Model hook。
- 需要跨表事务、外部调用、状态流转或多入口复用时，Model hook 调用 Service。
- 不在 Model 中复制 Service 的业务规则。

Model 的 Options、Relations、comment 和索引是数据契约，优先由 Page runtime 复用。

## 8. 配置和常量

- 配置只保存环境或部署差异，不保存可建模的业务数据。
- 业务枚举优先放 Model Options；不会随部署变化的值不要做环境变量。
- 同一常量只有一个定义点，不在 API、Service 和 Page 各复制一份。
- 不引入 feature flag、缓存、队列、Provider registry 或策略体系，除非当前需求确实需要且已有框架能力不足。

## 9. 清理要求

每次实现后删除：

- 未使用的函数、类型、变量、import、文件和目录。
- 调试打印、临时日志、实验分支、注释掉的旧代码和无主 TODO。
- 被新路径替代的 wrapper、alias、旧配置、旧模板和重复查询。
- 只有一个小文件且没有独立职责的微目录。

保留的抽象必须消除真实重复、稳定公共契约、隐藏真实复杂度或明确业务概念；否则合并回直接实现。

## 10. 验证

- 测试统一放当前仓库根目录 `test/`；一次性验证完成后删除。
- 不为测试暴露生产内部 API。
- 先运行语法、静态检查和最小定向测试，再根据风险决定更大验证。
- 不手改生成文件或编译产物来让检查通过。
- 用户或项目禁止 build/test 时，明确记录未运行项，不能绕过限制。

审查时继续读 [review.md](review.md)；具体 Service/Provider/API 协议读 [service-api.md](service-api.md)。
