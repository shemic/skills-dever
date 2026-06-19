Dever package 开发目录。

普通项目不需要保留 package 源码；执行 dever package <name> 后只保留 module/<name>/main.go shim。

只有框架/package 开发仓库才在这里保留本地 package 源码，并通过 go.mod replace 接入。
