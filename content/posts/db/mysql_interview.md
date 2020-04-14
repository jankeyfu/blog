---
title: "MySQL 知识要点"
date: 2020-04-14T21:51:50+08:00
lastmod: 2020-04-14T22:49:05+08:00
draft: true
categories:
    - 数据库
tags:
    - mysql
    - interview
---

在日常开发过程中，有很多 MySQL 的基础要点会忽略，此文主要记录一些比较容易忽略的知识要点，或是提供一些常见问题的解决方案。

<!--more-->

**1、auto_increment 服务重启后在不同的存储引擎中的表现**

> **For InnoDB**
>
> In MySQL 5.7 and earlier, the auto-increment counter is stored only in main memory, not on disk.
>
> In MySQL 8.0, this behavior is changed. The current maximum auto-increment counter value is written to the redo log each time it changes and is saved to an engine-private system table on each checkpoint. These changes make the current maximum auto-increment counter value persistent across server restarts.

- InnoDB：在 5.7 之前，重启服务后，自增 ID 为数据表最大 ID，因为这个自增 ID 存在内存中，但是到了 8.0，MySQL 会将此参数值持久化下来，不会丢失原有的自增 ID 值。
- MyISAM：和 8.0 的 InnoDB 一样，会持久化此数据，即使重启服务也不会丢失。

**2、MySQL数据库 CPU 飙升如何处理？**

- 通过`show processlist` 查看是否有正在执行的慢查询，如有需要，通过命令 `kill ID` 将部分长时间查询的慢 SQL 查询干掉

