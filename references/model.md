# Model 规则

Model 是后台、导入导出、权限、option、relation 的源头。先写对 model，再写页面。

## 1. 文件和命名

- 一个数据库表一个文件。
- 一个文件只放一个表 struct、一个 Index、一个 `NewXxxModel`。
- 共享枚举、Relation 可放 `options.go`、`relation.go`。
- 文件名用资源名 snake_case。
- 可以省略当前 package 已表达的前缀，但不能省略剩余业务前缀。

例子：

| package | struct / func | 文件 |
| --- | --- | --- |
| `model/brain` | `Brain` / `NewBrainModel` | `brain.go` |
| `model/brain` | `ThinkNode` / `NewThinkNodeModel` | `think_node.go` |
| `model/agent` | `AgentKnowledge` / `NewAgentKnowledgeModel` | `knowledge.go` 或 `agent_knowledge.go` |

不要把表 model 放进 `main.go`。`main.go` 只做入口或 package import shim。

## 2. 标准结构

```go
type Article struct {
    ID        uint64    `dorm:"primaryKey;autoIncrement;comment:主键ID"`
    Name      string    `dorm:"type:varchar(128);not null;comment:名称"`
    Code      string    `dorm:"type:varchar(128);not null;comment:标识"`
    Content   string    `dorm:"type:text;not null;default:'';comment:内容"`
    Status    int16     `dorm:"type:smallint;not null;default:1;comment:状态"`
    Sort      int       `dorm:"type:int;not null;default:100;comment:排序"`
    CreatedAt time.Time `dorm:"comment:创建时间"`
}

type ArticleIndex struct {
    Code       struct{} `unique:"code"`
    StatusSort struct{} `index:"status,sort,id"`
}

var articleStatusOptions = []map[string]any{
    {"id": 1, "value": "启用"},
    {"id": 2, "value": "停用"},
}

func NewArticleModel() *orm.Model[Article] {
    return orm.LoadModel[Article]("文章", "article", orm.ModelConfig{
        Index:    ArticleIndex{},
        Order:    "sort asc,id asc",
        Database: "default",
        Options: map[string]any{
            "status": articleStatusOptions,
        },
    })
}
```

## 3. 字段规则

- 所有后台展示字段写 dorm `comment`。
- 长文本用 `type:text`，不要用 `longtext`。
- `CreatedAt` 可作为常规创建时间字段；`UpdatedAt` 不要默认添加。
- 只有明确需要追踪最后更新时间的表才加 `UpdatedAt`，例如运行记录、审批状态、进度/黑板等会被多次更新的运行态记录。
- 纯配置、节点/边定义、版本快照、消息、记忆等没有明确更新时间语义的表，默认只保留 `CreatedAt`。
- Model 没有 `UpdatedAt` 时，service/repo/page 也不能写 `updated_at`，字段和写入必须保持一致。
- 状态、类型、枚举字段必须写 `Options`。
- 关联字段优先写 `Relations`，页面会自动生成 option 和关联展示。
- 密码/隐藏字段写 `ModelConfig.Fields`。

## 4. Relation 规则

```go
orm.Relation{
    Field:      "agent_id",
    Option:     "bot.agent.NewAgentModel",
    OptionKeys: []string{"name", "key"},
}
```

常用规则：

- 单选外键：`xxx_id`
- 多选关系：`xxx_ids`
- 中间表：写 `Through/OwnerField/TargetField/Option`
- 页面列展示关联名时用 `agent.name` 这类路径，不写额外接口。

## 5. 索引规则

索引只服务真实查询、幂等和业务一致性，不为了“看起来完整”默认添加。

- 展示名字段（`name`、`title`、`display_name`）默认不加 `unique`，也不默认加 `index:"name,id"`。
- 只有稳定业务标识才加唯一索引，例如 `key`、`code`、`account`、`token_hash`、`request_id`、`lock_key`、版本号、关系表自然键。
- 运行态、大表、日志、流水、统计表可以按真实查询保留组合索引，例如 `project_id,status,created_at`、`owner_id,status,id`、`knowledge_base_id,status,id`。
- 小配置表、分类表不要默认加单独 `sort`、`created_at`、`name` 索引；如果只是后台列表排序，依赖 `Order` 即可。
- `status,sort,id` 只在数据量可能增长且经常按状态筛选时添加；小型字典/分类表不需要。
- 如果字段用于模糊搜索，普通 BTree `name,id` 通常无效；不要为了模糊搜索随手加索引。
- 树路径、文件目录、状态 KV 等确实需要同级唯一时可以加组合唯一，但必须在模型旁能看出业务语义。

索引变更后要注意已上线数据库里的既有索引。Dever 结构同步在开启时会按 model 声明同步索引；如果项目未开启结构同步，需要单独提供清理 SQL 或升级说明。

## 6. 注册规则

Dever 只扫描 `model` 目录里的零参数 `New*Model` 构造函数。注册名：

```txt
<module>[.<model子目录>].NewXxxModel
```

可以在 model 包里写普通导出 helper、Options、Normalize 函数，但它们不会进 `data/load/model.go`，也不能当 model 注册名给 page JSON 使用。

例子：

- `module/profile/model/profile.go` -> `profile.NewProfileModel`
- `package/bot/model/brain/brain.go` 通过 `module/bot/main.go` import -> `bot.brain.NewBrainModel`

如果报 `model 未注册`，先查：

1. `NewXxxModel` 是否被生成进 `data/load/model.go`。
2. model 初始化是否 panic。
3. page path 是否推导到正确 model。
4. 是否用了数据库不支持的字段类型。
