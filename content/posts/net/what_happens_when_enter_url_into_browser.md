---
title: "当你在浏览器中输入网址后都发生了什么？"
date: 2019-07-20T15:06:54+08:00
draft: true
categories:
    - 网络
tags:
    - http
---

“在浏览器中输入网址后，背后都发生了什么事情“这个问题，想必很多人都很好奇。从不同的角度有不同的分析，有硬件相关的知识，也有软件相关的知识，本文只着重介绍软件相关的知识点。

<!--more-->

整个过程可以总结为下图，主要涉及的三个大步骤，浏览器，DNS服务器，以及目标网址对应的服务相关内容。

![整体流程图](https://jankeyfu-blog.oss-cn-beijing.aliyuncs.com/http_browser.svg)

##### 缓存

如果请求的是静态资源并且缓存策略设置允许缓存，则会从浏览器缓存中直接读取静态文件直接进行渲染，省去了后续其他步骤。

##### DNS解析

> DNS（Domain Name Server，域名服务器）是进行域名(domain name)和与之相对应的IP地址 (IP address)转换的服务器。DNS中保存了一张域名(domain name)和与之相对应的IP地址 (IP address)的表，以解析消息的域名。

由于所有的HTTP请求都是基于TCP/IP协议栈的，所以要发起HTTP请求就必须知道目标服务器的IP地址，因此通过获取域名对应的IP地址是必不可少的。

![缓存流程图](https://jankeyfu-blog.oss-cn-beijing.aliyuncs.com/http_cache.svg)

- **浏览器DNS缓存**：一般浏览器会记住一些dns的信息，以便提升浏览器的速度。因此当访问一个网站的时候，如果浏览器缓存有其对应的IP地址，则可以直接取来使用。
- **系统DNS缓存**：通常也就是我们hosts文件中配置的域名与IP的映射关系，当浏览器中没有对应的域名关联关系时，则会去查询系统的hosts配置文件，寻找网址对应的IP地址。
- **路由器DNS缓存**：当系统DNS缓存找不到对应IP时，使用路由器中的缓存信息查找。
- **ISP DNS缓存**：网络服务提供商会提供域名解析服务，其会保存有一些域名与IP的映射关系。
- **递归DNS解析**：当上述所有方法都无法找到域名对应的IP地址时，ISP DNS服务器则会从根服务器去查询。如以`www.google.com`为例，根服务器查询不到，则查询`.com`DNS服务器，然后查询`.google.com`DNS服务器，直到找到域名对应的IP地址为止。

##### HTTP请求

当获取到IP地址之后，则可以向服务器发起网络请求了，请求流程图如下

![http请求流程图](https://jankeyfu-blog.oss-cn-beijing.aliyuncs.com/http_tcp.svg)

- **建立网络连接**：http协议是基于TCP/IP协议族的应用层协议，因此在进行通信需要建立连接，也就TCP三次握手。

- **发起HTTP请求**：http请求有多种方式，比较常用的是`GET`和`POST`请求，`GET`请求以参数拼接在url上进行传递，而`POST`则不是。请求格式如下：主要包含请求行，请求头，请求体
```
GET / HTTP/1.1
Host: www.google.com
Connection: keep-alive
Pragma: no-cache
  
q=http&oq=http
```

- **服务器响应**：http响应包含响应行，响应头和响应体三部分。具体格式如下。

```
HTTP/1.1 200 OK
Cache-Control: private
Connection: Keep-Alive
Content-Encoding: gzip
    
<!doctype html>
...
```

- **维持连接/断开连接**：在HTTP/1.0中，默认使用的是短连接，浏览器和服务器每进行一次HTTP操作，就会建立一次连接，当任务结束后就中断连接。在http/1.1中默认使用长连接，用以保持通信连接继续下一次http请求而不需要再重新建立连接，使用长连接的HTTP协议，会在响应头有加入这行代码`Connection:Keep-Alive`
- **浏览器解析**：由于访问一个url之后对应的文件并不止一个，有html、js、css样式文件，图片等资源文件，异步调用接口数据等，这些逻辑都和上诉所讲述的一致，都需要经历上述那些过程。在这些资源文件的获取过程中，浏览器会将这些文件进行解析渲染，最终呈现在我们面前的就是一个解析完成之后的网页，具体是怎么解析的，感兴趣的同学可以去好好了解一些前端的知识。

大体上在浏览器中输入一个url，后续所发生的事情就是这么些，因为不是专业前端，所以一些细节没有讲解地很到位。不过在大体框架上，就是这么一个流程。后续更多细节性的东西可以去搜索好好了解下。

##### 参考

- http://igoro.com/archive/what-really-happens-when-you-navigate-to-a-url/

- https://zhuanlan.zhihu.com/p/43369093

