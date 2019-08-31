---
title: "Golang Reflect基础篇"
date: 2019-08-31T14:30:33+08:00
draft: true
categories:
    - 语言
tags:
    - golang
---

套用维基百科的解释来说，反射就是指计算机程序在运行时（Run time）可以访问、检测和修改它本身状态或行为的一种能力。用比喻来说，反射就是程序在运行的时候能够“观察”并且修改自己的行为。Go语言和很多语言一样，支持反射操作，接下来就一起学习下，反射在Go语言中是怎么使用的。

<!--more-->

在学习Go语言中的反射之前，我们应该知道一个变量是由其类型和值决定的。而所谓的类型就是我们在定义变量时如： `var i int` 和`var s string`，其 中的变量 `i` 和变量 `s` 的类型分别是`int`和`string`，此为静态类型（**static type**）；Go 语言还有一种类型就是运行时类型（**concrete type**），运行时类型不是说我们不知道他的类型，而是说可以将一些其他类型的变量转换为当前类型的变量。以下面代码为例：`Reader` 是个 interface，其中定义了 `Read` 方法，然后自定义了一个 `MyReader` 的 struct，并且实现了 `Read` 方法；则在使用过程中，定义了一个`Reader` 类型的变量b（此处我们可以理解为其类型永远都是Reader类型的，因为Go语言是静态类型语言），尽管在使用过程中，其值可以是不同类型的值，但是它也是适应了`Reader`类型的数据，因为实现了 `Reader` interface 定义的方法。对于预定义的类型 `int`，`string` 等来说，他们的静态类型就是运行时类型，而反射主要研究的是运行时类型。

```go
type Reader interface {
	Read(p []byte) (n int, err error)
}

type MyReader struct{}

func (rw *MyReader) Read(p []byte) (n int, err error) {
	return 0, nil
}

func Demo() {
  var b Reader
	mr := &MyReader{}
	b = mr
	b.Read([]byte{})
}
```

#### 反射中的两大结构体：Type 和 Value

Go语言中的反射主要是围绕变量的类型和值来处理的，所以最重要的API设计也是以此而设计的。

- func TypeOf(i interface{}) Type：次方法主要是将变量转换为reflect.Type类型的变量，以便对其类型进行其他操作。
- func ValueOf(i interface{}) Value：此方法主要是将变量的值转换为reflect.Value类型的变量，以便对变量的值进行其他操作。

接下来就围绕类型和值的API进行简单的介绍。

##### Type

**1. 变量类型**：获取变量的预定义类型，可以通过 `reflect.TypeOf` 方法获取，得到的是一个`reflect.Type` 类型的变量，可以通过 `String()` 方法获取变量的类型，如下代码所示，定义的变量 i 和 s ，通过反射获取到的变量类型分别是 int 和 string，当然也可以获取到方法的定义和结构变量的类型。

```go
func TpDemo() {
	var i int
	var s string
	it := reflect.TypeOf(i)
	st := reflect.TypeOf(s)
	ft := reflect.TypeOf(Add)
	tt := reflect.TypeOf(D{I: 10})
	fmt.Printf("i:%s s:%s f:%s t:%s", it.String(), st.String(), ft.String(), tt.String())
}

func Add(i, j int) int {
	return i + j
}

type D struct {
	I int
}
// output
// i:int s:string f:func(int, int) int t:main.D
```

**2. 结构体字段**：通过对结构体变量转换为获取到的reflect.Type类型的变量，可以获取到结构体的字段结构。

- **NumField() int** : 获取结构变量字段数量，如结构体 D 有两个字段 I 和 S
- **Field(i int) StructField** : 通过索引获取结构体变量的字段，其返回值是`reflect.StructField`类型的变量。
- **FieldByName(name string) (StructField, bool)**: 通过名称获取结构体变量，如果对应名称的字段变量不存在，则返回false。

- **FieldByNameFunc(match func(string) bool) (StructField, bool)**：通过一个匹配方法来获取匹配的结构体字段变量，需要自定义 `match` 方法

```go
type D struct {
	I int
	S string
}

func TpDemo2() {
	d := D{I: 1, S: "s"}
	dt := reflect.TypeOf(d)
	fmt.Printf("field_number:%d 1st_field:%v 2nd_field:%v\n", dt.NumField(), dt.Field(0).Name, dt.Field(1).Name)
	if iFiled, ok := dt.FieldByName("I"); ok {
		fmt.Printf("field_i:%v\n", iFiled.Name)
	}
	if sField, ok := dt.FieldByNameFunc(func(s string) bool { return s == "S" }); ok {
		fmt.Printf("field_s:%v\n", sField.Name)
	}
}
// output
// field_number:2 1st_field:I 2nd_field:S
// field_i:I
// field_s:S
```

- 对于上述提到的`StructField`结构体定义如下，有字段名`Name` 结构体所属的 package路径，以及字段的具体类型Type（reflect.Type)，Tag 结构体tag标记 

``` go
type StructField struct {
	Name      string
	PkgPath   string
	Type      Type      // field type
	Tag       StructTag // field tag string
	Offset    uintptr   // offset within struct, in bytes
	Index     []int     // index sequence for Type.FieldByIndex
	Anonymous bool      // is an embedded field
}
```

**3. 方法反射**：通过类型反射，获取方法参数的类型和方法返回值的类型

- **NumIn() int** : 返回方法参数个数
- **In(i int) Type** : 返回第i个参数的反射类型
- **NumOut() int** : 返回方法返回值个数
- **Out(i int) Type** :返回第i个返回值的反射类型

```go
func TpDemo3() {
	ft := reflect.TypeOf(Add)
	fmt.Printf("func_param_num:%d 1st_param:%s 2nd_param:%s\n", ft.NumIn(), ft.In(0), ft.In(1))
	fmt.Printf("func_return_num:%d 1st_return:%s", ft.NumOut(), ft.Out(0))
}
// output
// func_param_num:2 1st_param:int 2nd_param:int
// func_return_num:1 1st_return:int
```

**4. 其他类型**：其他数据类型如slice，array，map，ptr 的类型反射

- **Elem()** : 复合类型Array, Chan, Map, Ptr, or Slice 的类型反射，其余类型会 panic，当是指针的反射类型对象是，其返回的是指针所指向的对象类型，当反射类型是上述类型是非指针类型时，返回的是其中元素的类型。如slice 结果是 int， 因为 slice 元素的数据类型是 int 类型的，而 &slice 的结果是 []int ，因为其实指针指向的是 []int 类型的的变量。
- **Key()** : 返回map类型的反射类型的key对应的类型，其余数据类型类型panic
- **Len()** : 返回数组的长度，其余数据类型painc
- **Kint()** : 返回反射的具体类型，主要是基础数据类型int, uint8, int32 int64, float32, float64 等及复合类型 slice,   array, map, chan, struct, func

```go
func TpDemo4() {
	slice := []int{1, 2, 3, 4, 5}
	arr := [3]string{"A", "B", "C"}
	mp := map[string]string{"A": "1", "B": "2"}
	ch := make(chan float64, 1)
	ptr := &slice
	st := reflect.TypeOf(slice)
	mt := reflect.TypeOf(mp)
	pt := reflect.TypeOf(ptr)
	ct := reflect.TypeOf(ch)
	art := reflect.TypeOf(arr)
	dt := reflect.TypeOf(D{I: 10})
	it := reflect.TypeOf(10)
	ft := reflect.TypeOf(Add)
	fmt.Printf("slice:%v map:%v chan:%v ptr:%v arr:%v\n", st.Elem(), mt.Elem(), ct.Elem(), pt.Elem(), art.Elem())
	fmt.Println("map_key:", mt.Key())
	fmt.Println("arr_len:", art.Len())
	fmt.Printf("slice:%v map:%v chan:%v ptr:%v arr:%v struct:%v func:%v int:%v\n", st.Kind(), mt.Kind(), ct.Kind(), pt.Kind(), art.Kind(), dt.Kind(), ft.Kind(), it.Kind())
}
// output
// slice:int map:string chan:float64 ptr:[]int arr:string
// map_key: string
// arr_len: 3
// slice:slice map:map chan:chan ptr:ptr arr:array struct:struct func:func int:int
```

##### Value