# Dever 应用开发

本文件用于普通应用项目中的业务 module、配置和后台功能。开始前先读 [decide.md](decide.md) 与 [development.md](development.md)。

## 1. 应用边界

- 项目私有业务放 `module/<name>`。
- `module/<name>/main.go` 只有 `// dever:import github.com/dever-package/<name>` 时，它是 package shim；真实代码来自 package，不在 shim 中追加业务。
- 普通应用不修改 `backend/dever`、`backend/package/*`，也不复制 package 源码。
- 当前仓库如果明确处于 framework/package 开发态，可以维护对应源码，但这不是普通应用模式。

## 2. 实现顺序

1. 搜索已有 component、Model、Page、Service、Provider、API 和组件 skill。
2. 明确拥有该业务的 module，并按业务域规划 `model/`、`service/`、`front/page/`。
3. 持久化资源先写 Model：字段、comment、Options、Relations、索引和默认排序。
4. 普通后台 CRUD 写 Page JSON，让标准路径推导 Model。
5. 有真实业务不变量时，在 `service/` 或 `service/<domain>/` 写普通 Service 方法。
6. Page 需要动态 hook/option 时，在同一 Service 域增加薄 Provider 方法。
7. 只有真实 HTTP 边界才写薄 API；只有 Page 无法表达的交互才写 front plugin。
8. 改 Model/Provider/API 后让 `dever run` 或 `dever init --skip-tidy` 刷新生成文件。

普通资源的最小形态：

```text
module/catalog/
  model/product.go
  front/page/admin/product/list.json
  front/page/admin/product/update.json
```

只有存在发布、审批、同步等业务动作时才增加：

```text
module/catalog/service/product.go
module/catalog/api/admin/product.go    # 仅在需要自定义 HTTP 动作时
```

## 3. 能力边界

| 需求 | 默认实现 | 不要做 |
| --- | --- | --- |
| 列表、新增、编辑、删除、详情 | Model + Page JSON | CRUD API/Service |
| 字段标签、枚举、关联选项 | Model comment/Options/Relations | 多页重复硬编码 |
| 保存前规范化、上下文派生 | Provider before hook | API 内联业务 |
| 保存后关系同步、计数、缓存失效 | Provider after hook 调用 Service | 空 Provider |
| 发布、审批、状态流转、跨表事务 | Service | Page 直接改状态 |
| 登录、回调、webhook、文件/流式协议 | API + Service | 泛化 CRUD action |
| 画布、复杂编辑器、持续客户端状态 | front plugin | 巨型 Page JSON |

选择依据见 [decide.md](decide.md)。

## 4. 业务目录

核心业务代码只放 `service/`。安装、升级、签名、任务、导入、发布等也是业务域，不创建 component 根级 `installer/`、`updater/`、`signing/`、`contract/` 或 `internal/`。

API、CLI、middleware、Model hook 只调用 Service，不复制规则。具体目录和命名见 [development.md](development.md)。

## 5. 配置

- 环境和部署差异放 `config/setting.json(c)`。
- 组件站点契约放组件 `dever.json.front.sites`。
- 项目 `config/front.json(c)` 只覆盖站点展示配置。
- 业务枚举放 Model Options，不做环境变量。
- 可持久化、可管理的业务数据放 Model，不塞进配置文件。

## 6. 空项目

空项目固定 Go module：

```go
module my
```

从零开始读 [quickstart.md](quickstart.md)。`scripts/boot.sh` 只用于空项目，已有项目不要用它覆盖骨架。

安装或更新 package：

```bash
dever package front
dever package bot
dever package
```

默认使用稳定 `@latest`。维护 package 或验证未发布提交时才使用：

```bash
dever package --ref=main front
dever package --ref=v0.1.1 front
```

flag 写在组件名称前。

## 7. 自检

- 是否改在拥有业务的 module，而不是 framework 或公共 package。
- 是否先复用现有能力并停在最低能力层。
- 普通 CRUD 是否仍然只有 Model + Page JSON。
- 核心业务是否全部在 `service/`，适配入口是否薄。
- 是否没有根级平行业务目录、空 Provider、CRUD wrapper 或预留 API。
- 是否没有手改生成文件、编译产物或使用旧 Page 协议。
- Options/Relations 是否替代了重复 Page 配置。

可用时运行：

```bash
bash skills/skills-dever/scripts/audit.sh <changed-file-or-dir>
```
