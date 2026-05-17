# Module Business Development Playbook

这个文档专门回答：在 Dever 项目里怎么写业务代码，重点是 `module`，但规则同样约束写在其他目录里的业务逻辑。

适用三类场景：

1. 新建模块：`module/<new_module>`
2. 续写模块：`module/<existing_module>`
3. 在 `package/*`、`cmd/*`、worker、task、hook、helper、middleware 等非 `module/*/service` 位置写业务逻辑

快速入口（仅需要业务 API/Provider 骨架时推荐）：

- `bash scripts/module.sh <module_dir> <resource_name> [dever_version] [--force]`
- 示例：`bash scripts/module.sh blog article main`
- 默认拒绝覆盖同名文件；确认要替换时才加 `--force`
- 当前主开发流程：
  1. `go run .../dever install`
  2. `dever run`
  3. 再持续写 `module/*` 或其他业务目录
  4. 需要发布产物时统一使用 `dever build`

如果目标是“业务后台页面”，不要从 API CRUD 开始。使用 `shemic-dever` 做后台时，默认按 `model + package/front + page JSON` 复用通用后台能力；用户不需要额外说“通过 JSON 实现”。只有通用页面能力无法覆盖时才补 service/api。

如果目标是“完整项目”或“复杂后台系统”，不要直接从某个 module 开始写代码。先读 `references/project.md`，输出模块矩阵、模型矩阵、页面矩阵和动作矩阵，再回到本文实现具体 module。

---

## 0. 通用开发约束

### 0.1 复用和封装

1. 写代码前先搜索已有实现：
   - 同类 Model / Service / Provider / API
   - `dever/util`、`dever/orm`、`dever/load`、`dever/log`、`dever/observe`
   - `package/front` 的页面运行时、导入导出、上传、资源库能力
2. 能扩展现有实现就不要新建平行实现。
3. 同一流程出现第二次时，优先抽成 service/helper/config；出现第三次必须抽。
4. 封装只服务于复用和清晰，不为了减少行数制造空层。

### 0.2 简单好读

1. API 只做取参、调 Service、返回。
2. Service 承载业务规则、校验、事务和编排。
3. Model 只放结构、索引、构造函数，避免混入业务逻辑。
4. 函数保持单一职责，优先早返回，避免深层嵌套。
5. 命名表达业务意图，不使用 `data/item/manager/util` 这类模糊名。

### 0.3 命名约束

命名优先靠目录和 package 提供上下文，文件名、类型名、函数名只补充当前层缺失的信息。不要用长命名或多段下划线掩盖职责混乱。

文件命名：

1. 文件名用小写，优先一个业务词；两个词可以用 `_`。
2. 文件名出现多个 `_` 时，先判断是否应该拆目录、拆职责或缩短语义。
3. 不重复父目录已经表达的语义。例如 `runtime/loop.go` 优于 `runtime/runtime_loop.go`。
4. 不用 `service_`、`runtime_`、`prompt_` 这类已由目录表达的前缀。
5. 谨慎使用 `helper.go`、`utils.go`、`common.go`、`value.go`、`manager.go`；它们容易变成垃圾桶。

目录归属：

1. `service` 根目录只放入口、编排和跨领域 glue 文件，例如 `main.go`、`request.go`、`repo.go`、`types.go`。
2. 同一稳定领域出现多个文件时必须收进子目录；不要让 `stream.go`、`stream_cancel.go`、`stream_collect.go` 这类同域文件散落在根目录。
3. 已有稳定目录时，同域新增文件必须放进去。例如已有 `log/record.go`，日志查看、日志格式化、日志查询也应归到 `log/`，不要再写 `log_view.go` 到根目录。
4. 目录成立条件：至少满足“多文件同域”、“有独立状态/协议/适配边界”、“被多个上层流程复用”之一。
5. 目录不成立条件：只有一个很小文件、只服务当前函数、或只是为了套分类。此时先并回上层。
6. Go 子目录就是子包，不能在子包里给父包类型继续加方法；遇到 `GatewayService.StartStream` 这类公开入口时，根目录只保留薄 facade，内部状态机、解析、收集、取消等稳定逻辑放进子包。
7. 被 `Dever.Load` 或 page JSON 引用的 Provider/Hook 移目录时，必须同步更新 page JSON 的 `use` 字符串，并通过 `dever run` 或调试用 `dever service` 刷新生成注册；不要手改 `data/load/service.go`。

类型命名：

1. 类型名不要重复 package 语义。例如 `input.Target` 优于 `input.InputTarget`。
2. 私有类型尽量短；导出类型必须让调用方看懂业务含义。
3. 只有一个方法、没有状态、没有策略差异的类型，优先改成函数。
4. `Service` 后缀只给真实业务入口；不要给每个小能力都套 `XxxService`。
5. Dever 扫描和动态调用依赖的命名不能随意缩短：`New<Resource>Model`、`ProviderBeforeSaveXxx`、`ProviderLoadXxxOptions`、`Get/Post/Put/DeleteXxx` 必须保持协议语义。

函数和变量命名：

1. 函数名表达业务动作，不表达实现绕法；超过四个语义词时，先检查函数是否职责过多。
2. 接收者、包名、目录已经提供上下文时，函数名不要重复上下文。
3. 短作用域变量可用 `id/err/row/req/resp/ctx`；长作用域变量必须写清业务含义。
4. 不用 `data/item/thing/manager/util/helper` 作为业务变量名；`row/item` 只适合很短的循环。
5. 布尔变量使用明确判断语义，如 `exists/enabled/matched/cancelled`。

### 0.4 清理垃圾和冗余

每次实现后必须做一次 cleanup pass，主动删除垃圾、无用和冗余代码。不要把“以后可能用到”的代码留在项目里。

必须清理：

- 未使用的函数、变量、常量、类型、import、文件和目录。
- 调试日志、临时打印、临时注释、废弃 TODO、实验代码。
- 单行转发 wrapper、无意义 alias、只调用一次且不提升可读性的 helper。
- 重复的查询、校验、状态判断、参数转换、错误包装和响应组装。
- 已被新实现替代的旧分支、旧配置、旧模板、旧示例。
- 只有一个小文件且没有独立职责的微目录。

保留代码必须满足至少一个条件：

1. 当前功能真实使用。
2. 消除了实际重复。
3. 明确表达业务概念。
4. 降低了复杂度或未来变更面。

如果不满足，就删除或合并。

### 0.5 高性能、高可用、高并发

1. 列表和批量接口必须考虑索引、分页、条件下推、字段选择。
2. 避免 N+1 查询；需要关联数据时优先批量查询后组装。
3. 禁止无边界 goroutine、无边界内存聚合、无条件全表扫描。
4. 外部调用必须有超时、错误返回和结构化日志；重试只用于幂等操作。
5. 状态流转、扣减、唯一创建等并发敏感逻辑必须使用事务、唯一索引、锁或幂等键。
6. 不在包级可变变量里保存请求态数据；共享缓存必须并发安全，并有失效策略。

### 0.6 严格按 Dever 框架开发

1. Model 使用 `orm.LoadModel[T](...)`。
2. API 使用结构体方法，方法名前缀为 `Get/Post/Put/Delete`。
3. API 入参统一使用 `c.Input(...)`。
4. 动态调用统一通过 Provider + `Dever.Load` 注册名。
5. 日志、观测、JWT、配置读取优先复用 Dever 框架能力。
6. 不手改生成文件：
   - `data/router.go`
   - `data/load/model.go`
   - `data/load/service.go`

### 0.7 非 module/service 的业务代码

只要代码承载业务规则、业务编排、状态流转、外部调用、任务处理、导入导出、回调处理、页面 hook、worker 逻辑，就必须按本文 Service 规则写；不要因为文件不在 `module/*/service` 下，就写成临时脚本或巨型过程。

适用目录包括但不限于：

- `package/*` 中的可复用业务能力
- `cmd/*` 中的 worker、job、daemon
- `module/*/hook`、`module/*/task`、`module/*/helper`
- `middleware` 中除鉴权装配外的业务策略
- `package/front` hook、导入导出处理、资源处理

约束：

1. 先定义业务用例，再决定放在哪个目录。
2. 核心业务函数使用 `context.Context + 明确参数`，不要直接依赖 HTTP 请求对象。
3. HTTP、Provider、CLI、worker、page hook 只做适配层，核心流程继续调用普通业务函数。
4. 目录名和文件名按业务意图命名，不使用 `utils/common/helper/manager/value` 作为业务归宿。
5. 不创建只有一两个函数的微目录；如果只服务当前流程，先放在同一业务文件里。
6. 需要被 `Dever.Load` 动态调用时，在 `module/*/service` 或项目约定的 service 目录补一个薄 Provider，Provider 只做参数适配。
7. 可复用的跨模块业务能力可以放到 `package/*`，但仍然按 Service 的复用、事务、错误、日志和并发约束写。
8. 不要在 `cmd/*`、hook、middleware 中复制 Model 查询、状态校验或外部调用流程；抽成业务函数后复用。

---

## 1. 先做需求拆解（写代码前）

把需求拆成 5 个问题：

1. 业务实体是什么（表）？
2. 业务动作是什么（增删改查/状态流转/批处理）？
3. 接口输入输出是什么（字段、必填、错误）？
4. 是否需要 `Dever.Load` 动态调用（Provider）？
5. 是否需要中间件控制（鉴权/白名单/日志增强）？

输出一个最小清单：

- 要改的 Model 文件
- 要改的 Service 文件
- 要改的 API 文件
- 是否新增/改动中间件

### 1.1 建议的需求输入模板（给 AI）

```md
模块名：blog
资源名：article
核心字段：name, code, status, sort
接口需求：list, info, add, update, delete
权限规则：登录用户可访问，仅本人数据可见
状态规则：status=1 可用，status=2 删除
```

### 1.2 接口产出矩阵（最小可交付）

1. `GetList`：列表查询（支持 limit / 条件）
2. `GetInfo`：按 code 查详情
3. `PostAdd`：新增数据
4. `PostUpdate`：更新关键字段
5. `PostDelete`：软删除（更新状态）

---

## 2. 模块标准目录

最小目录：

```text
module/<name>/
  api/
  model/
  service/
```

推荐按业务域拆文件，不按“接口数量”拆。

示例（文章模块）：

```text
module/blog/
  model/
    article.go
    article_cate.go
  service/
    article.go
    article_provider.go
  api/
    article.go
    article_cate.go
```

---

## 3. Model 层怎么写（数据结构）

### 3.1 单表模板

```go
package model

import (
    "time"

    "github.com/shemic/dever/orm"
)

type Article struct {
    ID        uint64    `dorm:"primaryKey;autoIncrement;comment:主键ID"`
    Name      string    `dorm:"type:varchar(64);not null;comment:标题"`
    Code      string    `dorm:"type:varchar(64);not null;comment:唯一标识"`
    UID       uint64    `dorm:"type:bigint;not null;default:0;column:uid;comment:用户ID"`
    Status    int16     `dorm:"type:smallint;not null;default:1;comment:状态"`
    Sort      int       `dorm:"type:int;not null;default:100;comment:排序"`
    CreatedAt time.Time `dorm:"comment:创建时间"`
}

type ArticleIndex struct {
    Code    struct{} `unique:"code"`
    UIDSort struct{} `index:"uid,status,sort,id"`
}

var articleStatusOptions = []map[string]any{
    {"id": 1, "value": "启用"},
    {"id": 2, "value": "删除"},
}

func NewArticleModel() *orm.Model[Article] {
    return orm.LoadModel[Article]("文章", "blog_article", orm.ModelConfig{
        Index:    ArticleIndex{},
        Order:    "sort desc,id desc",
        Database: "default",
        Options: map[string]any{
            "status": articleStatusOptions,
        },
    })
}
```

### 3.2 Model 设计规则

1. `Code` 做业务唯一标识，避免前端依赖自增 ID。
2. 索引围绕常用查询条件设计（例如 `uid+status+sort`）。
3. `module/*/model` 目录尽量只放模型相关导出函数，避免被 `dever model` 误注册。
4. 如果该 model 要被 `package/front` 页面默认解析，构造函数优先命名为 `New<Resource>Model`，例如 `NewArticleModel`。嵌套路由如 `work/type/list` 可用 `NewTypeModel` 或 `NewWorkTypeModel`，以 `front-page.md` 的默认模型命名规则为准。

---

## 4. Service 层怎么写（业务逻辑）

Service 负责业务规则，不负责 HTTP 协议细节。

### 4.0 从零开始写 Service

写 Service 前先定义业务用例，不要先定义文件结构。

必须先回答：

1. 这个 Service 负责哪个业务动作？
2. 输入、输出和错误是什么？
3. 会读写哪些 Model？
4. 是否有事务、状态流转、外部调用、异步任务或幂等要求？
5. 哪些规则必须在 Service 兜底，而不是只靠 API、Provider 或页面校验？

第一版先写清主流程，主流程应该像业务步骤一样可读：

1. 归一化输入
2. 校验业务规则
3. 查询必要数据
4. 执行业务动作
5. 写入状态或结果
6. 返回稳定结果

不要一开始就创建 helper、interface、manager、executor、runtime、options 等抽象。只有当真实职责出现后，再拆函数、文件或目录。

### 4.1 常规业务方法模板

```go
package service

import (
    "context"
    "errors"
    "fmt"
    "strings"
    "time"

    "my/module/blog/model"
)

type ArticleService struct{}

func (ArticleService) Create(ctx context.Context, uid uint64, name string) (string, error) {
    name = strings.TrimSpace(name)
    if name == "" {
        return "", errors.New("名称不能为空")
    }
    now := time.Now()
    code := fmt.Sprintf("article_%d", now.UnixNano())
    model.NewArticleModel().Insert(ctx, map[string]any{
        "uid":        uid,
        "name":       name,
        "code":       code,
        "status":     1,
        "sort":       int(now.Unix()),
        "created_at": now,
    })
    return code, nil
}

func (ArticleService) GetInfo(ctx context.Context, uid uint64, code string) *model.Article {
    return model.NewArticleModel().Find(ctx, map[string]any{
        "uid":    uid,
        "code":   strings.TrimSpace(code),
        "status": 1,
    })
}
```

### 4.2 Service 设计规则

1. 业务校验在 Service 做最终兜底，不要只依赖 API 层校验。
2. 多表逻辑优先放 Service，API 只做组装和返回。
3. 返回值保持稳定：成功返回业务对象，失败返回 `error`（或按项目约定 panic）。
4. 先检查 `github.com/shemic/dever/util` 是否已有可复用 helper，不要在业务层重复写第二套：
   - `util.ToString`
   - `util.ToStringTrimmed`
   - `util.ParseInt64`
   - `util.ParseUint64`
   - `util.ParseFloat64`
   - `util.ParseBool`
   - `util.ToBool`
   - `util.ToKeyString`
   - `util.CloneMap`
   - `util.CloneMapSlice`
   - `util.UniqueUint64s`

### 4.3 Service 过度封装禁令

1. 禁止无意义单行转发。
   - 不要只给外部函数换名，例如 `func frameType(v any) string { return external.FrameType(v) }`。
   - 只有当函数承载业务语义、统一错误处理、默认值、协议兼容或多处复杂重复时，才允许抽出。
2. 禁止单实现 interface。
   - 当前只有一个具体实现时，直接用 concrete type。
   - 只有存在多个实现、跨包稳定契约、真实替换需求或明确外部边界时，才允许 interface。
3. 禁止固定模板拆文件。
   - 不要因为“Service 都应该有这些文件”而创建文件。
   - 文件必须来自真实职责，命名必须表达业务意图或技术边界。
4. 禁止桶文件。
   - 不要创建 `helper.go`、`utils.go`、`common.go`、`value.go`、`manager.go` 这类无法表达职责的文件。
   - 必须改成能表达职责的名字，例如 `normalize.go`、`validate.go`、`status.go`、`payload.go`、`selector.go`、`scheduler.go`。
5. 禁止单小文件目录。
   - 目录必须代表稳定业务边界。
   - 如果目录里只有一个小文件，且只服务当前 Service 主流程，应并回上层。
6. 禁止为了“以后可能扩展”提前抽象。
   - 抽象必须来自当前已经存在的重复、复杂分支、多个实现或清晰边界。

### 4.4 Service 自查清单

写完第一版后必须检查：

- 主流程是否能直接读出业务步骤？
- 是否有只调用一次的 helper？
- 是否有单行转发 wrapper？
- 是否有单实现 interface？
- 是否有桶文件名？
- 是否有只有一个小文件的目录？
- 是否把普通 CRUD 写成了不必要的 Service/API？
- 是否把数据库细节塞进 API？
- 是否把 HTTP 协议细节塞进 Service？
- 是否为了未来扩展提前造层？
- 是否能复用 Dever util、已有 Model、已有 Service、已有 Provider？

发现问题先改结构，再继续加功能。

---

## 5. Provider 层怎么写（给 Dever.Load 调用）

当你需要流程引擎、配置化节点、跨模块动态调用时，给 Service 增加 Provider。

### 5.1 Provider 模板

```go
package service

import (
    "github.com/shemic/dever/server"
    "github.com/shemic/dever/util"
)

func (s ArticleService) ProviderGetInfo(c *server.Context, params []any) any {
    if len(params) < 2 {
        panic("参数不足，需要 uid, code")
    }
    uid, _ := util.ParseInt64(params[0])
    code := util.ToStringTrimmed(params[1])
    return s.GetInfo(c.Context(), uid, code)
}
```

### 5.2 Provider 规则

1. 方法名必须 `ProviderXxx` 才会被 `dever service` 扫描。
2. 推荐签名固定为：`func (XxxService) ProviderXxx(c *server.Context, params []any) any`
3. Provider 里做“参数适配”，核心业务继续调用常规 Service 方法。
4. 参数转换优先复用 `dever/util`，不要在 Provider 里重复写 `strconv/type switch`。

---

## 6. API 层怎么写（对外接口）

API 只做三件事：取参、调服务、返回。

### 6.1 API 模板

```go
package api

import (
    "github.com/shemic/dever/server"

    mid "my/middleware"
    blogService "my/module/blog/service"
)

type Article struct{}

var articleSvc = blogService.ArticleService{}

func (Article) PostAdd(c *server.Context) error {
    uid := mid.GetUid(c.Context())
    name := c.Input("name", "required", "名称")
    code, err := articleSvc.Create(c.Context(), uid, name)
    if err != nil {
        return c.Error(err)
    }
    return c.JSON(map[string]any{"code": code})
}

func (Article) GetInfo(c *server.Context) error {
    uid := mid.GetUid(c.Context())
    code := c.Input("code", "required", "标识")
    info := articleSvc.GetInfo(c.Context(), uid, code)
    if info == nil {
        return c.Error("数据不存在")
    }
    return c.JSON(map[string]any{"info": info})
}
```

### 6.2 API 规则

1. 参数统一走 `c.Input(...)`（包含 path/query/form/json body）。
2. 统一返回 `c.JSON(...)` / `c.Error(...)`。
3. API 必须是结构体方法，命名前缀 `Get/Post/Put/Delete`。
4. 如果接口受登录保护，业务代码优先只拿：
   - `mid.GetUid(c.Context())`
   不要在 API 里重复解析 Bearer/JWT/claims。

---

## 7. 中间件怎么接入业务

项目级中间件入口是 `middleware/Register()`。

常见做法：

1. 全局挂 `coremiddleware.Init()`（Recover + Log）。
2. 再挂自定义鉴权中间件（例如 JWT、RBAC）。
3. 特殊接口用 `UseRouteFunc(method, path, ...)` 做精细控制。

建议：

- 认证/用户上下文注入放中间件，业务代码只拿 `mid.GetUid(...)`。
- JWT 优先复用 `dever/auth/jwt`：
  - 单 JWT：`config.auth.jwtSecret`
  - 多 JWT：`config.auth.jwt.schemes + guards`
- 不要在每个 API 里复制 token 解析逻辑。
- request/db observe 已在框架层，业务 API/Service 不要再重复包一层计时埋点。

---

## 8. 新建模块完整流程（从 0 写业务 API/Provider）

1. 确认当前需求确实需要自定义 API/Provider；普通后台 CRUD 先走 Model + page JSON。
2. 执行脚手架命令（自动生成 model/service/provider/api）：
   - `bash scripts/module.sh blog article main`
   - 有同名文件时脚本会拒绝覆盖；确认替换才加 `--force`
3. 如果要写后台页面，先接入/检查 `package/front`，并把 model 构造函数命名保持为 `New<Resource>Model`。项目模块页面放 `module/<name>/page`；可复用 package 页面放 `package/<name>/page`，不要混放。
4. 基于需求补充字段、校验、权限和状态流转。
5. 如需多实体，继续执行脚手架命令生成第二个资源骨架。
6. 确保 `dever run` 正在运行：
   - `dever run` 会自动处理 `init --skip-tidy`
7. 检查：
   - `data/router.go` 有新路由
   - `data/load/model.go` 有新 model 注册
   - `data/load/service.go` 有新 provider 注册

---

## 9. 续写现有模块完整流程（增量改业务）

1. 找到现有模块 `module/<name>` 的对应文件。
2. 优先复用已有 Service，不要在 API 里堆逻辑。
3. 变更涉及模型字段时，先改 Model，再改 Service/API。
4. 新增可复用动作时，补 `ProviderXxx`。
5. 如果变更页面 JSON，先确认页面归属目录（module 页面放 `module/*/page`，package 页面放 `package/*/page`），再复用 `package/front` 的 list/update/view/stat 页面模式，并检查默认模型名是否能命中。
6. 改完保持 `dever run` 运行即可：
   - `dever run` 会自动处理 `init --skip-tidy`
7. 对照生成文件确认改动生效。

---

## 10. Install + Run 约定

现在项目开发主流程统一为：

1. 安装 `dever`
   - 常规项目：`go run github.com/shemic/dever/cmd/dever@main install`
   - 本地框架项目：`go run ./dever/cmd/dever install`
2. 启动开发：`dever run`

说明：

- `dever run` 启动前会自动执行 `init --skip-tidy`
- 改动 `model/service/api` 等敏感文件后，也会自动重新执行 `init --skip-tidy`
- 显式执行 `init/routes/service/model` 主要用于排查，不再是日常主流程

---

## 11. AI 交付时必须输出的内容

每次完成业务改动，AI 需要输出：

1. 改动文件列表
2. 新增/修改路由列表
3. 新增/修改 `load` 注册名列表
4. 业务规则说明（关键校验、权限、状态流转）
5. 复用和封装说明（复用了什么，抽取了什么，为什么没有新增抽象）
6. 性能/可用性/并发风险检查结果（索引、分页、事务、超时、幂等、并发状态）
