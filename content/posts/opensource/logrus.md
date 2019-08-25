---
title: "Logrus"
date: 2019-08-23T18:03:32+08:00
draft: true
categories:
    - 源码
tags:
    - log
---

logrus是Go语言编写的结构化日志工具，拥有丰富的日志API，支持自定义格式输出同时也支持hook操作，是目前比较流行的Go语言日志记录工具。

<!--more-->

先来一个官方demo感受一下什么叫做结构化日志工具，所谓结构化就是，日志记录的数据是有结构可以解析的，而不是像`log.Infof("A walrus appears animail %s", "walrus")`，无法解析。接下来我们打开源码来详细看看logrus是怎么实现这些结构化日志的。

```go
package main

import (
  log "github.com/sirupsen/logrus"
)

func main() {
  log.WithFields(log.Fields{
    "animal": "walrus",
  }).Info("A walrus appears")
}
// 输出格式如下
// INFO[0000] A walrus appears                              animal=walrus
```

logrus的文件内容主要集中在`exported.go, logger.go, entry.go, formatter.go, hooks.go `这五个文件中，`logger.go`文件主要定义了logrus的Logger对象的结构，以及此对象实现的方法；而`exported.go`则通过使用一个包装好的`stdLogger`对象对外提供日志记录的方法，最终的日志输出是有Entry对象来实现的，日志的输出格式由`formatter.go`来控制，而日志的hook方法则有`hooks.go`来控制。

##### 结构体

首先来看Logger struct的定义，字段的大体含义可以看代码中的注释。

- **Out**：日志输出的Writer对象，可以是os.Stderr,也可以是文件；
- **Hooks**：用于打印日志时的hooks操作；
- **Formatter**：日志内容格式化对象，用于格式化日志内容；
- **ReportCaller**：是否打印调用日志打印的函数的信息；
- **Level**：日志等级；
- **mu**：并发锁，控制并发日志记录；
- **entryPool**：日志内容对象的sync.Pool；
- **ExitFunc**：打印日志完成后执行的方法。

```go
type Logger struct {
	Out          io.Writer
	Hooks        LevelHooks
	Formatter    Formatter
	ReportCaller bool
	Level        Level
	mu           MutexWrap
	entryPool    sync.Pool
	ExitFunc     exitFunc
}
```

其次是日志内容对象`Entry`,这主要功能是存储日志内容以及进行日志内容写入。

- **Logger**：所属的Logger对象，拥有上述Logger的内容，如io.Writer对象和Formatter对象等；
- **Data**：存储的是日志的结构化数据，其类型是`type Fields map[string]interface{}` 一个map，key是字符串型，value是任意类型，存储的是`log.WithFileds()`中的数据内容；
- **Time**：存储内容创建的时间；
- **Level**：和Logger对象一致，保存日志等级（既然都一样了，为啥还要再定义一个字段存储，不是很清楚）；
- **Caller**：记录调用方的信息；
- **Message**：字符串类型，记录日志内容，通常是`log.Info("msg")`中msg的内容；
- **Buffer**：当formatter调用entry.log()方法的时候设置，具体用途现在还没有弄清楚，后续补充上TODO。
- **Context**：用于记录上下文信息，主要用于hook操作
- **err**：存储错误信息，可能在日志内容格式化的时候出错。

```go
type Entry struct {
	Logger  *Logger
	Data    Fields
	Time    time.Time
	Level   Level
	Caller  *runtime.Frame
	Message string
	Buffer  *bytes.Buffer
	Context context.Context
	err     string
}
```

##### 日志等级

先来看看logrus支持的日志等级，共有七类，分别是`Panic, Fatal, Error, Warn, Info, Debug, Trace`，日志等级有高到低，`Panic`级别的日志是最高等级的日志，当打印日志等级为`Panic`的时候，会显示地调用panic函数，`Fatal`级别的日志会在调用后显示地调用`logger.Exit(1)`函数，然后退出当前程序。`Error`级别的日志一般用来记录程序中的error信息，通常与hooks来对error进行处理，如上报error信息给监控平台等。剩下四类日志级别就比较普通了，大家应该都懂，不再详细介绍。

```go
const (
	// PanicLevel level, highest level of severity. Logs and then calls panic with the
	// message passed to Debug, Info, ...
	PanicLevel Level = iota
	// FatalLevel level. Logs and then calls `logger.Exit(1)`. It will exit even if the
	// logging level is set to Panic.
	FatalLevel
	// ErrorLevel level. Logs. Used for errors that should definitely be noted.
	// Commonly used for hooks to send errors to an error tracking service.
	ErrorLevel
	// WarnLevel level. Non-critical entries that deserve eyes.
	WarnLevel
	// InfoLevel level. General operational entries about what's going on inside the
	// application.
	InfoLevel
	// DebugLevel level. Usually only enabled when debugging. Very verbose logging.
	DebugLevel
	// TraceLevel level. Designates finer-grained informational events than the Debug.
	TraceLevel
)
```

##### 日志对象的创建

对于logrus来说，其记录的是结构化的数据，其中的数据都保存在`Entry`对象中，这块在创建一个新的Entry对象时，使用`sync.Pool`对象 entryPool，主要保存Entry指针空对象，使用完后再放回sync.Pool中，防止在记录日志的时候大量开辟内存空间，触发GC操作，从而提高日志记录的速度。

```go
func (logger *Logger) newEntry() *Entry {
	entry, ok := logger.entryPool.Get().(*Entry)
	if ok {
		return entry
	}
	return NewEntry(logger)
}

func (logger *Logger) releaseEntry(entry *Entry) {
	entry.Data = map[string]interface{}{}
	logger.entryPool.Put(entry)
}

func NewEntry(logger *Logger) *Entry {
	return &Entry{
		Logger: logger,
		// Default is three fields, plus one optional.  Give a little extra room.
		Data: make(Fields, 6),
	}
}
```

##### 日志格式化数据API

格式化数据填充API，主要是几个`With`开头的方法，`WithField`和`WithFields`主要是记录结构化的字段信息，保存在Entry对象的Data字段中；在这块使用到上述提到的`newEntry()`方法，就是每一次使用`log.WithFiled()`都会从entryPool 池子中拿出一个`*Entry`对象出来，然后再执行`entry.WithField`方法生成一个全新的`*Entry`对象，然后回收从池子中拿出来的`*Entry`对象。

- **WithField**：生成一个全新的*Entry，存储单个键值对；
- **WithFields**：生成一个全新的*Entry，存储多个键值对；
- **WithError**：其实内部也是存储在Entry对象的Data字段中，只不过使用内置的`error`作为键值对的key；
- **WithContext**：生成一个全新的*Entry对象，存储ctx在Entry对象的Context字段上；
- **WithTime**：生成一个全新的*Entry对象，存储在Entry对象的Time字段上；

```go
func (logger *Logger) WithField(key string, value interface{}) *Entry {
	entry := logger.newEntry()
	defer logger.releaseEntry(entry)
	return entry.WithField(key, value)
}

// Adds a struct of fields to the log entry. All it does is call `WithField` for
// each `Field`.
func (logger *Logger) WithFields(fields Fields) *Entry {
	entry := logger.newEntry()
	defer logger.releaseEntry(entry)
	return entry.WithFields(fields)
}

// Add an error as single field to the log entry.  All it does is call
// `WithError` for the given `error`.
func (logger *Logger) WithError(err error) *Entry {
	entry := logger.newEntry()
	defer logger.releaseEntry(entry)
	return entry.WithError(err)
}

// Add a context to the log entry.
func (logger *Logger) WithContext(ctx context.Context) *Entry {
	entry := logger.newEntry()
	defer logger.releaseEntry(entry)
	return entry.WithContext(ctx)
}

// Overrides the time of the log entry.
func (logger *Logger) WithTime(t time.Time) *Entry {
	entry := logger.newEntry()
	defer logger.releaseEntry(entry)
	return entry.WithTime(t)
}
```

##### 日志内容API

常见的就是三类：一类是支持日志内容格式化的API，不带格式化的，以及带换行的。

- 格式化日志：如`Logf, Tracef, Debugf, Infof, Warnf, Errorf, Fatalf, Panicf`这类日志记录的方法都是支持格式化的，类似于`fmt.Printf()`其实底层也就是使用了`fmt.Sprintf()`将日志内容格式化为字符串。其中Fatalf函数在执行完日志记录的逻辑后，会执行`logger.Exit(1)`方法，默认是使用`os.Exit(1)`，支持自定义；
- 不带格式化的日志：如`Log, Trace, Debug, Info, Warn, Error, Fatal, Panic `，类似于`fmt.Print()`；
- 带换行的日志：如`Logln, Traceln, Debugln, Infoln, Warnln, Errorln, Fatalln, Panicln`，类似于`fmt.Println()`。

```go
func (logger *Logger) Logf(level Level, format string, args ...interface{}) {
	if logger.IsLevelEnabled(level) {
		entry := logger.newEntry()
		entry.Logf(level, format, args...)
		logger.releaseEntry(entry)
	}
}
func (logger *Logger) Tracef(format string, args ...interface{}) {}
func (logger *Logger) Debugf(format string, args ...interface{}) {}
func (logger *Logger) Infof(format string, args ...interface{}) {}
func (logger *Logger) Warnf(format string, args ...interface{}) {}
func (logger *Logger) Errorf(format string, args ...interface{}) {}
func (logger *Logger) Panicf(format string, args ...interface{}) {}
func (logger *Logger) Fatalf(format string, args ...interface{}) {
	logger.Logf(FatalLevel, format, args...)
	logger.Exit(1)
}
```

##### std Logger API

在`exported.go`文件中，封装了使用stdLogger的对外的API，这个就不多介绍了，主要是生成了一个std logger，使用os.Stderr作为输出，使用TextFormatter进行日志格式化，使用`InfoLevel`作为缺省日志记录等级，使用`os.Exit`作为Fatal日志的后续执行函数，`ReportCaller=false`不进行日志调用方信息的记录。

```go
// std logger
func New() *Logger {
	return &Logger{
		Out:          os.Stderr,
		Formatter:    new(TextFormatter),
		Hooks:        make(LevelHooks),
		Level:        InfoLevel,
		ExitFunc:     os.Exit,
		ReportCaller: false,
	}
}

func WithField(key string, value interface{}) *Entry {
	return std.WithField(key, value)
}
```

##### 日志格式化

既然logrus是结构化的日志记录工具，那么拥有将结构化数据按照执行格式进行输出的功能也就不足为奇了，logrus自带两种格式输出，一种是`TextFormatter`，另外一种是`JsonFormatter`。

先来看看Formatter的interface的定义，就只有一个Format方法，就是将Entry中的数据内容，如Data字段存储的有结构的数据键值对，Message中存储的无结构数据，以及Time存储的日志记录时间等等，格式化成我们容易看的数据格式

```go
type Formatter interface {
	Format(*Entry) ([]byte, error)
}
```

它有一个自定义的字段Key，主要就是上述提到的那些日志中的内容对应的key。

```go
const (
	defaultTimestampFormat = time.RFC3339
	FieldKeyMsg            = "msg"
	FieldKeyLevel          = "level"
	FieldKeyTime           = "time"
	FieldKeyLogrusError    = "logrus_error"
	FieldKeyFunc           = "func"
	FieldKeyFile           = "file"
)
```

以及一个基础的方法`prefixFieldClashes`，这个可以将日志中的一些字段进行进行重写，防止在进行数据格式化的时候覆盖了需要填充的字段内容。

```go
func prefixFieldClashes(data Fields, fieldMap FieldMap, reportCaller bool) {
	timeKey := fieldMap.resolve(FieldKeyTime)
	if t, ok := data[timeKey]; ok {
		data["fields."+timeKey] = t
		delete(data, timeKey)
	}
	...//省略了其他key的复写
}
```

下面是一个demo，日志输出内容中原本Fields中包含有key为`@timestamp`的数据，然后再输出的时候变成了`fields.@timestamp`字段。可以看到在这个例子中，使用了`SetFormatter`方法，这个地方是为日志输出设置格式化方式的，也可以使用`TextFormatter`，其内容如第一个demo中显示的那样：`INFO[0000] A walrus appears                              @timestamp=2019-09-01 animal=walrus`，默认就是这种格式化方式，在终端中执行的时候，还会对键值对的key进行着色处理；当然，也可以使用自定义的Formatter进行格式化，只需要实现`Format`方法即可。

```go
package main

import (
	log "github.com/sirupsen/logrus"
)

func init() {
	// Log as JSON instead of the default ASCII formatter.
	log.SetFormatter(&log.JSONFormatter{FieldMap: log.FieldMap{
		log.FieldKeyTime:  "@timestamp",
		log.FieldKeyLevel: "@level",
		log.FieldKeyMsg:   "@message",
		log.FieldKeyFunc:  "@caller",
	}})
}
func main() {
	log.WithFields(log.Fields{
		"animal": "walrus",
	}).WithField("@timestamp", "2019-09-01").
		Info("A walrus appears")
}
// {"@level":"info","@message":"A walrus appears","@timestamp":"2019-08-25T15:37:24+08:00","animal":"walrus","fields.@timestamp":"2019-09-01"}
```

##### Hook

俗称钩子，就是在执行日志记录之前执行一段逻辑。我们可以先看一下Hook的interface定义，Levels函数主要定义的是那些日志级别需要执行特殊操作，而具体执行的逻辑则由Fire函数进行处理。

```go
type Hook interface {
	Levels() []Level
	Fire(*Entry) error
}
```

可以来看个简单的例子，我自定义了一个HookDemo，然后实现了`Levels`函数和`Fire`函数，可以看到，我在`Levels()`函数只返回了`WarnLevel`和`ErrorLevel`，也就是说，只有这两种级别的日志才会执行`Fire`函数，然后我在`Fire()`函数中输出了Entry对象的Data字段内容。

```go
package main

import (
	"fmt"

	log "github.com/sirupsen/logrus"
)

func init() {
	log.AddHook(HookDemo{})
}
func main() {
	log.WithFields(log.Fields{
		"animal": "walrus",
	}).WithField("@timestamp", "2019-09-01").
		Info("A walrus appears")
	log.Error("this is a error msg")
}

type HookDemo struct {
}

func (h HookDemo) Levels() []log.Level {
	return []log.Level{log.WarnLevel, log.ErrorLevel}
}
func (h HookDemo) Fire(entry *log.Entry) error {
	fmt.Printf("this is a hook func:%v\n", entry.Data)
	return nil
}
//INFO[0000] A walrus appears                              @timestamp=2019-09-01 animal=walrus
//this is a hook func:map[]
//ERRO[0000] this is a error msg          
```

那hook函数一般可以用开干什么呢？可以上报Error错误给我们的监控平台，只需要在`Fire()`函数中将错误内容上报给监控系统即可；还可以进行日志文件分割，按照日志文件大小或者日期进行日志文件切割；将日志发送到其他地方如：elasticsearch等。