---
title: "MySQL EXPLAIN"
date: 2019-08-26T10:07:21+08:00
lastmod: 2020-04-05T22:21:12+08:00
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

#### id

查询标识，标识查询的顺序，次字段可能为空，当有`Union`联合查询的时候，有一行数据中的id将会是空，表示是从联合数据`<unionM,N>`中查询。id相同时执行顺序自上而下。

![image-20190826205614663](/img/image-20190826205614663-6824289.png)

#### select_type

| select_type  |                    解释                    |
| :----------: | :----------------------------------------: |
|    simple    |         不使用 `union` 或者子查询          |
|   primary    |     最外层查询：union 的第一层查询...      |
|    union     | union 查询中第二个查询的表或者之后查询的表 |
| union_result |        union 查询中间过程的联合结果        |

#### type

- **system** 官方文档介绍说当表中只有一行数据的时候，显示的连接类型即为 `system` ，但是在实际测试中，一致没有出现，我的 `MySQL server` 版本是 `5.7.26`。

- **const** 查询结果只有一条数据，一般是使用 `primary key` 或者 `unique key` 进行查询时为这种连接类型，`const` 查询类型非常快。

  ```mysql
  -- id为primary key
  EXPLAIN SELECT * FROM employee WHERE id = 1;
  ```


- **eq_ref** 在连接查询中，使用连接表中某一张表的主键或者非空唯一建作为主键进行查询，每一次只会从前面的表中读取一行数据。（ps：一般是前一张表的数据查询结果比当前表的多）

  ```mysql
  -- e.code 为unique_key
  EXPLAIN SELECT * FROM employee_extend ee 
  JOIN  employee e on e.CODE = ee.CODE
  ```

- **ref** 在连接查询中，使用当前表的索引字段查询联合数据中的项。

  ```mysql
  -- e.department_id 为普通key
  EXPLAIN SELECT * FROM employee e 
  JOIN employee_extend ee ON e.CODE = ee.CODE
  WHERE e.department_id = 2
  ```

- **fulltext** 在连接查询中，使用全文索引字段查询数据

  ```mysql
  -- introduction 为fulltext索引
  EXPLAIN SELECT * FROM employee WHERE match(introduction) against ("王五*" in boolean mode)
  ```

- **range** 使用索引的区间进行数据筛选，如 `IN` , `BETWEEN a AND b`, 

  ```mysql
  -- department_id 为索引字段
  EXPLAIN SELECT * FROM employee WHERE department_id in(1,2)
  ```

- **index** 全索引字段扫描，通常出现在查询的字段为索引字段且不包含查询条件的情况，和 all 进行全表扫描类型，但是索引字段数量通常比全表数据要小得多，除了唯一索引。

  ```mysql
  -- id 为primary_key
  EXPLAIN SELECT id FROM employee
  ```

- **all** 全表扫描，如果第一张表的查询方式是 all，这是非常不合适的，有严重的性能问题，需要增加索引进行优化。

  ```mysql
  -- name 为非索引字段
  EXPLAIN SELECT * FROM employee WHERE NAME = '张三'
  ```

