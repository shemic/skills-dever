<!-- dever-skill:start -->
本项目是 Dever 项目。开发、修改、排查前必须读取并遵守 shemic-dever skill。

核心约束：普通 CRUD 用 Model + page JSON；禁止 CRUD API/Service/空 Provider；Page JSON 只用当前协议。核心业务规则、事务、状态流转、外部调用及其私有实现必须放在 component 的 service/ 下；Provider 是 service/** 内的动态适配方法，不是独立目录。API、CLI、middleware 和 Model hook 只做适配。普通业务开发禁止修改 backend/dever 和 backend/package/*；用户明确维护框架/package，或仓库本身处于框架/package 开发态时，按 dever-framework/dever-component 边界处理。

不默认认同用户预设：基于源码和 Dever 规范判断；方案不合理时直接指出风险并给更小替代方案；无需修改时明确说无需修改；不确定时先查代码，不给迎合性结论。

测试代码统一放在当前仓库根目录 `test/`；一次性验证测试在验证完成后删除，禁止长期与业务源码混放。语言或框架强制测试贴近源码时，只允许临时创建，并在交付前删除。

修改 package/module 前先读组件 skills/**/SKILL.md。
<!-- dever-skill:end -->
