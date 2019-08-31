---
title: "MySQL EXPLAIN"
date: 2019-08-26T10:07:21+08:00
draft: true
categories:
    - 数据库
tags:
    - mysql
---

在日常开发工作中，你是否经常遇到自己写的sql执行时间过长影响系统性能的问题却无从下手？这时候你就需要一个工具，这就是`EXPLAIN`命令，它将全面分析我们所编写的sql语句，包括表的查询顺序，索引的使用情况以及预估的涉及数据量大小等等，接下来我们就一起来探索一下，如何分析我们写的sql语句的性能，以便写出更优，执行速度更快的sql吧。

<!--more-->

`EXPLAIN`命令的基本用法是，在`SELECT, DELETE, INSERT, REPLACE, UPDATE`这些sql的最前面加上`EXPLAIN`即可，其结果如下图所示。

![image-20190826102937756](https://jankeyfu-blog.oss-cn-beijing.aliyuncs.com/explain_demo.png)

我们先来看一下它的各个字段的含义，至于字段值，后面再详细地说明。

|     字段      |         释义         |
| :-----------: | :------------------: |
|      id       | 执行SELECT语句的标识 |
|  select_type  |      SELECT类型      |
|     table     | SQL语句所使用到的表  |
|  partitions   |       分布式表       |
|     type      |       连接类型       |
| possible_keys |  可能用到的索引字段  |
|      key      |    实际使用的索引    |
|    key_len    |     索引使用长度     |
|      ref      |     连接匹配关系     |
|     rows      |    估算记录的行数    |
|   filtered    |   被条件过滤的比例   |
|     Extra     |    查询的额外信息    |

##### id

查询标识，标识查询的顺序，次字段可能为空，当有`Union`联合查询的时候，有一行数据中的id将会是空，表示是从联合数据`<unionM,N>`中查询。id相同时执行顺序自上而下。

![image-20190826205614663](/img/image-20190826205614663-6824289.png)