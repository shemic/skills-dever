<!-- dever-skill:start -->
本项目是 Dever 项目。开发、优化、重构、排障、代码审查、安全/性能分析，或修改 model、service、api、provider、page JSON、front、package、module、dever.json、config/front、Dever CLI 前，必须读取并遵守 shemic-dever skill。

先判断角色：dever-app / dever-front-page / dever-front-plugin / dever-component / dever-framework / dever-review / dever-skill-maintainer。角色不明时只盘点，不生成、不删除。

默认是 dever-app。涉及 page JSON、route/action/option、权限、菜单、后台页面、工作台页面时必须叠加 dever-front-page。涉及 front/src/plugin.ts、React 节点、画布、复杂自定义交互时叠加 dever-front-plugin。

不要默认认同用户预设。每次先基于源码、配置和 Dever 规范判断；方案不合理时直接指出风险并给更小替代方案；无需修改时明确说无需修改；不确定时先查代码，不给迎合性结论。

普通业务默认禁止修改 backend/dever、backend/package/*、生成文件和编译产物；只有用户明确要求维护框架或 package 时才进入 dever-framework/dever-component。

普通 CRUD 优先使用 Model + package/front + page JSON；禁止无意义 CRUD API、CRUD Service、空 Provider。

Page JSON 只用当前协议：能自动推导的不写；不能推导才写对应位置的 model/service；禁止旧字段和历史兼容写法。

修改 package/module 前，先读取该组件 skills/**/SKILL.md。

每次执行非纯问答任务后，最终回复必须明确说明：
- 状态：已完成 / 部分完成 / 未完成 / 阻塞。
- 已完成：只列实际完成的改动、分析或排查结果。
- 验证：列出实际运行过的检查命令和结果；用户禁止 build/test 时必须明确说明未运行。
- 剩余：列出未做、未验证、需要用户手动确认或后续迁移的事项；没有剩余时写“剩余：无”。
- 不得把计划、推测、未运行的 build/test、未人工验证的 UI 或未执行的数据迁移说成已完成。
<!-- dever-skill:end -->
