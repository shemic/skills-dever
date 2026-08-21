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

- `dever run` 对本地可编辑插件使用项目级 Vite source server 和 virtual compat；开发源码请求不按生产 chunk 数验收。
- `dever front build [name]` 构建本地可编辑插件，先写 staging，通过 bundle audit 和 manifest 后处理后再替换 `front/dist`。
- `dever build` 默认先构建本地可编辑前端插件，再构建 Go 二进制；不隐式构建宿主 `front/src`。
- 宿主发布由维护者单独执行 `pnpm --dir front build:backend`，不要把它与插件构建合成一个入口。
- split 插件可在 `front/package.json` 的 `dever.bundleBudget` 声明自己的 JS/CSS、动态入口、小文件和静态闭包预算；不声明时框架只输出统计和执行通用结构检查。
- 用户禁止 build/test 时不要运行这些命令。

## 组件边界

修改 `package/bot` 画布、`package/crm` 工作台等插件前，必须读组件自己的 `skills/SKILL.md`。不要把组件私有 UI 逻辑放到 `package/front`。
