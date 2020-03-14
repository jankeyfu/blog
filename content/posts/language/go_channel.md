---
title: "Go Channel"
date: 2020-03-14T15:43:06+08:00
draft: true
categories:
    - 语言
tags:
    - golang
    - channel
---

channel 是Go语言中很重要的一种数据结构，他主要用于多个协程之间进行通信。其设计是同步的，在使用的时候并不需要加锁，由于channel的存在，大大降低了go 并发编写的难度。

<!--more-->

#### channel的类型

##### 方向

从方向上channel可以分为三类，以数据类型为 int 为例，普通双向 channel （chan int），只可接收数据的 channel （`<- chan int`）和只可发送数据的 channel （`chan <- int`）。

**1. 双向channel** ：`chan int` 即可发送数据，又可接收数据

**2. receive-only channel** ：`<- chan int` 只允许从 channel 中接收数据，如果发送数据给此 channel，会编译报错：**invalid operation: ch <- 10 (send to receive-only type <-chan int)**

**3. send-only channel** ： `chan <- int` 只允许向 channel 中发送数据，如果从此 channel 中接收数据，也会编译报错：**invalid operation: <-ch (receive from send-only type chan<- int)**

##### 容量

从容量上 channel 可以而分为无缓冲的 channel 和有缓存的 channel，所谓有缓冲是指可以不断地向 channel 中塞入数据而不协程不会阻塞。

```go
make(chan int,cap) // 创建一个容量为cap的chan int
make(chan int) // 创建一个无缓存的chan int
```

有缓冲的容量为1的 channel 和无缓冲的channel 有什么区别呢？

- 缓冲为1的channel可以在同一个协程下有一个数在channel中，可以在同一个协程下从channel中取数
- 无缓冲的channel可以理解为缓存为0的channel，在一个协程中接收数据之后，只能从两个协程发送数据，无法同时在一个协程中接收和发送数据，否则会造成协程死锁

```go
func bufferedChan() {
	ch1 := make(chan int, 3)
	ch2 := make(chan int, 1)
	ch3 := make(chan int)
	ch1 <- 1
	ch1 <- 2
	ch1 <- 3
	fmt.Println(<-ch1, <-ch1, <-ch1)

	ch2 <- 1
	fmt.Println(<-ch2) // 同一协程可接收可发送

	ch3 <- 1
  // fatal error: all goroutines are asleep - deadlock!
  // 一个协程只能发送数据，必须由另一个协程接收数据才行
	fmt.Println(<-ch3) 
}
```

#### Range

go 的 `for range` 支持遍历 channel，for range 会读取 channel 中的数据直到 channel 被 close 掉，遍历过程中当 channel 中无数据的时候会阻塞；如果最终 channel 没有close，引起 panic `fatal error: all goroutines are asleep - deadlock!`

```go
func rangeChan() {
	ch := make(chan int, 3)
	go func() {
		ch <- 1
		time.Sleep(time.Second * 5)
		//如果未close channel，main 协程执行完毕后会panic: fatal error: all goroutines are asleep - deadlock!
		close(ch)
	}()
	for v := range ch {
		fmt.Println(v)
	}
}
```

#### Select ... Case

select语句会选择一组可能的 接收channel 或者发送channel执行，类似于 switch 操作，但是 switch 操作是串行的，而这里是通过通信的方式选择其中之一的 case 进行执行。如果没有满足条件的case，则执行 default。

```go
func selectChan() {
	ch := make(chan int, 3)
	go func() {
		ch <- 1
	}()
	// 如果没有下列的休眠，则由于另一个goroutine 还没来得及向ch中塞入数据，则会执行default语句。
	// 有了休眠语句，则ch中已有数据，<-ch操作未被阻塞，则执行输出ch中的数据
	time.Sleep(time.Second)
	select {
	case v := <-ch:
		fmt.Println(v)
	default:
		fmt.Println("default...")
	}
}
```

#### 闹钟+定时器

##### Timer

time.Timer 可以理解为我们的闹钟，你可以告诉它你需要等待多久，它会在指定时间之后向通过 channel 通知你，当然我们也可以提前终止，通过调用 `stop` 方法，它会告诉我们是否提前终止成功。如下所示，timer1将会在2秒钟之后通过 timer1.C告知时间已到，而timer2 则由于提前终止了，无法从 timer2.C 中读取数据。

```go
func timer() {
	timer1 := time.NewTimer(2 * time.Second)

	<-timer1.C
	fmt.Println("Timer 1 fired")

	timer2 := time.NewTimer(time.Second)
	go func() {
		<-timer2.C
		fmt.Println("Timer 2 fired")
	}()
	stop2 := timer2.Stop()
	if stop2 {
		fmt.Println("Timer 2 stopped")
	}

	time.Sleep(2 * time.Second)
}
```

当然我们也可以通过 `time.After`实现 time.Timer 的延时功能，它会返回一个 receive-only channel，在指定时延之后channel中将会有数据输出。但是其无法提前终止，因此如果有提前终止的需求的话，使用`time.Timer`

```go
func timeAfter() {
	select {
	case <-time.After(time.Second):
		fmt.Println("a second later")
	}
}
```

##### Ticker

time.Ticker 是一个定时器，每隔指定时间间隔向 channel 中塞入一个数，通过 select 语句可以实现定时器操作。

```go
func ticker() {
	ticker := time.NewTicker(500 * time.Millisecond)
	done := make(chan bool)

	go func() {
		for {
			select {
			case <-done:
				return
			case t := <-ticker.C:
				fmt.Println("Tick at", t)
			}
		}
	}()

	time.Sleep(1600 * time.Millisecond)
	ticker.Stop()
	done <- true
	fmt.Println("Ticker stopped")
}
```

#### 参考

- https://gobyexample.com/tickers
- https://gobyexample.com/timers
- https://colobu.com/2016/04/14/Golang-Channels/