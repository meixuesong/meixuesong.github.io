---
layout: post
title: "Java注解"
date: 2014-07-09 22:22:10 +0800
comments: true
categories: 
- Java

---

本文记录Java注解的基本用法。

<!--more-->

注解类型声明与接口声明的唯一区别是，在interface之前增加了一个@符：

```java
public @interface TestMethod {
}
```

判断方法是否有某个注解：

```java
	for(Method method: testClass.getDeclaredMethods())
		if (method.isAnnotationPresent(TestMethod.class)) {
			...
		}			
```

### 保留(Retention)

注解信息的保留策略：

* RetentionPolicy.SOURCE 在编译时丢弃。
* RetentionPolicy.CLASS（缺省） 保存在类文件中，运行时可被VM丢弃。
* RetentionPolicy.RUNTIME 保存在类文件中，运行时由VM保留。

```java
@Retention(RetentionPolicy.RUNTIME)
public @interface TestMethod {
}
```

### 注解的目标（Annotation Target）

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface TestMethod {
}
```

目标的类别包括：TYPE, FIELD, METHOD, PARAMETER, CONSTRUCTOR, LOCAL_VARIABLE, ANNOTATION_TYPET和PACKAGE。如果没有指定目标，则注解可以修饰任何Java元素。

### 单值注解

为了在注解类型中支持单个参数，需要提供一个名为value的方法，返回适当的类型并且没有任何参数。

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Ignore {
	String value();
}

//使用示例
@Ignore("忽略")
public void testC() {}
```

不能将null作为注解的值（value）。

### 数组参数

可指定value方法的返回值为数组：

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Ignore {
	String[] value();
}

//使用示例
@Ignore({"忽略", "房价涨了"})
public void testC() {}

//如果数组只有一个成员，也可以这样写：
@Ignore("房价涨了")
public void testC() {}
```

### 多个参数的注解

注解有多个参数时，注解类型的成员名与注解声明的名称一致，如下例中的reasons和initials：

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Ignore {
	String[] reasons();
	String initials();
}

//使用示例
@Ignore(reasons={"just because", "and why not"}, initials="jjl")
```

### 缺省值

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Ignore {
	String[] reasons() default "房价涨了";
	String initials();
}
```

### 附加返回类型与复式注解类型

注解值可以是基本类型、枚举、Class引用、注解类型本身，或者任意这些类型的数组。我们以注解类型为例：

```java
public @interface Date {
	int month();
	int day();
	int year();
}



@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Ignore {
	Date date();
}

//使用示例
@Ignore(date=@Date(month=1, day=2, year=2014))
public void testC() {}
```

### 包注解

注解的目标除了方法、属性等外，还可以是包，那么包注解写在哪呢？方法在在包对应的目录中，创建一个名为package-info.java的源文件，这个文件应该包含所有的包注解，后面跟随适当的package语句。除此之外，这个文件不能够包含其它任何东西。示例如下：

```java
@TestPackage(isPerformance=true) package sis.testing;
```


