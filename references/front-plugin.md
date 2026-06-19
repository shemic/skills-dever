# Front Plugin

只有 page JSON 表达不了的强交互才写 front plugin，例如画布、工作台、流程编辑器、复杂表格和实时交互。

## 边界

- Page JSON 能做的列表、编辑、详情、option、状态、排序，不写插件。
- 插件只负责 UI、交互、节点注册。
- 登录、保存、业务动作、事务和外部调用放 API/Service。
- 不直接 import 主 `front/src` 私有实现；优先使用公开 SDK。

## 文件

```txt
package/<name>/front/src/plugin.ts
package/<name>/front/package.json
package/<name>/front/dist/manifest.json
```

发布 package 时，有 `front/src/plugin.ts` 就必须有有效 `front/dist/manifest.json`。

## plugin.ts

- 注册插件名、节点和依赖。
- `depends` 写 Dever front plugin 名，例如 `"crm"`，不是 npm 包名。
- npm 依赖写 `front/package.json`。
- 节点名加组件前缀，避免和内置节点冲突。
- 不在模块顶层做请求、读配置、写全局状态或启动副作用。

## dev/build

- `dever run` 在没有 dist manifest 时启动插件 dev server。
- `dever front build [name]` 构建本地可编辑插件。
- `dever build` 默认先构建前端插件。
- 用户禁止 build/test 时不要运行这些命令。

## 组件边界

修改 `package/bot` 画布、`package/crm` 工作台等插件前，必须读组件自己的 `skills/SKILL.md`。不要把组件私有 UI 逻辑放到 `package/front`。
