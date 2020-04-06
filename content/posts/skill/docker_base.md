---
title: "Docker基础知识"
date: 2020-04-06T16:30:34+08:00
lastmod: 2020-04-06T19:47:15+08:00
draft: true
categories:
    - docker
tags:
    - docker
---

Docker 是一个用于开发、交付和运行应用程序的开放平台。Docker 将我们的应用与基础架构分开，从而实现软件的快速交付。通过 Docker 可以创建统一的开发环境，让我们更专注于代码的编写，而不必分心于环境的配置问题。

<!--more-->

#### Docker 引擎

![](https://docs.docker.com/engine/images/engine-components-flow.png)

Docker 引擎是一个 C / S 架构的应用程序，其包含以下几个部分：

- server：持续运行的守护进程（dockerd 命令），通过监听 Docker API 的请求来管理 docker 对象如，镜像、容器、网络等，一个 server 也可以与其他的 server 通信，以便管理整个 docker 服务

- REST API：客户端与守护进程（服务端）之间通信的渠道
- CLI：也就是终端命令（docker 命令），通过 API 与 docker daemon 进行通信。



#### 基础概念

加下来我们来看看 Docker 中的几个基础概念，以便我们对 Docker 有更好的了解。

- **镜像**：创建容器的只读模板，一般是一个微型的系统，如 Ubuntu 镜像；当然我们也可以在一个镜像的基础上加上自定义的内容，形成一个新镜像，如再ubuntu镜像的基础上安装 nginx 等形成一个 nginx 镜像。

- **容器**：基于镜像的一个运行实例，是我们的应用实际运行的地方。可以通过 Docker API 进行创建、启动、停止、销毁等操作。

- **仓库**：类似于代码仓库，只不过不是存储代码的，而是存储镜像的。仓库由两部分组成如`dl.dockerpool.com/ubuntu`，`dl.dockerpool.com `表示的是注册地址，`ubuntu `表示的是一个项目的仓库名

- **Docker Hub**

  ```shell
  # 登录docker hub
  docker login
  
  # 登出docker hub
  docker logout
  
  # 在仓库中搜索docker镜像[查找收藏数在N以上的镜像]
  docker search image [--filter=stars=N]
  
  # 推送镜像至docker hub
  docker tag iamge:tag username/image:tag
  docker push username/image:tag
  ```

  

