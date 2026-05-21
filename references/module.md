# Service / Provider / API 规则

后台普通 CRUD 不写 API，不默认写 Service。只有真实业务规则才写。

## 1. 什么时候写 Service

写 Service 的情况：

- 状态流转需要校验当前状态。
- 保存前要规范化数据或跨表保存。
- 删除前要检查子记录、权限或状态。
- 列表要聚合统计、批量补充字段。
- 导入导出要转换数据。
- 外部协议、回调、签名、轮询、异步任务。

不写 Service 的情况：

- 普通新增、编辑、删除。
- 普通列表、分页、搜索。
- 普通枚举和关联 option。
- 只为了“每个 model 都有 service”。

## 2. Service 写法

- 核心方法用 `context.Context + 明确参数`。
- Service 承载业务规则、事务、状态流转。
- API、Provider、worker 只做适配。
- 不创建无意义 interface、manager、helper、base service。
- 先复用 `dever/util`、现有 model/service/provider。

```go
type OrderService struct{}

func (OrderService) Cancel(ctx context.Context, id uint64, reason string) error {
    if id == 0 {
        return errors.New("订单ID不能为空")
    }
    // 查询、校验状态、事务更新
    return nil
}
```

## 3. Provider

Provider 给 `Dever.Load` 和 page JSON 调用。

```go
type OrderHook struct{}

func (OrderHook) ProviderBeforeSaveOrder(c *server.Context, params []any) any {
    record, _ := params[0].(map[string]any)
    return record
}
```

注册名由生成规则得到：

```txt
<module>[.<service子目录>].<Receiver>.ProviderBeforeSaveOrder
```

不要手写 `data/load/service.go`。

Provider 常见用途：

- `ProviderBeforeSaveXxx`
- `ProviderAfterSaveXxx`
- `ProviderBeforeDeleteXxx`
- `ProviderLoadXxxOptions`
- `ProviderLoadXxxData`
- `ProviderBuildXxxRows`

## 4. API

API 只用于非后台 CRUD 的 HTTP 能力。

```go
type Order struct{}

func (Order) PostCancel(c *server.Context) error {
    id := util.ToUint64(c.Input("id", "required", "订单ID"))
    reason := c.Input("reason")
    if err := (service.OrderService{}).Cancel(c.Context(), id, reason); err != nil {
        return c.Error(err)
    }
    return c.JSON(map[string]any{"id": id})
}
```

规则：

- receiver 是资源名。
- 方法名前缀只用 `Get/Post/Put/Delete`。
- 入参统一 `c.Input(...)` 或 `c.BindJSON(...)`。
- 返回 `c.JSON(...)` 或 `c.Error(...)`。
- 不在 API 里写长业务流程。

路由生成：

```txt
func (Order) PostCancel -> POST /<module>/order/cancel
```

## 5. Middleware / Config / Observe

- middleware 统一在 `middleware.Register()` 挂载。
- JWT 优先用 `dever/auth/jwt`。
- 日志用 `dever/log`，观测用 `dever/observe`。
- 配置从 `config/setting.json(c)` 走框架配置，不在业务代码里造第二套配置读取。

## 6. 脚手架

`scripts/module.sh` 默认只生成 model。只有明确需要时才加：

- `--provider`：生成 Provider hook 骨架。
- `--api`：生成薄 API 骨架。

不要用脚手架给普通后台 CRUD 生成 API/Service。
