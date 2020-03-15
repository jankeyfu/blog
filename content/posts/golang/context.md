---
title: "Go Context"
date: 2020-03-15T12:00:05+08:00
draft: true
categories:
    - golang
tags:
    - context
---

Context 也称为上下文，主要用于并发中对多个 goroutine 的控制，也可作为全局数据进行传递的载体，按照golang 的编程实践，一般用作函数的第一个参数。

<!--more-->

#### context 定义

context 主要用于多groutine中的控制，如 Deadline 方法和 Done 方法都是为此设计的，目的是为了通知其余相关goroutine流程是否结束。

- **Deadline** 返回设置的到期时间，以及一个标识判断是否设置了到期时间
- **Done** 返回一个只读 channel，用于其余 goroutine 监听流程是否结束，以便及时结束逻辑，避免不必要的计算开销
- **Err** 返回的是Context 终止的原因，一种是手动取消`Canceled`，一种是超时取消`DeadlineExceeded`
- **Value** 则是使用Context全局传递数据时使用的，类似于map，通过制定的key获取对应的值

```go
type Context interface {
	Deadline() (deadline time.Time, ok bool)
	Done() <-chan struct{}
	Err() error
	Value(key interface{}) interface{}
}
```

#### Context 应用

##### 基础 Context 

context有两个基础实现，一个是 `context.Background() `一个` context.TODO()`，他们都会返回一个 `context.emptyCtx` 指针；这两个基础的 Context 都不具备监听 Done 方法返回的 channel 数据的功能。

- `context.Background()` : context 树的根节点，是创建其余context 节点是根基。
- `context.TODO()` : 当不知道使用何种 Context 的时候，就创建一个 TODO context。 

##### 可取消 Context 

context的一个核心功能就是通知相关联的 goroutine 流程已结束，可以释放资源了，可以通过下列三种方式进行创建。

`WithCancel(parent Context) (ctx Context, cancel CancelFunc)` ：基于父 Context 创建一个带有取消功能的 Context，可以显示的调用 cancel 方法进行取消，相关的 goroutine 对此 Context 及其子 Context 均可监听 Done 方法，以便在合适的时机释放资源。 

```go
func CancelCtx() {
	ctx, cancel := context.WithCancel(context.Background())
	vctx := context.WithValue(ctx, "key", "value")
	go func() {
		select {
		case <-ctx.Done():
			fmt.Println("g1 root context done")
		}
	}()
	go func() {
		select {
		case <-vctx.Done():
			fmt.Println("g2 value context done")
		}
	}()
	cancel()
	fmt.Println("main cancel")
	time.Sleep(time.Second)
}
```

` WithDeadline(parent Context, d time.Time) (Context, CancelFunc)` ：基于父 Context 创建一个带有截至时间的 可取消 Context，当到达截至时间，向 `ctx.Done()` 返回的channel 中塞入数据，其余goroutine 即可监听到 上下文取消的信息。除此之外，还可以显示地调用 函数返回的 cancel 方法，提前取消。

 ```go
  func DeadLineCtx() {
  	ctx, cancel := context.WithDeadline(context.Background(), time.Now().Add(time.Second))
  	defer cancel()
  	go func() {
  		select {
  		case <-ctx.Done():
  			fmt.Println("g1 ctx done after 1 sec")
  		}
  	}()
  	time.Sleep(2 * time.Second)
  	fmt.Println("main die after 2 sec")
  }
 ```

`WithTimeout(parent Context, timeout time.Duration) (Context, CancelFunc) ` 底层调用的还是 `WithDeadline` 方法，此处设定一个超时时间段，超过多长时间即向 `ctx.Done()` 返回的 channel 中塞入数据，以便其余 goroutine 能够监听。

```go
func TimeoutCtx() {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	go func() {
		select {
		case <-ctx.Done():
			fmt.Println("g1 ctx done after 1 sec")
		}
	}()
	time.Sleep(2 * time.Second)
	fmt.Println("main die after 2 sec")
}
```

##### 值传递 Context

> 值传递最好只用来传递全局变量，如全局链路ID，全局用户ID，全局SSO cookie 等等，其余数据传递最好以函数参数的形式进行传递。

`WithValue(parent Context, key, val interface{}) Context` : 基于父 Context 附加数据得到一个新的Context，数据通过 k-v 的方法进行存储，如果需要取出数据，则可以通过 `Value`方法获取。

```go
func ValueCtx() {
	ctx := context.WithValue(context.Background(), "key", "value")
	fmt.Println(ctx.Value("key"))
}
```

#### 参考

- https://draveness.me/golang/docs/part3-runtime/ch06-concurrency/golang-context/
- https://www.flysnow.org/2017/05/12/go-in-action-go-context.html
- https://juejin.im/post/5a6873fef265da3e317e55b6



