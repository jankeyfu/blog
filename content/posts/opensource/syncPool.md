---
title: "Sync.Pool 对象重用利器"
date: 2019-12-29T16:04:06+08:00
draft: true
categories:
    - 源码
tags:
    - golang
    - src
---

最近在看 zap 相关的源码，里面用到了很多的 sync.Pool 来优化内存使用，于是花了点时间研究了下。

`sync.Pool` 是一组可以单独保存和检索的**临时对象**，之所以称其保存的是临时对象是因为在下一次 GC 的时候，池中对象会被清理，且被清理时不会得到任何通知，因此池中不适合存放数据库连接等持久对象。`sync.Pool `的主要用途是存储已分配内存但却不再使用的对象，以供后续重用此对象，减少内存分配产生的碎片垃圾回收，提升性能。

<!--more-->
#### 用法

首先我们了解下 sync.Pool 的用法，其实 sync.Pool 很简单，只需要三步即可搞定：

1. 创建一个 sync.Pool ，只需要定义其字段 New 即可，这是一个方法，主要作用是当池中无可用对象的时候，可以创建一个对象以供使用

   ```go
   var pool = &sync.Pool{
   	New: func() interface{} {
   		return &S{}
   	},
   }
   ```

2. 当需要获取对象的时候使用 `Get` 方法即可，然后再将其转换为所需要的类型

   ```go
   obj := pool.Get().(*S)
   ```

3. 回收获取的对象，使用 `Put` 方法，可以将对象放回池中，以供后续使用。

   ```go
   pool.Put(obj)
   ```

接下来看一个例子，看看 sync.Pool 在性能提升上有多大的用途。

```go
func BenchmarkNoPool(b *testing.B) {
	b.ResetTimer()
	var tmp *S
	for i := 0; i < b.N; i++ {
		tmp = &S{}
	}
	_ = tmp
}
func BenchmarkWithPool(b *testing.B) {
	var pool = &sync.Pool{
		New: func() interface{} {
			return &S{}
		},
	}
	b.ResetTimer()
	var tmp *S
	for i := 0; i < b.N; i++ {
		tmp = pool.Get().(*S)
		pool.Put(tmp)
	}
	_ = tmp
}

type S struct {
	s string
}
```

通过对上述代码进行 `Benchmark` 得到下列结果：

```shell
BenchmarkNoPool-4     	39317407	        27.8 ns/op	      16 B/op	       1 allocs/op
BenchmarkWithPool-4   	69199653	        16.2 ns/op	       0 B/op	       0 allocs/op
```

由此看出，sync.Pool 在能够减少内存分配，而且，数据结构体越大，性能提升效果越明显，感兴趣的同学可以将结构体 `S` 进行扩展，增加新的字段，会得到更加明显的提升效果。

**sync.Pool 是如何实现的呢？每个 P 都有独享的的缓存池，当 g 进行 sync.Pool 操作的时候，会先找到对应 P 的缓存池的 private 对象；如果没有对象可用，则加锁从 shared 切片中取一个可用对象；如果仍然没有可用对象，则会从别的 P 对应的池中偷取；如果还是没有，则使用 New 方法创建一个新对象。**

#### 结构体分析

```go
type Pool struct {
	noCopy     noCopy
	local      unsafe.Pointer // local fixed-size per-P pool, actual type is [P]poolLocal
	localSize  uintptr        // size of the local array
	victim     unsafe.Pointer // local from previous cycle
	victimSize uintptr        // size of victims array
	New        func() interface{}
}

type poolLocalInternal struct {
	private interface{} // Can be used only by the respective P.
	shared  poolChain   // Local P can pushHead/popHead; any P can popTail.
}

type poolLocal struct {
	poolLocalInternal

	// Prevents false sharing on widespread platforms with
	// 128 mod (cache line size) = 0 .
	pad [128 - unsafe.Sizeof(poolLocalInternal{})%128]byte
}
```

- Pool 结构体对外只暴露了 `New` 这个字段，是池中无可用对象时申请内存创建新对象的方法；

- local 其实是每个 P 对应的缓冲池 (poolLocal) 切片，可用通过每个 P 的序号索引获取；
- poolLocalInternal.private 就是每个缓冲池中的私有对象，只允许被当前 P 所获取
- poolLocalInternal.shared 这个是当前 P 所持有的公共对象列表，可用被当前 P 所获取，也能被其他的 P 获取。

#### 获取对象

```go
func (p *Pool) Get() interface{} {
	l, pid := p.pin()
	x := l.private
	l.private = nil
	if x == nil {
		x, _ = l.shared.popHead()
		if x == nil {
			x = p.getSlow(pid)
		}
	}
	runtime_procUnpin()
	if x == nil && p.New != nil {
		x = p.New()
	}
	return x
}
```

为了让代码看起来更加简单明了，此处只保留了部分核心代码。获取对象的操作如下：

- 首先通过 p.pin() 方法获取当前 goroutine 对应的 P 所对应的 poolLocal 对象以及 P 的id
- 然后从当前 P 的poolLocal 对象中获取 private 对象，由于同一时刻一个 P 只会有一个 groutine 执行，所以此处不需要加锁。
- 如果 private 为 nil ，则从取出 shared 切片头部一个对象，如果仍然为空，则通过 getSlow 方法从别的 P 的缓存池中偷取一个对象。
- 如果仍未获取到可用对象，则通过 New 方法创建一个新对象。

#### 缓存对象

```go
func (p *Pool) Put(x interface{}) {
	if x == nil {
		return
	}
	l, _ := p.pin()
	if l.private == nil {
		l.private = x
		x = nil
	}
	if x != nil {
		l.shared.pushHead(x)
	}
	runtime_procUnpin()
}
```

缓存对象则和获取对象的流程相反，流程如下

- 如果存入对象为 nil ，则直接返回
- 获取当前 goroutine 所属的 P 的 LocalPool 对象，如果其 private 对象为 nil ，则将此赋值给 private
- 如果 private 对象非空，则将此对象存入 shared 切片的头部

#### 引用

- [golang新版如何优化sync.pool锁竞争消耗？](http://xiaorui.cc/2019/06/12/golang新版如何优化sync-pool锁竞争消耗？/)