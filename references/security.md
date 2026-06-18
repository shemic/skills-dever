# 安全和权限

front 的便利能力必须放在明确的服务端权限检查之后。不要为了少写 page JSON 而牺牲安全。

## 权限默认规则

- API route 默认要求登录，除非明确配置为公开。
- Page action 继承当前站点访问模式。
- 公开页面和公开 route 必须有明确原因。
- 公开配置只写在组件 `dever.json.front.public` 或 `dever.json.front.sites.<site>.public`。
- `access.mode: "public"` 表示站点匿名可访问，但服务端仍必须做输入校验、字段过滤、上传保护和业务边界检查；不要把它当成关闭安全。
- 嵌入弹窗和子表必须保留父级 action 上下文；不要为了让它工作就开放通配权限。

## 通用 Action

通用 page action 可以提高开发效率，但不能允许客户端传任意表名或字段名后直接更新。

必须具备的保护：

- action key 从 page/model registry 解析。
- 按当前 site/user/role 做权限检查。
- 可操作的 model/action/field 清单来自服务端元数据。
- 服务端过滤字段。
- 客户端不能直接控制表名。
- 客户端不能直接控制 SQL 片段。
- 敏感修改要有审计或日志。

自动推导的 action 也遵守同样规则。空 `action` 配置不代表可以跳过权限检查。

## 密钥

- 模板和源码里不放真实 JWT secret、API key、数据库密码或 provider token。
- 文件模板使用 `replace_me` 占位。
- 日志和错误信息必须脱敏密钥。
- 绝不能把 provider 凭据返回给 page runtime。

## 上传

- 校验文件大小。
- 校验扩展名，可用时校验 MIME。
- 存储位置不能在源码目录内。
- 不允许路径穿越。
- 私有上传文件不能通过公开静态路由暴露。

## 外部端点

公开 callback/webhook 要求：

- provider 支持时校验签名或 token。
- 处理逻辑幂等。
- 状态流转可安全重试。
- 日志记录 request ID，不记录密钥。

## CORS 配置

开发环境可以使用宽松 CORS。生产配置应限制 origin 和 credentials。不要在 package 代码里硬编码宽泛 CORS。
