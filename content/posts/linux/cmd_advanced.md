---
title: "Linux 进阶命令"
date: 2019-09-26T17:51:19+08:00
lastmod: 2020-04-07T22:45:29+08:00
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

#### 参数转换命令 xargs

xargs 可以将命令的结果通过管道或者标准输入作为后续命令的参数，具体用法如下

```shell
cat a.txt |xargs # 将文件中的每一行内容通过 xargs 转换为一个参数，默认使用 echo 命令，将内容输出
-nx # 多行输出，每行最多x个参数
-d	# 设置分隔符，默认使用空格、换行、tab 作为分隔符
-I {} # 将每一个参数转换为变量{}，可以在后续命令中引用,如 cat a.txt|xargs -I {} echo {}+1
```

