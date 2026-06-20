# 从零开始

本文件用于空 Dever 项目初始化。已有项目不要用空项目脚本覆盖骨架。

## 顺序

1. 安装或同步 skill：

```bash
dever skill install
```

2. 检查项目根提示词：

```bash
dever skill doctor
```

缺少 `AGENTS.md` 管理块时，重新执行 `dever skill install`。`CLAUDE.md` 只引用 `@AGENTS.md`。

3. 空目录生成最小骨架：

```bash
bash ~/.agents/skills/shemic-dever/scripts/boot.sh my dever-app 8082
```

Dever 应用 Go module 固定是 `my`。不要按项目名、域名或目录名改 module path。

4. 安装基础 package：

```bash
dever package front
dever package bot
```

`dever package <name>` 会写 `module/<name>/main.go` package shim 并刷新注册文件。普通项目不保留 `package/<name>` 源码。

5. 新增业务资源按最低层级：

```txt
model -> page JSON -> Provider hook -> Service -> API -> front plugin
```

普通列表、新增、编辑、删除、详情只用 Model + page JSON，不写 CRUD API/Service。

## 最小骨架

空项目模板包含：

```txt
go.mod
main.go
config/setting.jsonc
data/readme.txt
module/front/main.go
module/bot/main.go
module/main/model/
```

`module/front/main.go` 和 `module/bot/main.go` 只放 package shim：

```go
// dever:import github.com/dever-package/front
```

不要在 shim 里写业务代码。

## 生成业务骨架

Model 骨架：

```bash
bash ~/.agents/skills/shemic-dever/scripts/module.sh main product
```

标准页面骨架：

```bash
bash ~/.agents/skills/shemic-dever/scripts/page.sh module/main admin product list 产品 --parent=product-center
bash ~/.agents/skills/shemic-dever/scripts/page.sh module/main admin product update 产品
```

这些脚本故意不生成 Service/API。只有读完 `service-api.md` 并确认存在真实业务流程后才手写。

## 常见错误

- 没先安装 skill，导致项目根没有 Dever 规则。
- 把 Go module 写成项目名，导致 package shim import 失效。
- 用 `boot.sh` 覆盖已有项目。
- 手动复制 `package/front` 源码到普通项目。
- 先写 API/Service，再补 model/page JSON。
- 手改 `data/router.go`、`data/load/*.go` 或 `data/table/*.json`。
