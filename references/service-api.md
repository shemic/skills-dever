# Service、Provider 与 API

Service 是 Dever component 的业务实现层；Provider 和 API 是不同调用协议的适配入口。普通后台 CRUD 不需要三者。

## 1. 物理归属

```text
<component>/
  service/
    product.go
    release/
      publish.go
      package.go
  api/
    admin/
      release.go
```

- 核心业务、私有校验、映射、接口和实现都在 `service/` 或 `service/<domain>/`。
- Provider 写成 `service/**` 内接收者的 `ProviderXxx` 方法，不创建 `provider/` 目录。
- API 放 `api/**`，只做 HTTP 适配。
- 不创建 component 根级 `contract/`、`internal/`、`manager/` 或按业务动作命名的平行目录。

## 2. Service

Service 承载：

- 业务不变量和权限范围。
- 事务、状态流转、并发控制和幂等。
- 跨表查询/写入编排。
- 外部调用、超时、重试和回调处理。
- 安装、升级、签名、发布、导入、任务等业务流程。

普通业务方法不需要 Dever 生成器注册。API、Provider、CLI、middleware 或 Model hook 直接调用它们。

推荐普通签名使用 `context.Context + 明确参数`：

```go
type ReleaseService struct{}

func (ReleaseService) Publish(ctx context.Context, input PublishInput) (Release, error) {
    // 校验版本、签名和状态，并在一个事务内发布。
}
```

不要让核心方法直接依赖 `*server.Context`，否则 CLI、任务和测试会被 HTTP/runtime 上下文绑死。

### CRUD 方法名

`Create`、`List`、`GetInfo`、`Update`、`Delete` 不是禁用词。以下场景可以使用：

- 创建时生成/哈希凭据并只返回一次 secret。
- 根据身份和租户范围查询，并维护不可绕过的权限边界。
- 在事务中创建或更新多张表。
- 校验状态流转、唯一约束或业务默认值。
- 对接外部协议并保证幂等。

如果方法只把参数传给 Model 的同名 CRUD，没有额外业务不变量，它就是多余 wrapper，应删除并使用 Model + Page JSON。审查方法体语义，不根据名称直接定罪。

`HandleData`、`Process`、`DoWork` 等名字通常没有表达业务动作，应改成 `Publish`、`BindInstance`、`InstallRelease` 等意图名称。

## 3. Provider

Provider 是 Dever 动态调用适配方法，不是业务层。

### 生成器事实

当前 Service 生成器：

- 递归扫描 active module/package 的 `service/**`。
- 只识别导出接收者上的 `ProviderXxx` 方法，`Xxx` 不能为空。
- 普通 Service 方法不会自动注册。
- 注册名包含 `service/` 下的子目录。

例如：

```go
// package/crm/service/setting/customer.go
type CustomerHook struct{}

func (CustomerHook) ProviderBeforeSave(c *server.Context, params []any) any {
    // 适配 Page 参数后调用普通 Service。
}
```

注册名：

```text
crm.setting.CustomerHook.BeforeSave
```

Page hook：

```json
{
  "service": "crm.setting.CustomerHook.BeforeSave"
}
```

### 签名

Page hook 常用且已受 runtime 适配支持的签名：

```go
func (XxxHook) ProviderAction(c *server.Context, params []any) any
```

生成器只识别接收者和名称，不验证签名。使用其它签名前必须先确认 `dever/load` 注册适配支持，不能凭空发明。

### 允许职责

- Page before/after hook 的参数和返回值适配。
- 从登录态、站点、父页面或路由派生归属字段。
- 无法由 Model Options/Relations 提供的动态 option 适配。
- 调用普通 Service 并把错误转换成 runtime 期望的结果。
- 很小的边界校验或字段规范化。

### 禁止职责

- 原样返回输入的透传 Provider。
- 只为“统一入口”包装普通 CRUD。
- 在 Provider 内实现事务、长流程、HTTP client 或外部重试。
- 把普通 Service 方法全部改成 Provider 以便 Page 任意调用。

Provider 变长或需要多个入口复用时，提取普通 Service 方法，Provider 只保留适配。

## 4. API

API 只处理：

1. 用 `c.Input(...)` 读取和校验请求输入。
2. 提取登录、站点、租户或 API key 上下文。
3. 调用普通 Service 方法。
4. 返回 `c.JSON(...)` 或 `c.Error(...)`。

API 不写 SQL、事务、状态机、外部调用或跨表编排。

### 生成器事实

当前路由生成器递归扫描 active module/package 的 `api/**`，只识别接收者方法：

```text
GetXxx
PostXxx
PutXxx
DeleteXxx
```

路径由 component、api 子目录、接收者和动作生成：

```text
package/bot/api/admin/team.go
func (Team) GetWorkspaceData
-> GET /bot/admin/team/workspace_data
```

常见目录：

- `api/*.go`：不归属具体站点的通用接口。
- `api/admin/*.go`：后台自定义接口。
- `api/<site-or-scope>/*.go`：工作台、公开站点或独立协议。

需要站点保护时，在 `dever.json.front.sites.<site>.api` 声明对应前缀；公开路由必须在组件 `front.public` 或站点 `public` 中明确声明。

### 新增 API 的真实理由

- 登录、注册、OAuth/callback、webhook。
- 文件上传/下载或流式传输。
- 对外集成协议和 API key 边界。
- front plugin 需要的自定义交互接口。
- 无法由 Page 标准 action 表达的业务命令。

普通列表、详情、保存和删除不构成新增 API 的理由。

## 5. 调用方向

```text
Page standard action -> Model
Page hook            -> Provider -> Service
API                  -> Service
CLI / worker         -> Service
middleware           -> Service（需要业务判断时）
Model hook           -> Service（复杂生命周期时）
```

禁止反向依赖：Service 不依赖 API、Page JSON 或 front plugin；公共 runtime 不 import 业务 component。

## 6. 错误、事务和安全

- Service 返回业务可判断的错误；API/Provider 在边界处转换，不吞错。
- 事务覆盖完整业务不变量，不拆到多个适配入口。
- 外部调用设置超时；重试只用于幂等动作。
- webhook/callback 校验签名并保证幂等。
- 日志脱敏 password、token、secret、卡密、验证码和私钥。
- public route 仍执行输入校验、权限范围和字段过滤。

## 7. 自检

- 这是否只是普通 CRUD？如果是，回到 Model + Page JSON。
- 核心业务是否只有 `service/` 中一个实现。
- Provider 是否仅做动态适配，API 是否仅做 HTTP 适配。
- 是否误建了 Provider/contract/internal 或业务动作根目录。
- CRUD 方法是否有可指出的真实业务不变量。
- 注册名和 API 路由是否根据实际目录/生成器计算，而不是猜测。
