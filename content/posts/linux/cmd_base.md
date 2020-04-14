---
title: "Linux 基础命令"
date: 2019-09-26T17:30:41+08:00
lastmod: 2020-04-14T22:49:05+08:00
draft: true
categories:
    - linux
tags:
    - shell
---

对于刚学习开发的同学，了解一些基本的Linux命令还是很有必要的，下面都是都是日常开发过程中使用的基本命令。

<!--more-->

#### 文件目录命令

**ls (list directory content) 列出当前目录下的文件和文件夹**

```shell
ls		#只展示文件名
ls -l	#展示文件名即其他文件信息，包括权限，日期等
ls -a	#展示隐藏文件
```

**cd (change directory) 跳转到指定目录路径**

```shell
cd dir_name # 跳转到指定的目录路径下
~ 			# 跳转到用户目录下
.. 			# 跳转到上一级目录
. 			# 当前目录
```

**pwd 显示当前目录路径**

```shell
pwd

/Users/xxx
```

**cp(copy files)复制文件**

```shell
cp [params] src_file desc_file
-r # 递归复制文件夹中的文件
-i # 如果目标文件存在会提示是否覆盖
cp file1 file2 dir # 将多个文件复制到一个文件夹中
```

**mv(move files) 移动文件**

```shell
mv [params] src_file desc_file
-f # 强制移动文件，不提示是否会覆盖目标文件
-i # 如果目标文件存在会提示是否覆盖
mv file1 file2 dir # 将多个文件移动到一个文件夹中
```

**rm(remove directory entries) 删除文件**

```shell
rm [params] file
-r # 递归移除目录中的文件
-f # 强制移除文件，不提示
-i # 提示是否移除目标文件
```



#### 内容查看命令

**cat(concatenate and print files) 查看文件内容**

```shell
cat [params] file
-n # 输出行号信息
-e # 展示不可打印字符，并将换行符替换为$输出
```

**head(display first lines of a file) 展示文件前面内容**

```shell
head [params] file # 默认显示文件前十行内容
-n num # 显示前n行
-c num # 显示前n个byte
```

**tail(display the last part of a file) 展示文件后面部分内容**

```shell
tail [params] file # 默认显示文件倒数十行内容
-n num	# 显示后n行
-c num	# 显示后n个byte
-f		# 动态监听文件内容变化并将内容输出到控制台
-r		# 文件内容倒序输出内容
```

**more|less 以翻页的方式展示内容**

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



#### 查找命令

**find 文件查找命令**

```shell
find path -name file_name # 查找path路径下名为file_name的文件，文件名称支持*通配符
```

**grep 文件内容查找命令**

```shell
grep [params] patten file_name # 查找文件中指定的内容所在的那一行
-n 		# 显示查找内容的行号,如果后面加了数字则表示将匹配行上下各n行的内容展示
-i 		# 忽略大小写
-r dir	# 递归查找dir目录下所有文件中与所需查找的内容匹配的行
```



#### 文件权限命令

**chmod 修改文件用户权限**

```shell
chmod 777 file # 修改文件的权限值，777为最低权限，所有人均可使用，可以改为你想设定的权限值
chmod -R 777 dir # 修改文件夹及其内部所有文件权限
```

**chown 修改文件所有者**

```shell
chown user_name file 	# 修改文件或者目录下所有文件的所有者
chown -R user_name dir	# 修改文件夹下所有文件的所有者
chown group_name:user_name file # 同时修改文件的所属用户组和用户
```

**chgrp 修改文件所属用户组**

```shell
chgrp group_name file	# 修改文件所属用户组
chgrp -R group_name dir	# 修改文件夹下所有文件的所属用户组
```



#### 用户相关命令

**useradd 新增用户**

```shell
useradd [params] user_name	# 创建一个名为user_name的用户
-u uid			# 设定用户ID
-g group_name	# 在某个用户组下创建一个用户
-c comment		# 用户的描述信息
-e YYYY-MM-DD	# 设置用户失效日期，
```

**userdel 删除用户**

```shell
userdel [-r] user_name # 删除用户，如果使用-r参数，则表示删除用户主文件夹
```

**passwd 用户密码修改**

```shell
passwd [param] user_name # 修改某个用户的密码,如果不接任何参数则是修改当前账号的密码
```

**su 用户身份切换**

```shell
su [param] user_name # 切换当前用户
su - 	# 切换当前用户为登录用户
-c cmd	# 以用户的身份执行某个命令
```
