# Dever 统一工作流

先识别项目当前状态，再按缺失层补齐。

## 1. 先识别现状

```bash
find . -maxdepth 3 -type f \( -name go.mod -o -name main.go -o -name '*.json' -o -name '*.jsonc' \)
find module package -maxdepth 4 -type f 2>/dev/null
```

看这些东西是否存在：

- `go.mod`
- `main.go`
- `config/setting.json(c)`
- `module/*`
- `package/*`
- `data/readme.txt`
- `data/router.go`
- `data/load/model.go`
- `data/load/service.go`
- `config/front.json(c)`
- `module/*/page` 或 `package/*/page`

缺少哪层，就补哪层。不要为了“模式”套模板。

## 2. 决策顺序

1. 项目能否被 Dever 启动？
   - 没有 `go.mod`：初始化。
   - 没有 `main.go`：补 Dever 入口。
   - 没有 `config/setting.json(c)`：补最小配置。
2. 代码归属在哪里？
   - 项目业务放 `module/<name>`。
   - `package/<name>` 和 `backend/dever` 作为已上线框架/package 参考或复用；应用开发不要改它们。
   - `module/<name>/main.go` 有 `// dever:import ...` 时，真实代码在 package。应用层只通过 module 引入和配置复用，不复制 package 代码。
3. 数据是否需要新表？
   - 需要就先写 model。
   - 页面字段、Options、Relations 都从 model 开始。
4. 是否是后台页面？
   - 是就默认 `package/front + page JSON`。
   - 普通 CRUD 不写 API/Service。
5. 是否有真实业务规则？
   - 状态流转、跨表保存、强校验、外部协议、异步任务、聚合查询才写 Service/API。
6. 是否需要刷新生成文件？
   - 改 model/service/api 后让 `dever run` 自动刷新，或手动用 `dever model/service/routes` 调试。
   - 不手改生成文件。

## 3. 实施顺序

1. 搜索同类实现。
2. 列出要改文件。
3. 先写 model。
4. 再写必要 Service/Provider/API。
5. 再写 page JSON。
6. 最后补 config/menu。
7. 跑静态 audit。

## 4. 交付格式

```md
结构风险：
- ...

实现：
- ...

复用点：
- ...

验证：
- ...
```

验证里明确说是否没有跑 build/test。
