---
title: "Linux 进阶命令"
date: 2019-09-26T17:51:19+08:00
lastmod: 2020-04-20T22:28:23+08:00
draft: true
categories:
    - linux
tags:
    - shell

---

除了前面提到的基本的 linux 命令之外，还有一些功能强大的其它命令，学习这些命令，能够有效提升我们的开发效率。

<!--more-->

#### 文件查找命令 find

find 命令用于查找指定的文件，可以按照文件大小、文件名称、文件类型等进行查找，具体用法如下所示：

```shell
find path [params]

-name file_name		# 精确匹配，文件名可以包含通配符 *
-iname file_name 	# 不区分大小写精确匹配 
-type file_type		# 查找指定类型的文件，类型可以是 d 目录、f 文件、s socket 等
-size n 			# 查找指定大小的文件，+1k 表示超过 1k 的文件，-1k 表示小于 1k 的文件，单位可以是K、M、G
```

#### 内容查找命令 grep

grep 命令用于查找文件中符合指定条件的内容，默认情况下显示指定内容所在行的数据。

```shell
grep [params] patten path
-v	# 显示不匹配的内容行
-An	# 显示匹配行的后 n 行
-Bn	# 显示匹配行的前 n 行
-Cn	# 显示匹配行的前后各 n 行
-c	# 显示匹配次数
-E	# 使用扩展的正则表达式，如 +、?、()、| 等 
-i	# 忽略大小进行匹配
-n	# 显示匹配行的行号
-r	# 递归查询目录中的所有文件内容是否包含匹配内容，等同于 -d recurse
-w	# 只有全字符匹配才算匹配
```

#### 内容修改命令 sed

sed 命令主要用于批量修改文件中的内容。

```shell
sed [params] path
-e script 				# 以脚本方式修改文件内容（ e 可以省略）
-i 						# 在原文件中修改内容
-n 						# 只输出执行的结果
-r						# 使用扩展的正则表达式
sed -i '' patten file	# 按照指定的 patten 修改 file 文件中的内容
```

sed 的脚本和 vim 的修改命令类似，接下来我们看看一些常用的脚本动作有哪些：

**1、增加 a**

```shell
sed '3a\xxxx' file	 	# 在文件的第三行之后增加（也就是第四行） xxxx 内容
sed '3a xxxx' file		# 空格和\等价
```

**2、删除 d**

```shell
sed '3d' file 		# 删除第三行的内容
sed '3,5d' file 	# 删除第 3 到 5 行（闭区间，即 3，4，5 行均会被删除）的内容
sed '3,$d' file		# 删除第 3 行到最后一行的内容
```

**3、插入 i**

```shell
sed '2i 222' file	# 在第二行插如 222 一个新行
```

**4、替换 c**

```shell
sed '2c 2222' file # 替换第二行内容为 222
```

**5、显示指定内容 p**

```shell
sed -n '7p' file # 只显示第七行内容，如果没有 n 参数，会在最后显示文件所有内容
```

**6、搜索并（删除、打印、替换）**

```shell
sed '/a/d' file			# 查找包含 a 的行并将其删除
sed -n '/a/p' file 		# 查找包含字符 a 的内容并显示，等价于 grep 操作
sed 's/old/new/g' file	# 查找全部旧字符 old 并将其替换为 new，g 表示替换所有
```

**7、在原文件上修改**

上面提到的命令都是将修改后的内容输出到标准输出，而接下里的命令是会将修改后的内容写入到文件中，需要特别注意。

```shell
sed -i 's/old/new/g' file	# 查找全部旧字符 old 并将其替换为 new，g 表示替换所有
```

值得注意的一点是，在 macos 系统上，需要多加一个参数`''`，否认会报错 `sed: 1: "a.txt": command a expects \ followed by text`

```shell
sed -i '' 's/old/new/g' file
```

#### 排序命令 sort

sort 将每行作为一个比较的对象，针对每行内容进行排序

```shell
sort [params] file

-c 	# 检查文件是否按照顺序排序
-f 	# 忽略大小写
-u 	# 去除重复值排序
-n 	# 按照数字大小进行排序
-r	# 反向排序
-k	# 按照指定列的指定字符按照某中格式进行排序
-t 	# 按照指定字符进行分割列，常与 -k 命令一起使用
-m 	# 将两个已排好序的文件进行合并（归并排序）
```

此处重点讲解一下 `k `参数

```shell
-k field.character type,field.character type

sort -t " " -k 1.2 # 按照第一列第二个字符进行排序
sort -t " " -k 1.2,1.3 -k 2,2 # 只针对第一列的第二个和第三个字符进行排序,如果相同则针对第二列排序
```

#### 唯一命令 uniq

uniq 用于去除文件中的重复行

```shell
uniq [params] file
-c	# 在每列旁边显示重复的次数
-d	# 只显示重复的行
-u	# 只显示出现一次的列  c/d/u 三者只能同时出现一个
-f	# 忽略前 n 列
-s	# 忽略前 n 个字符
-i	# 忽略大小写
```

#### 参数转换命令 xargs

xargs 可以将命令的结果通过管道或者标准输入作为后续命令的参数，具体用法如下

```shell
cat a.txt |xargs # 将文件中的每一行内容通过 xargs 转换为一个参数，默认使用 echo 命令，将内容输出
-nx # 多行输出，每行最多x个参数
-d	# 设置分隔符，默认使用空格、换行、tab 作为分隔符
-I {} # 将每一个参数转换为变量{}，可以在后续命令中引用,如 cat a.txt|xargs -I {} echo {}+1
```

#### 内容切割命令 cut

cut命令用来显示行中的指定部分，删除文件中指定字段

```shell
cut [params] file
-c	# 显示指定第 n 个字符
-d	# 指定分割符号，默认 tab
-f 	# 显示第 n 列字段，或者使用 n,m 表示第 n 列到 m 列
--complement # 显示选中列之外的列
```

#### 字符替换命令 tr

```shell
tr [param] s1 s2
echo "HELLO WORLD" | tr 'A-Z' 'a-z'	#字符大写替换为小写

-c	# 将不属于第一字符集的字符替换为第二字符
-d	# 删除属于字符集的参数
-s	# 将连续多个字符看做一个字符
-t	# 删除第一字符集比第二字符集多的字符
```

可以使用的字符类型

```shell
[:alnum:]：字母和数字
[:alpha:]：字母
[:cntrl:]：控制（非打印）字符
[:digit:]：数字
[:graph:]：图形字符
[:lower:]：小写字母
[:print:]：可打印字符
[:punct:]：标点符号
[:space:]：空白字符
[:upper:]：大写字母
[:xdigit:]：十六进制字符
```

#### 资源占用查看命令 top

top 命令能查看当前系统资源占用的情况，包括 CPU、内存等，我们来看下一下具体会统计哪些信息。

前五行是统计信息区：

- 第一行系统信息：显示当前时间，启动时间，当前登录用户数量，cpu 1 分钟、5 分钟、15 分钟的负载情况；

- 第二行任务统计：2 个进程，1 个正在运行，1个正在休眠，0 个停止的 ，0 个僵尸进程；
- 第三行CPU 信息统计：0.7 %的用户空间占用，2.2%的系统占用，0%的改变过优先级的占用，96.5%的空闲 cpu 占比，0.3%的 io 等待占用 cpu，0%的硬中断占比和 0.2 的软中断占比，0%的虚拟 cpu 等待占比
- 第四行内存信息统计：2037620KB的总内存，其中219252KB 空余，904112KB占用，914256KB 的缓存占用
- 第五行swap交换分区信息：1048572KB 的交换区总量，其中1047792KB空闲，780KB 已使用

```shell
top - 13:50:53 up 4 days,  2:18,  0 users,  load average: 0.05, 0.06, 0.08
Tasks:   2 total,   1 running,   1 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.7 us,  2.2 sy,  0.0 ni, 96.5 id,  0.3 wa,  0.0 hi,  0.2 si,  0.0 st
KiB Mem :  2037620 total,   219252 free,   904112 used,   914256 buff/cache
KiB Swap:  1048572 total,  1047792 free,      780 used.  1000576 avail Mem
```

后面则是具体的进程相关的信息，主要包含

- PID：进程 ID
- USER：用户名
- PR：进程优先级
- NI：nice值，越小优先级越高，[-20, 19]
- VIRT：进程使用的虚拟内存大小
- RES：进程使用的物理内存大小
- S：进程状态；R 运行，S 休眠，T 追踪，Z 僵尸进程，D 不可中断的睡眠状态
- SHR：共享内存大小
- %CPU：进程 cpu 占比
- %MEM：进程内存占比
- TIME+：进程运行时间
- COMMAND：启动命令

```shell
PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
  1 root      20   0   11832   2996   2612 S   0.0  0.1   0:00.40 bash
 24 root      20   0   56204   3832   3296 R   0.0  0.2   0:00.36 top
```

相关命令如下：

```shell
top [param]
-o  # 按照指定列进行排序
-u 	# 显示指定的用户进程
-n	# linux 是刷新的次数，mac 是显示的行数
-i	# 设置刷新时间间隔（秒）
-p	# 指定进程
```

#### 进程查看命令 ps

```shell
ps [params]
a		# 显示所有进程
A		# 显示所有进程
-e	# 同上
-f	# 显示进程之间的关系，PID 进程ID， PPID 父进程ID
u		# 显示使用者
-u	# 筛选指定用户的进程
aux # 显示所有包含其他使用者的进程 
-ef # 显示所有进程 
```
