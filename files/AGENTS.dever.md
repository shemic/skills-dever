<!-- dever-skill:start -->
本项目是 Dever 项目。开发、优化、重构、排障、代码审查、安全/性能分析，或修改 model、service、api、provider、page JSON、front、package、module、dever.json、config/front、Dever CLI 前，必须读取并遵守 shemic-dever skill。

先判断角色：dever-app / dever-front-page / dever-front-plugin / dever-component / dever-framework / dever-review / dever-skill-maintainer。角色不明时只盘点，不生成、不删除。

默认是 dever-app。涉及 page JSON、route/action/option、权限、菜单、后台页面、工作台页面时必须叠加 dever-front-page。涉及 front/src/plugin.ts、React 节点、画布、复杂自定义交互时叠加 dever-front-plugin。

普通业务默认禁止修改 backend/dever、backend/package/*、生成文件和编译产物；只有用户明确要求维护框架或 package 时才进入 dever-framework/dever-component。

普通 CRUD 优先使用 Model + package/front + page JSON；禁止无意义 CRUD API、CRUD Service、空 Provider。

Page JSON 只用当前协议：能自动推导的不写；不能推导才写对应位置的 model/service；禁止旧字段和历史兼容写法。

自定义 API 按站点/用途放到 api/<scope> 子目录，并在 dever.json.front.sites.<site>.api 声明对应前缀；不要新增 apiAliases/apiRoots/internal。

修改 package/module 前，先读取该组件 skills/**/SKILL.md。
<!-- dever-skill:end -->
