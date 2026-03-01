# Module Business Development Playbook

这个文档专门回答：在 `module` 下怎么写业务代码。

适用两类场景：

1. 新建模块：`module/<new_module>`
2. 续写模块：`module/<existing_module>`

快速入口（推荐）：

- `bash scripts/scaffold-module.sh <module_dir> <resource_name> [dever_version]`
- 示例：`bash scripts/scaffold-module.sh blog article main`
- 注意：脚手架会覆盖同名文件，续写已有模块前先确认文件冲突

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

import "github.com/shemic/dever/orm"

type Article struct {
    ID      int64  `dorm:"primaryKey;autoIncrement;comment:主键ID"`
    Name    string `dorm:"size:64;not null;comment:标题"`
    Code    string `dorm:"size:64;not null;comment:唯一标识"`
    UID     int64  `dorm:"column:uid;comment:用户ID"`
    Status  int8   `dorm:"size:1;default:1;comment:状态"`
    Sort    int64  `dorm:"default:1;comment:排序"`
    Cdate   int64  `dorm:"comment:创建时间"`
}

type ArticleIndex struct {
    Code    struct{} `unique:"code"`
    UIDSort struct{} `index:"uid,status,sort,id"`
}

func ArticleModel() *orm.Model[Article] {
    return orm.LoadModel[Article]("blog_article", ArticleIndex{}, "sort desc,id desc", "default")
}
```

### 3.2 Model 设计规则

1. `Code` 做业务唯一标识，避免前端依赖自增 ID。
2. 索引围绕常用查询条件设计（例如 `uid+status+sort`）。
3. `module/*/model` 目录尽量只放模型相关导出函数，避免被 `dever model` 误注册。

---

## 4. Service 层怎么写（业务逻辑）

Service 负责业务规则，不负责 HTTP 协议细节。

### 4.1 常规业务方法模板

```go
package service

import (
    "context"
    "errors"
    "strings"
    "time"

    "my/module/blog/model"
)

type ArticleService struct{}

func (ArticleService) Create(ctx context.Context, uid int64, name string) (string, error) {
    name = strings.TrimSpace(name)
    if name == "" {
        return "", errors.New("名称不能为空")
    }
    code := buildCode("article")
    model.ArticleModel().Insert(ctx, map[string]any{
        "uid":    uid,
        "name":   name,
        "code":   code,
        "status": 1,
        "sort":   time.Now().Unix(),
        "cdate":  time.Now().Unix(),
    })
    return code, nil
}

func (ArticleService) GetInfo(ctx context.Context, uid int64, code string) *model.Article {
    return model.ArticleModel().Find(ctx, map[string]any{
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

---

## 5. Provider 层怎么写（给 Dever.Load 调用）

当你需要流程引擎、配置化节点、跨模块动态调用时，给 Service 增加 Provider。

### 5.1 Provider 模板

```go
package service

import (
    "fmt"

    "github.com/shemic/dever/server"
)

func (s ArticleService) ProviderGetInfo(c *server.Context, params []any) any {
    if len(params) < 2 {
        panic("参数不足，需要 uid, code")
    }
    uid := toInt64(params[0])
    code := fmt.Sprint(params[1])
    return s.GetInfo(c.Context(), uid, code)
}
```

### 5.2 Provider 规则

1. 方法名必须 `ProviderXxx` 才会被 `dever service` 扫描。
2. 推荐签名固定为：`func (XxxService) ProviderXxx(c *server.Context, params []any) any`
3. Provider 里做“参数适配”，核心业务继续调用常规 Service 方法。

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

---

## 7. 中间件怎么接入业务

项目级中间件入口是 `middleware/Register()`。

常见做法：

1. 全局挂 `coremiddleware.Init()`（Recover + Log）。
2. 再挂自定义鉴权中间件（例如 JWT、RBAC）。
3. 特殊接口用 `UseRouteFunc(method, path, ...)` 做精细控制。

建议：

- 认证/用户上下文注入放中间件，业务代码只拿 `mid.GetUid(...)`。
- 不要在每个 API 里复制 token 解析逻辑。

---

## 8. 新建模块完整流程（从 0 写业务）

1. 优先执行脚手架命令（自动生成 model/service/provider/api）：
   - `bash scripts/scaffold-module.sh blog article main`
2. 基于需求补充字段、校验、权限和状态流转。
3. 如需多实体，继续执行脚手架命令生成第二个资源骨架。
4. 执行：
   - `go run github.com/shemic/dever/cmd/dever@main init --skip-tidy`
5. 检查：
   - `data/router.go` 有新路由
   - `data/load/model.go` 有新 model 注册
   - `data/load/service.go` 有新 provider 注册

---

## 9. 续写现有模块完整流程（增量改业务）

1. 找到现有模块 `module/<name>` 的对应文件。
2. 优先复用已有 Service，不要在 API 里堆逻辑。
3. 变更涉及模型字段时，先改 Model，再改 Service/API。
4. 新增可复用动作时，补 `ProviderXxx`。
5. 改完统一执行一次：
   - `go run github.com/shemic/dever/cmd/dever@main init --skip-tidy`
6. 对照生成文件确认改动生效。

---

## 10. AI 交付时必须输出的内容

每次完成业务改动，AI 需要输出：

1. 改动文件列表
2. 新增/修改路由列表
3. 新增/修改 `load` 注册名列表
4. 业务规则说明（关键校验、权限、状态流转）
