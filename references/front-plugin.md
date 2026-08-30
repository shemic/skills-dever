# Front Plugin

Front plugin 只补 Page runtime 缺失的交互节点。普通列表、表单、详情、option、状态、排序、弹窗和标准 action 都使用 Page JSON，不为“页面看起来复杂”直接写插件。

## 升级判断

按顺序回答：

1. 宿主或当前组件是否已有可复用节点。
2. 是否能用 layout + nodes + data/state/action 组合完成。
3. 缺的是数据/业务规则，还是交互组件。
4. 数据补充能否用 Provider，业务流程能否用 Service。
5. 只有缺少真实交互能力时，才新增插件节点。

适合插件的例子：画布、图编辑器、复杂流程设计器、领域实时工作台、宿主没有的高交互可视化。普通 CRUD 和页面级样式调整不是理由。

## 职责边界

- 插件：React UI、交互状态、节点注册和公开 SDK 调用。
- Page JSON：页面结构、节点实例、数据绑定和 action 编排。
- Provider：Page/option 的动态调用适配。
- Service：业务不变量、事务、状态流转、外部调用。
- API：插件确实需要的 HTTP/流式/文件/回调边界，保持薄。

插件不能把权限、保存、事务或业务状态机搬到浏览器。Page 能表达的数据请求和保存仍使用现有 runtime；真实自定义 API 必须由后端校验输入和权限。

## 文件和发布物

```txt
package/<name>/front/src/plugin.ts
package/<name>/front/package.json
package/<name>/front/dist/manifest.json
```

有 `front/src/plugin.ts` 的已发布 package 必须携带有效 `front/dist/manifest.json`。`front/dist/placeholder.txt` 不是有效构建产物，也不能手改 dist。

## `plugin.ts` 契约

宿主当前插件对象只声明：

```ts
type DeverFrontPlugin = {
  name: string
  depends?: string[]
  nodes?: Record<string, LazyNodeComponent>
}
```

- 使用公开 `defineFrontPlugin`/`lazyNode` 方式注册。
- `depends` 写 Dever front plugin 名，不是 npm 包名。
- npm 依赖只写 `front/package.json`。
- 节点名加组件前缀，避免与内置节点或其它组件冲突。
- 节点 props 和共享能力只依赖公开 SDK/compat，不 import 宿主 `front/src` 私有路径。
- 模块顶层不发请求、不读业务配置、不写全局状态、不启动副作用。

Runtime 会根据当前 Page 使用的 node type 匹配插件，先加载 `depends`，再注册节点。不要为了普通本地插件手写 `setting.runtime.plugins`；外部 URL 或特殊 runtime 注入才由站点配置显式声明。

## 复用和拆分

- 多个页面使用同一交互时，注册一个意图明确的节点，通过 props/meta 配置差异。
- 只有一个组件使用的节点留在该组件，不放进 `package/front`。
- 通用节点只有在确实跨多个组件复用、协议稳定且不包含业务语义时，才进入宿主 front/runtime。
- 不创建复制宿主组件的私有 UI 工具层；先查公开 SDK。

## Dev 和 Build

- `dever run`：本地可编辑插件缺少 dist manifest 且存在 `front/src/plugin.ts` 时，使用项目级 Vite source server。
- `dever front build [name]`：构建指定/本地可编辑插件，staging 校验通过后替换 `front/dist`。
- `dever build`：先构建本地可编辑插件，再构建 Go 二进制；不会隐式构建宿主 `front/src`。
- 宿主发布：维护者单独运行 `pnpm --dir front build:backend`。

插件和宿主构建不是同一个入口。用户禁止 build/test 时不运行上述命令；仅修改本规范也不需要构建。

## 修改前后检查

- 先读目标组件自己的 `skills/**/SKILL.md`。
- 确认 Page runtime 没有现成节点或组合能力。
- 节点名、插件名和依赖名是否稳定且无冲突。
- 插件是否只负责交互，业务写入是否仍经过后端权限和 Service。
- 是否只使用公开 SDK，没有依赖宿主私有源码路径。
- 发布 package 是否包含经构建生成的 manifest，而不是手写产物。
