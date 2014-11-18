---
layout: post
title: "Java 7的6个新特性"
date: 2014-11-18 22:20:52 +0800
comments: true
categories: 
- java
---
Java 8早都出来了，现在来了解一下Java 7语言上的几个新特性。 :) switch语句支持String、数字常量的新形式、改进的异常处理、TWR语句、钻石语法和变参警告位置的修改。

<!--more-->

## 1. switch语句支持String

```java
public void printDay(String dayOfWeek) {
	switch(dayOfWeek) {
		case "Sunday": System.out.println("周日"); break;
		case "Saturday": System.out.println("周六"); break;
		...
		default: System.out.println("不知道"); break;
	}
}
```

## 2. 更强的数值文本表示法

```java
int x = 0b1100110; //0b表示二进制
int bitPattern = 0b0001_1100_0011; //也可以加下划线
long longValue = 2_111_000_888L; //加下划线便于阅读
```

## 3. 改善的异常处理

```java
try {
	String fileText = getFile(fileName);
	cfg = verifyConfig(parseConfig(fileText));
} catch(FileNotFoundException | ParseException | ConfigurationException e) {
	//可以用或来表示可能的异常
	...
} catch(IOException iox) {
	...
}
```
另一个新语法对需要重新抛出异常时很有用：

```java
try {
	doSomethingWhichMightThrowIOException();
	doSomethingElseWhichMightThrowSQLException();
} catch (final Exception e) {
	...
	//不再是抛出笼统的Exception，而是抛出实际的异常。
	//final不是必须的，但留着提个醒有好处。
	throw e;
}
```

## 4. TWR(try-with-resources)

这个很有用，特别是io操作时，可以抛掉大串丑陋的代码了。

```java
try (
	OutputStream out = new FileOutputStream(file);
	InputStream is = url.openStream()
) {
	byte[] buf = new byte[4096];
	int len;
	while (len = is.read(buf)) > 0)
		out.write(buf, 0, len);
}
```

上面的代码将资源放在try的圆括号内，当处理完后会自动关闭！但一定要注意不要嵌套创建，否则可能无法正确关闭。一定要声明变量。例如下面的代码就应该修改：

```java
try (ObjectInputStream in = 
	new ObjectInputStream(
		new FileInputStream("someFile.bin"))) {
	...
}

//要改为：
try (
	FileInputStream fin = new FileInputStream("someFile.bin");
	ObjectInputStream in = new ObjectInputStream(fin)) {
	...
}

```

TWR特性依赖于try从句中的资源类实现新接口AutoCloseable。Java 7平台的大多数资源都已经修改过了。

## 5. 钻石语法

```java
//不用这么麻烦了：
Map<Integer, Map<String, String>> userList = new HashMap<Integer, Map<String, String>>();

//可以直接写成：
Map<Integer, Map<String, String>> userList = new HashMap<>();
```

## 6. 简化变参方法调用
在Java 7之前，如果泛型和变参结合起来会怎么样？

```java
public static <T> Collection<T> doSomething(T... entries) {
	...
}
```

Java处理变参实际上是把它放到一个编译器自动创建的数组中。但我们知道泛型的实现其实是通过[擦拭法](/blog/2014/07/02/javafan-xing/)实现的。所以Java数组不支持泛型:

```java
HashMap<String, String>[] a = new HashMap<String, String>[3]; //编译错误

HashMap<String, String>[] a = new HashMap[3]; //编译可通过，但会有警告：
//Type safety: The expression of type HashMap[] needs unchecked conversion to conform to HashMap<String,String>[]
```

因此，当泛型遇到变参时，编译器只好给你个警告。但这个问题更应该由API的设计者去关注，而不是API使用者。所以Java 7把警告信息挪到了定义API的地方。