---
title: "Go"
date: 2019-08-18T22:17:58+08:00
draft: true
categories:
    - 面试
tags:
    - go
---

> 本文是长期维护的Go相关的笔试面试题合集

<!--more-->

1. `defer`  请说出下列代码的输出结果

```go
func main() {
	fmt.Printf("main:%d\n", deferFunc())
}

func deferFunc() int {
	var i int
	defer func() {
		i++
		fmt.Printf("first defer:%d\n", i)
	}()
	defer func() {
		i++
		fmt.Printf("second defer:%d\n", i)
	}()
	return i
}
// second defer:1
// first defer:2
// main:2
```
- defer的执行顺序是栈调用，**后进先出**，所以最后定义的defer函数最先执行。
- 在函数体中有panic的时候，会层层调用defer函数，直到有某个defer函数处理panic为止，如果没有，则程序抛出panic
- 如果函数中有`os.Exit()`函数调用，则defer函数不会执行
- return语句的赋值操作 **先于** defer函数执行 **先于** 函数返回

