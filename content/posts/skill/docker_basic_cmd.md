---
title: "Docker 常用命令"
date: 2020-04-07T22:46:53+08:00
lastmod: 2020-04-09T23:04:00+08:00
draft: true
categories:
    - docker
tags:
    - docker
---

接下来我将为大家介绍一些 Docker 的常用命令。

<!--more-->

#### 基本信息

首先，在我们安装完 Docker 之后，我们可以先看一下 Docker 的基本配置信息，就可以通过下面的命令进行了解，它会列出一些基本的信息，如 Client 的信息，还有一些 Server 的信息，如容器、镜像的数量，CPU 等等，具体的内容大家可以自行查看。

```shell
docker info	

Client:
 Debug Mode: false

Server:
 Containers: 25
  Running: 13
  Paused: 0
  Stopped: 12
 Images: 24
 ...
```

#### 镜像

接下来了解一下镜像相关命令，前面提到过，镜像是我们容器的模板，用于创建具体的容器实例。

**镜像信息**

`docker images `显示镜像相关的信息，如仓库名、标签名、镜像ID、创建时间、镜像大小等。

一个镜像可以有多个标签名，但是镜像ID是唯一的。镜像体积大小和Docker Hub上的大小不同，Docker Hub上的显示的压缩后的镜像大小，而使用`docker images`则显示的解压后的镜像大小。

`docker images` 列出的所有镜像和并不是最后所有镜像所占用的体积，应为docker镜像是多层存储结构，并且可以继承、复用，因此不同镜像可能会因为使用相同的基础镜像，从而拥有共同的层。因此实际体积比列出的所有体积和要小。可以使用`docker system df`查看镜像所占用的总体积。

**虚悬镜像**：仓库名和标签名都为`<none>`的镜像就是虚悬镜像。这种现象是由于镜像更新，重新拉取镜像后仓库名和标签名移到了新的镜像上`docker pull repository:tag`。一般来说，虚悬镜像已经没有什么用处了，可以直接删除了，`docker image prune`

**中间层镜像**：为了复用资源，docker会利用中间层镜像来构建顶层镜像，`docker iamges`列出的顶层镜像，使用`docker image ls -a`则会列出所有的镜像。

```shell
  docker images
  docker image ls
  docker iamge ls -a
  docker image ls repository
  docker image ls repository:tag
  docker image ls -f since|before=repository:tag	# 列出在镜像某个版本前|后的镜像
  docker image ls -f label=？	# 列出标签为某个值的镜像
  docker iamge ls -q	# 列出所有镜像ID
  docker image ls --format "{{.ID}:{.Repository}}"	# 只列出ID和仓库名
  docker image ls --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}"	# 以表格的形式列出数据
  docker image ls --digests #显示镜像摘要
  
  docker system df	#查看镜像占用空间情况
  
  docker image prune	#删除虚悬镜像
```

**查找、拉取、推送镜像**

`docker pull` 默认地址为Docker Hub，一般是 `IP:PORT`，仓库名是两段式名称，即 `用户名/软件名`，默认用户为 `library`。

```shell
docker search image_name

docker pull [选项] [Docker Registry 地址[:端口号]/]仓库名[:标签]
docker pull image_name

docker push image_name
```

**查看镜像的历史版本**

```shell
docker history image_name:tag
```

**删除镜像**

镜像可以是docker的短ID、长ID、镜像名、仓库名：标签名、镜像摘要，

```shell
docker image rm [选项] <镜像1> [<镜像2> ...]

docker image rm $(docker image ls -q -f before=mongo:3.2) #可以批量删除多个镜像
```

**查看镜像的修改**

```shell
docker diff container_name
```



#### 容器

**启动、停止、重启容器**

`docker run` 启动容器，

```shell
docker run -it --rm ubuntu:16.04 /bin/bash
-i		# 表示交互式操作
-t		# 表示终端
bash 	# 表示使用bash终端进行交互
--rm	# 表示退出容器后将容器删除，可以避免浪费空间
ubuntu:16.04	# 表示镜像名称
--name	# 定义镜像启动容器的名字
-p 80:80	# 端口映射,docker内的端口80映射到本机的80端口
-d		# 表示以后台形式运行，输出结果可以使用 docker logs container_name 查看
-v	# 挂载本地磁盘到容器内，使得容器可以访问，`-v local_dir:container_dir:pri`,启动容器的时候可以限制本地目录的权限，`rw`和`ro`读写和只读权限。


--restart	# 表示容器重新启动，检查容器退出代码，决定是否重启，默认不重启，当参数为`always`的时候（`--restart = always`）无论退出代码为什么都会重启，`on-failure`则表示只有当退出代码为非0的时候才会重启，`on-failure`还支持重启次数参数`on-failure:5`表示最多尝试重启5次。
```

```shell
docker run image_name
docker run -it --rm ubuntu:16.04 bash
docker run --name webserver -d -p 80:80 nginx
docker exec -it webserver bash	#以bash交互方式启动webserver容器

# 启动已终止的容器
docker container start container_naem
docker start container_name

#终止容器
docker container stop container_name
docker stop container_name

#重启容器
docker container restart container_name
docker restart container_name

#???
docker create ...
```

**查看容器**

```shell
docker container ls
docker ps -a     # 查看所有容器信息
docker ps  		 # 查看所有运行中的容器信息
docker ps -l	 # 查看最后一个运行的容器
docker ps -n n	 # 显示最后n个容器
docker ps -q  	 # 只显示容器id
```

**进入容器**

`docker attach` 在容器终端中输入`exit`会导致容器停止，而 `docker exec` 命令则不会

`docker exec`有参数`-i`、`-t`，如果只有`-i`可以使用命令但是不会有终端提示符，只有含有参数`t`之后才会显示。`docker exec`除了可以交互式执行shell命令外，还能直接执行其他命令：`docker exec -d container_name touch /etx/new_config_file.conf`

```shell
# 在容器终端中输入exit会导致容器停止
docker attach container_name|ID

docker exec -it container_name|ID bash
```

**容器变更**：查看容器内容的变更

```shll
docker diff container_name
```

**删除容器**

```shell
  docker container rm container_name|ID
  docker rm container_name|ID
  
  # 清除所有终止容器
  docker container prune
  
```

**容器日志**

```shell
docker log container_name
#动态查看日志输出，如tail -f jid
docker log -f container_name 
```

**容器状态查看**

 ```shell
docker top container_name	# 查看容器内部进程，user，pid信息

docker stats container_name #查看容器系统资源的占用情况，包括cpu，内存，I/O
 ```

**容器导出、导入**

导入镜像和导入容器快照的区别在于：*容器快照文件将丢弃所有的历史记录和元数据信息（即仅保存容器当时的快照状态），而镜像存储文件将保存完整记录，体积也要大。此外，从容器快照文件导入时可以重新指定标签等元数据信息。*

```shell
docker export containerID > file_name

# 倒入容器快照
cat file_name | docker import - repository/image:tag
docker import http://example.com/exampleimage.tgz example/imagerepo

#导入镜像
docker load 
```

**将容器当前状态保存为镜像**

`--author` 是指定修改的作者，而 `--message` 则是记录本次修改的内容。

一般不适用docker commit对镜像进行修改，因为仅仅修改一处，就会导致很多的修改历史，而且修改的历史很臃肿，其他人很难知道修改了什么。而且修改只能在当前层进行修改，其他层是不会改动的。即使删除了也会一直存在，所以镜像会变得很臃肿。

```shell
docker commit [选项] <容器ID或容器名> [<仓库名>[:<标签>]]
docker commit job_name image_name
docker commit --author "" --message "" container_name images_name
```

#### 挂载

**数据卷**

```shell
docker volume ls									# 查看volume列表
docker volume rm volume_name			# 删除volume
docker volume create volume_name	# 创建volume
docker volume inspect volume_name	# 查看数据卷详细信息
docker inspect container_name 		# 查看容器详情
docker volume prune								# 删除空余数据卷
# 容器挂载数据卷
docker run -d -P --name container_name \
--mount source=volume_name,target=container_path image_name bash
```

**挂载主机目录**

```bash
# -v 如果本地路径不存在，会自动创建
docker run -it --name test7 -v /Users/jankeyfu/sharedir/:/data ubuntu bash

# 目录必须是绝对路径，不能是相对路径
docker run -it --name test9 --mount type=bind,source=/Users/jankeyfu/sharedir,target=/data,readonly ubuntu bash
```


#### 网络

**创建网络**

```shell
docker network create net_name
```


**查看网络状况**

```shell
docker network inspect net_name
```

**查看网络列表**

```shell
docker network ls
```

**添加或移除已有容器到网络中**

```shell
docker network connect net_name container_name
docker network disconnect net_name container_name
```

  
