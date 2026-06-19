# 安全

front 的便利能力必须服从服务端权限和字段过滤。

## 权限

- API 默认需要登录，除非在组件 `dever.json` 显式 public。
- Page action 继承当前站点 access。
- `public` 站点匿名可访问，但仍需要输入校验、字段过滤、上传保护和业务边界。
- `login` 站点需要登录但绕过 RBAC。
- `rbac` 站点使用后台权限树。
- 不用通配权限修页面或 option 报错。

## Route Option

`route/option` 必须由 `path + key` 定位到服务端 page JSON，再解析 `option.model/service` 或 `meta.model/service`。

客户端不能直接传 model、service、字段名、SQL 片段决定数据来源。

## Action

通用 action 必须经过：

- 当前站点上下文。
- 登录/角色/API key 检查。
- page/action 权限。
- model/action/field 服务端白名单。
- 字段过滤。
- 操作日志或审计。

客户端不能直接控制表名或 SQL。

## 密钥

- 模板和源码不放真实 JWT secret、API key、数据库密码、provider token。
- 日志和错误脱敏。
- 不把 provider 凭据返回 page runtime。

## 上传和外部 URL

- 校验大小、扩展名、MIME。
- 存储位置不在源码目录。
- 拒绝路径穿越。
- 私有文件不能通过公开静态路由暴露。
- 导入 URL 要防 SSRF、限速、超时和大小限制。

## Webhook/Callback

- provider 支持时校验签名或 token。
- 处理逻辑幂等。
- 状态流转可安全重试。
- 日志记录 request ID，不记录密钥。
