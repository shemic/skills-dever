# 数据模板配置与调用

`package/front` 的数据模板用于少量、可配置、非固定业务表结构的后台配置数据。不要为了只有一两条配置的页面继续新增一张业务表；优先用“系统设置 → 数据模板”维护模板分类、模板和字段。

## 使用边界

- 模板必须填写 `template_key`，字段必须填写 `field_key`。两个 key 都是稳定调用编码，只能包含字母、数字、下划线、点和短横线；已有填写数据后不要再改。
- `record_json` 仍按 `field_id` 存储，避免字段展示名变化影响历史数据；对外调用时再转换为 `field_key`。
- 调用方优先使用 `front.datarecord.Editor.GetInfo` 返回的 `values`；不要直接读取或拼装 `data_record.record_json`。
- 当前 `GetInfo` 是“按模板 Key 读取单条配置记录”，对应 `target_id=0,target_record_id=0`。如果要按业务表记录维度存取扩展数据，先扩展 `datarecord` service，不要在业务代码里绕过 service 直查 `data_record`。

## 填写入口

- 需要让编辑人员填写数据时，在“系统设置 → 数据模板”维护分类、模板和字段。
- 再到“系统设置 → 权限管理”新增菜单：路径填 `front/data_record/set`，查询参数填 `cate_id=<模板分类ID>`，再给角色授权。
- 数据填写页是 `front/data_record/set?cate_id=<模板分类ID>`。页面会按分类加载启用模板，保存时走 `front.datarecord.Editor.BeforeSaveRecord`。

## 读取入口

后端读取单条模板配置用 `front.datarecord.Editor.GetInfo`。

参数优先传 `template_key`，也兼容：

- `templateKey`
- `key`
- `data_template_key`
- `dataTemplateKey`
- 直接传字符串模板 Key

示例：

```go
result := load.Service("front.datarecord.Editor.GetInfo", c, []any{
	map[string]any{"template_key": "company.about"},
})
```

也可以直接传模板 Key：

```go
result := load.Service("front.datarecord.Editor.GetInfo", c, []any{"company.about"})
```

page JSON 只需要加载某个模板数据时，可以配置 `data.xxx.service: "front.datarecord.Editor.GetInfo"`，并通过页面 query 传 `template_key`。

## 返回结构

`GetInfo` 返回：

- `template`：启用模板信息，包含 `fields`。
- `fields`：启用字段列表，已附带字段选项。
- `record`：原始数据记录；无记录时为空 map。
- `values`：稳定对外结果，按 `field_key` 映射，开发者优先使用。
- `raw_values`：按 `field_id` 映射，只用于排障或兼容，不作为业务调用契约。

字段值形态：

- 文本、日期、日期时间：字符串。
- 开关：bool。
- 单选、下拉：选项 value 字符串。
- 多选、多选下拉：字符串数组。
- 上传图片、上传视频、上传音频：文件对象数组。
