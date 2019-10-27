---
title: "Prometheus + Grafana 配置系统监控"
date: 2019-10-27T14:43:13+08:00
draft: true
categories:
    - 架构
tags:
    - monitor
---

最近上线系统出了一些问题，但是上完线之后都没有发现，直到外围报出问题去定位才解决。因此想着是不是应该给系统加上监控和报警，以便能够在系统出现问题的第一时间去解决。于是去研究了一波`prometheus + grafana`相关的资料。

<!--more-->

先简单介绍一下`prometheus` 和 `grafana` 。prometheus 是一款开源的系统监控和报警工具，它通过收集用户打点的数据，对数据进行聚合计算等操作，同时可以通过对结果数据进行报警配置，当结果超过阈值即可触发报警，以便用户能够及时了解系统出现的问题；而 `grafana` 主要是一款数据展示，和数据报警的开源工具，它可以从不同的数据源中获取数据进行展示，`prometheus` 就是其中一个，结合已上两个开源工具，就可以实现 `prometheus` 收集数据，`grafana`展示数据并配置报警的功能。

#### Metric

先介绍一些基本的知识点，在prometheus 中，单个数据集合叫 **metric** , 每个metric 都可以拥有多个 **label**。如有一个统计 http 请求的metric 叫 http_handle_total , 它可以拥有不同类型的 label 如 method 和 http_code 等，表示这个数据是 GET 请求或者 POST 请求，以及请求的 http 状态码是多少等。

数据打点的方式主要有 `Counter` ，`Gauge` ,`Histogram` 和 `Summary` ，此处只介绍前两种，剩余的请移步[官网](https://prometheus.io/docs/concepts/metric_types/#summary)， **Counter** 类型的数据点**只能增加数值**或者将数值重置为0，如 http_requests_total 这个点，在每一次请求过来的时候，我们我们可以使用 Counter 类型，对其计数加一，这样我们就能知道一共有多少次 http 请求了。**Gauge** 数据类型是一种即可以增加也可以减少的数据类型，一般表示一些只观察当前状态值的数据，如温度，内存使用情况等等。

#### PromQL

接下来介绍一些简单的查询语法，对于一些 metric 数据直接使用 metric 名字作为查询语句，可以得到这个metric 所有的数据信息，如

```prometheus
http_requests_total
```

如果需要查询这个metric 某个 label 的数据，可以使用一下操作符进行查询：

- `=` 表示精确匹配查询值

- `!=` 表示 label 值不等于查询值
- `=~` 正则匹配查询值
- `!~` 正则不匹配查询值

```prometheus
http_requests_total{method = "POST"}
http_requests_total{method != "POST"}
http_requests_total{method =~ "post | POST" }
http_requests_total{method !~ "post | POST" }
```

#### Examples

prometheus 还有很多其他内置的函数如 `abs` , `min` , `max` , `sum` 等等数学函数，具体使用可以翻看[手册](https://prometheus.io/docs/prometheus/latest/querying/functions/)，接下来介绍一些使用的数据打点以及查询的案例。以后有遇到其他的基础查询SQL，再不断补充。

##### QPS (Counter)

```shell
# 项目QPS
sum (irate(http_requests_total{project="you_project"} [1m]))
# 项目每个接口的QPS
sum(irate(http_requests_total{project="you_project"}[1m])) by (api_name)
# 项目非正常返回数据的QPS
sum(irate(http_requests_total{project="you_project",code != "200"}[1m])) by (api_name)
```

##### Error Rate (Counter)

```shell
# 接口返回非200占总接口处理中的百分比，之所以后面加上0.00001是为了防止分母为0
(sum(irate(http_requests_total{project="you_project",code!="200"}[1m])) by (api_name)) / sum(irate(http_requests_total{project="you_project"}[1m])+0.00001) by (api_name)) * 100
```

##### Latency (Counter)

```shell
# 系统接口响应时间 
# http_handling_seconds_sum 记录接口响应时间counter
# http_handling_seconds_count 记录接口响应次数
max(irate(http_handling_seconds_sum{project="you_project"}[1m])) / max(irate(http_handling_seconds_count{project="you_project"}[1m]) > 0)

# 系统不同接口响应时间 
max(irate(http_handling_seconds_sum{project="you_project"}[5m]) / irate(http_handling_seconds_count{project="you_project"}[5m]) > 0)by(api_name)
```

##### CPU (Counter)

```shell
# 统计 cpu 最大使用率
max (irate(cpu_usage_seconds_total{instance="you machine"}[1m])) by (instance)
```

##### Memory (Gauge)

```shell
# 统计 内存 使用情况
sum (memory_working_set_bytes{instance="you machine"}) by (instance) / 1024 / 1024
```

#### grafana

grafana的配置主要集中在 PromQL的设计上，分析自己需要那些数据，通过PromQL 从 prometheus 中查询获取，最后会展示在面板上。此处就不多介绍，具体可以看看[官方文档](https://grafana.com/docs/)

![](https://jankeyfu-blog.oss-cn-beijing.aliyuncs.com/grafana_promql.png)

grafana 还可以设置邮件报警，通过设置一个报警阈值，将查询结果与阈值进行比较，每个图表都可以设置多个阈值条件，只要其中一个满足条件，即可触发报警；在下方配置中添加报警的邮件组，以及设置报警的具体内容；在配置完报警条件后，可以通过 `Test Rule` 按钮对规则进行测试，看看当前数据是否有满足规则的；也可以通过 `Statu history` 按钮查看历史转态，查看哪个时间点数据触发了报警机制。 

![](https://jankeyfu-blog.oss-cn-beijing.aliyuncs.com/grafana_alert.png)



> https://prometheus.io/docs/introduction/overview/
>
> https://grafana.com/docs/guides/getting_started/

