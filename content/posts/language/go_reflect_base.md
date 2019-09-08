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
- **NumMethod() int** : 返回struct的方法数量
- **Method(int) Method** : 通过索引获取反射Method类型对象
- **MethodByName(string) (Method, bool)** : 通过方法名称获取反射Method类型对象

```go
func TpDemo3() {
	ft := reflect.TypeOf(Add)
	fmt.Printf("func_param_num:%d 1st_param:%s 2nd_param:%s\n", ft.NumIn(), ft.In(0), ft.In(1))
	fmt.Printf("func_return_num:%d 1st_return:%s\n", ft.NumOut(), ft.Out(0))
	mt := reflect.TypeOf(&D{I: 10})
	m, _ := mt.MethodByName("Print")
	fmt.Printf("struct method_num:%d method_name_by_id:%s method_name_by_name:%s", mt.NumMethod(), mt.Method(0).Name, m.Name)
}
// output
// func_param_num:2 1st_param:int 2nd_param:int
// func_return_num:1 1st_return:int
// struct method_num:1 method_name_by_id:Print method_name_by_name:Print
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

Go语言中的 Type 的反射主要用来判断变量类型，而 Value 反射则可以获取变量值，以及更改变量值。

**1. 值反射类型**：值的反射类型通过`reflect.ValueOf()`来获取。具体使用方式见后续介绍

**2. 变量类型转换** ：主要是获取反射对象的实际变量值并进行类型转换

- **Int() int64** : 将 Value 对象中存储的值转换为 int64类型的，只有在底层数据类型为 ` Int, Int8, Int16, Int32, or Int64` 才可以调用，否则会 panic。
- **String() string** : 获取 Value 对象中存储的值转换为 string类型，当底层数据类型不是String 时，不会报错，但是会返回一个类似的字符串`<int Value>`，其中`int`以底层数据类型是`int`为例，如果是其他类型的则显示为其他类型字符串。
- **Float() float64** : 转换为 float64 类型的数据，只支持底层数据类型是 float32 和 float64。
- **Slice(i, j int) Value** : 如果底层数据是 slice 或者 array，可以通过此方法获取数据内容，类似于 `slice[i:j]`。
- **Slice3(i, j, k int) Value** : 类似于 `slice[i : j : k]` , i 起始下标，j 终止下标，k 表示slice的容量大小。
- **Bytes() []byte** : 返回 byte 切片，只支持底层数据类型为 `[]byte`
- **Len() int** : 返回slice 的长度
- **Cap() int** : 返回 slice 的容量

```go
func VDemo() {
	i := 10
	s := "s"
	f := 10.2
	slice := []int{1, 2, 3, 4, 5}
	iv := reflect.ValueOf(i)
	sv := reflect.ValueOf(s)
	fv := reflect.ValueOf(f)
	slicev := reflect.ValueOf(slice)
	bv := reflect.ValueOf(true)
	fmt.Printf("i:%d s:%s f:%.2f slice:%v bool:%v\n", iv.Int(), sv.String(), fv.Float(), slicev.Slice(0, slicev.Len()), bv.Bool())
}
// output 
// i:10 s:s f:10.20 slice:[1 2 3 4 5] bool:true 
```

**3. 变量类型map**：由于map的比较复杂，就单独提出来讲解了。

- **MapKeys() []Value** : 返回 map 的键列表
- **MapIndex(key Value) Value** : 根据 map 的键获取值
- **MapRange() *MapIter** : 获取 map 的迭代器，通过 `Next()` 方法遍历获取 map 的 k_v entry

```go
func VDemo2() {
	mp := map[string]string{"A": "a", "B": "b", "C": "c"}
	mpv := reflect.ValueOf(mp)
	fmt.Println(mpv.MapKeys())
	for iter := mpv.MapRange(); iter.Next(); {
		fmt.Printf("%s:%s ", iter.Key(), iter.Value())
	}
	fmt.Println()
	for _, key := range mpv.MapKeys() {
		fmt.Printf("%s:%s ", key, mpv.MapIndex(key))
	}
}
// output
// [A B C]
// A:a B:b C:c 
// A:a B:b C:c 
```

**4. 地址相关**：

- **CanAddr() bool** : 通过`reflect.ValueOf` 获取到的 `Value` 对象都是不可取地址的，只有指针或者 interface 调用 `Elem() `方法后才可取地址。
- **Elem() Value** : 获取原始变量指针所指向的位置，只有底层数据是指针和interface才能调用此方法。

- **Addr() Value** : 只有 CanAddr 才能获取到 Value对象的地址
- **CanInterface() bool** : 是否可以调用 `Interface()` 方法，只有不可导出的字段变量返回false
- **Interface() (i interface{})** : 将底层数据转换为 `interface{}` 类型的变量，结构体中的不可导出变量会panic

```go
func VDemo3() {
	i := 10
	iv := reflect.ValueOf(i)
	slicev := reflect.ValueOf([]int{1, 2, 3})
	dv := reflect.ValueOf(D{I: 10, u: "u"})
	pv := reflect.ValueOf(&i)
	fv := reflect.ValueOf(Add)
	fmt.Printf("addr slice:%t int:%t struct:%t ptr:%t  func:%t\n", slicev.CanAddr(), iv.CanAddr(), dv.CanAddr(), pv.CanAddr(), fv.CanAddr())
	fmt.Printf("addr ptr_elem:%t addr:%v\n", pv.Elem().CanAddr(), pv.Elem().Addr())
	fmt.Printf("unexpored_field:%t other:%t", dv.FieldByName("u").CanInterface(), iv.CanInterface())
}
// output
// addr slice:false int:false struct:false ptr:false  func:false
// addr ptr_elem:true addr:0xc000016098
// unexpored_field:false other:true
```

**变量赋值**：主要用来设置哪些可以取地址的变量的内容

- **CanSet() bool** : 是否可以修改底层数据内容，只有可去地址的变量才可修改值
- **SetInt(x int64)** : 设置 CanSet 变量的值为int64，下列其他方法都死设置为不同类型的数据，不再赘述，一般用来修改struct 中的字段和map中的字段值。
- **SetUint(x uint64)**
- **SetBool(x bool)**
- **SetBytes(x []byte)**
- **SetFloat(x float64)**
- **SetLen(n int)**
- **SetCap(n int)**
- **SetString(x string)**
- **SetMapIndex(key, val Value)**

```go
func VDemo4() {
	dv := reflect.ValueOf(&D{I: 10})
	dv.Elem().FieldByName("I").SetInt(11)
	fmt.Printf("%+v\n", dv)
}
// output
&{I:11 S: u:}
```

**方法调用**：

- **Call(in []Value) []Value** : 反射方法的调用，方法的参数分别是 in[0], in[1] ...
- **CallSlice(in []Value) []Value** : 首先原方法必须是可变参数方法，可变参数对应 in数组中的最后一个元素，最后一个元素必须是与原方法定义参数类型相同的slice 。

```go
func VDemo5() {
	fv := reflect.ValueOf(Add)
	fvs := reflect.ValueOf(Print)
	// Add(10, 11) = 21
	ret := fv.Call([]reflect.Value{reflect.ValueOf(10), reflect.ValueOf(11)})
	fmt.Println(ret[0])

	fvs.CallSlice([]reflect.Value{reflect.ValueOf([]int{1, 2, 3})})

	dv := reflect.ValueOf(&D{I: 10, S: "s", u: "u"})
	dv.Method(0).Call([]reflect.Value{})
}

// Print ...
func Print(v ...int) {
	fmt.Println(v)
}
// output
// 21
// [1 2 3]
// i:10 s:s u:u
```

**Type Value通用API** : 这些API在Type 和 Value 中的用法一致，唯一的不同是返回值的类型一个是 Type 一个 Value

- **NumMethod() int**
- **Method(i int) Value**
- **MethodByName(name string) Value**
- **NumField() int**
- **Field(i int) Value**
- **FieldByName(name string) Value**
- **FieldByNameFunc(match func(string) bool) Value**
- **Kind() Kind**
- **Type() Type**