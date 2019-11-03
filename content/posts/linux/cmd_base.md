---
title: "linux基础命令"
date: 2019-09-26T17:30:41+08:00
draft: true
categories:
    - linux
tags:
    - shell
---

对于刚接触到开发的同学，势必是需要了解一些基本的shell命令的，这些命令都是日常开发过程中使用很频繁的命令，以此作为笔记记录下来。

<!--more-->

#### 文件目录命令

##### ls (list directory content) 列出当前目录下的文件和文件夹

```shell
ls		#只展示文件名
ls -l	#展示文件名即其他文件信息，包括权限，日期等
ls -a	#展示隐藏文件
```

##### cd (change directory)跳转到指定目录路径

```shell
cd dir_name # 跳转到指定的目录路径下
~ 			# 跳转到用户目录下
.. 			# 跳转到上一级目录
. 			# 当前目录
```

##### cp(copy files)复制文件

```shell
cp [params] src_file desc_file
-r # 递归复制文件夹中的文件
-i # 如果目标文件存在会提示是否覆盖
cp src_file desc_file dir # 将文件复制到一个文件夹中
```

##### mv(move files) 移动文件

```shell
mv [params] src_file desc_file
-f # 强制移动文件，不提示是否会覆盖目标文件
-i # 如果目标文件存在会提示是否覆盖
mv src_file desc_file dir # 将文件移动到一个文件夹中
```

##### rm(remove directory entries) 删除文件

```shell
rm [params] file
-r # 递归移除目录中的文件
-f # 强制移除文件，不提示
-i # 提示是否移除目标文件
```

#### 内容查看命令

##### cat(concatenate and print files) 查看文件内容

```shell
cat [params] file
-n # 输出行号信息
-e # 展示不可打印字符，并将换行符替换为$输出
```

##### head(display first lines of a file) 展示文件前面内容

```shell
head [params] file # 默认显示文件前十行内容
-n num # 显示前n行
-c num # 显示前n个byte
```

##### tail(display the last part of a file) 展示文件后面部分内容

```shell
tail [params] file # 默认显示文件倒数十行内容
-n num	# 显示后n行
-c num	# 显示后n个byte
-f		# 动态监听文件内容变化并将内容输出到控制台
-r		# 文件内容倒序输出内容
```

##### more|less 以翻页的方式展示内容

```shell
more [params] file
-n num # 每页显示n行
+num   # 从第n行展示

# 在此模式下的命令
# Enter	向下翻页
# 空格键	向下翻页
# F		向下翻页
# B		向上翻页
# =		显示当前行号信息
# q		退出
```

