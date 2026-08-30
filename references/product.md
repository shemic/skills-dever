# 从产品需求到 Dever 实现

完整产品需求先拆业务资源、业务动作、角色和页面，再选择 Dever 能力。不要从“生成 CRUD 接口”开始。

## 1. 先列业务事实

对每个需求回答：

1. 谁使用：站点、角色、登录或公开访问边界。
2. 管理什么：持久化资源、配置、文件或外部对象。
3. 用户执行什么业务动作：发布、审批、安装、绑定、运行、结算等。
4. 哪些只是普通增删改查。
5. 哪些不变量必须由服务端保证。
6. 是否存在外部系统、长任务、文件流、回调或复杂交互。

先产出资源和动作清单，不产出默认 API 清单。

## 2. 资源矩阵

| 资源 | 字段/关联 | 普通页面 | 真实业务动作 | 权限/归属 |
| --- | --- | --- | --- | --- |
| 示例：产品 | 名称、编码、状态 | 列表、编辑、详情 | 发布、下架 | 产品管理员 |
| 示例：版本 | 产品、版本号、安装包 | 列表、上传、详情 | 发布、撤回 | 发布管理员 |
| 示例：实例 | 产品、设备标识、当前版本 | 列表、详情 | 绑定、升级 | 客户/运维 |

普通页面直接映射到 Model + Page JSON。只有“真实业务动作”进入 Service 设计。

## 3. 能力映射

| 产品事实 | Dever 所有者 |
| --- | --- |
| 表结构、索引、枚举、关联 | Model |
| 后台列表、表单、详情、普通保存/删除 | Page JSON + package/front |
| 保存前后动态适配 | `service/**` 中的 Provider 方法 |
| 业务不变量、事务、状态流转、外部调用 | 普通 Service 方法 |
| HTTP/回调/流式/文件协议 | 薄 API + Service |
| Page 无法表达的复杂客户端交互 | front plugin |
| 站点所有权、API 前缀、public/auth | `dever.json.front.sites` |

不要为每个资源自动创建 Create/List/GetInfo/Update/Delete Service 和 API。

## 4. Service 用例矩阵

只有真实业务动作进入矩阵：

| 用例 | 输入 | 不变量/事务 | 输出 | 入口 |
| --- | --- | --- | --- | --- |
| 发布版本 | 产品 ID、版本、包 | 版本唯一、签名完整、状态流转 | 发布记录 | admin API/Page hook |
| 绑定实例 | 凭据、实例标识 | 凭据有效、只绑定一次 | 绑定结果 | client API |
| 执行升级 | 实例、目标版本 | 产品匹配、版本递增、原子替换 | 升级状态 | client Service/CLI |

如果一行没有业务不变量，只是单表 CRUD，就从矩阵删除并交给 Model + Page JSON。

## 5. 页面信息架构

对每个站点列出：

- 菜单分组和可见 list 页面。
- 隐藏的 create/update/detail 页面及其 `page.parent`。
- Model 自动推导能覆盖的字段、Options、Relations。
- 需要 Provider hook 的保存动作。
- 需要独立业务 API 的按钮或插件交互。

页面目录跟随拥有资源的 component；site 的物理 page 目录不自动进入 route。具体协议读 [front-page.md](front-page.md)。

## 6. 组件边界

- 项目私有业务放 `module/<name>`。
- 多项目复用且边界稳定时才发布 package。
- 核心业务实现始终在 component 的 `service/`。
- component 根目录只保留 framework/资源入口，不按产品动作创建 installer/updater/server 等平行业务目录。
- 公共 runtime 只解决多个 component 的共同问题，不吸收单个产品逻辑。

## 7. 最小交付清单

完整业务实施计划只列实际需要的内容：

- Model 和索引清单。
- Page、菜单和权限清单。
- 有真实不变量的 Service 用例清单。
- 必要的 Provider 注册名。
- 必要的 API 路由和公开/鉴权边界。
- 必要的 front plugin 节点。
- 最小验证和未执行项。

空类别写“无”，不要用空 Service、空 Provider、预留 API 或占位目录填满架构图。
