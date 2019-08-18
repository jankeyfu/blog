---
title: "Redis 数据结构 —— 字符串"
date: 2019-08-11T15:58:49+08:00
draft: true
categories:
    - 数据库
tags:
    - redis
---

redis 是一个基于C语言设计的开源的高性能的内存型数据结构存储系统，它可以用作数据库、缓存和消息中间件等。它支持以下五种数据格式： 字符串（strings）， 散列（hashes）， 列表（lists）， 集合（sets）和有序集合（sorted sets）。今天就从源码的角度分析一下这五种数据格式是怎么实现的。

<!--more-->

#### 字符串

##### Redis字符串操作命令

> `127.0.0.1:6379>` 为redis客户端显示内容

- 设置、获取key的内容，时间复杂度`O(1)`，当key不存在的时候，`GET`返回的值为`nil`，在2.6.12版本后，redis为`SET`命令增加了一些新参数，`EX`表示过期时间（单位秒）等价于`SETEX`命令，`PX`过期时间（单位毫秒）等价于`PSETEX`,`NX`只有当key不存在的时候才能设置成功等价于`SETNX`，`XX`只有当key存在的时候才能设置成功。
```shell
127.0.0.1:6379> SET key value
OK
127.0.0.1:6379> GET key
"value"
127.0.0.1:6379> GET nil
(nil)
127.0.0.1:6379> SET key value EX 10
OK
127.0.0.1:6379> SET key value PX 10
OK
127.0.0.1:6379> SET key value NX
OK
127.0.0.1:6379> SET key value XX
OK
127.0.0.1:6379> SET key value NX #当key存在的时候则设置不成功
(nil)
```

- 字符串追加命令`APPEND`，当key不存在的时候，次命令相当于`SET`，当key存在的时候，相当于在字符串后面拼接新的内容。时间复杂度`O(1)`

```shell
127.0.0.1:6379> APPEND key value
(integer) 5
127.0.0.1:6379> APPEND key "is 5 characters long"
(integer) 25
127.0.0.1:6379> GET key
"valueis 5 characters long"
```

  

  

---

> [《redis 设计与实现》  黄建宏](https://book.douban.com/subject/25900156/)
>
> [redis 中文网](http://redis.cn/)

