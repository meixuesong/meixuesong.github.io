---
layout: post
title: "设计模式:工厂方法模式"
date: 2014-07-27 22:11:04 +0800
comments: true
categories: 
- 设计模式

---

前文说到简单工厂方法的工厂类，对“开－闭”原则支持不够，当有新产品时，需要修改工厂类。而工厂方法模式可以解决这个问题。工厂方法模式的用意是定义一个创建产品对象的工厂接口，将实际创建工作推迟到子类中。其结构可表示为：

![image](/myresource/images/image_blog_2014-07-27_22.10.30.png)

<!--more-->
上图中，Factory和SomeProduct可以是接口或者抽象类，工厂方法factory的返回类型必须是SomeProduct，这也是针对接口编程的一个体现。

在实际项目中，产品类可能有多个层级，对应工厂类也有多个层级。当使Factory为抽象类时，可以将公共代码尽量往上层抽象。

工厂方法返回的对象不一定是新建的，有可能是之前新建的对象，缓存在那里。但一定是自己创建的，不可以是别的对象传入的对象。

ConcreteFactory1示例代码：

```java
public class ConcreteFactory1 implements Factory {
	public SomeProduct factory() {
		return new SomeConcreteProduct1();
	}  
}
```

Client代码示例：

```java
public class Client {
	private static Factory concreteFactory1,concreteFactory2;
	private static SomeProduct concreteProduct1, concreteProduct2;
	
	public static void main(String[] args) {
		concreteFactory1 = new ConcreteFactory1();
		concreteProduct1 = concreteFactory1.factory();
		concreteFactory2 = new ConcreteFactory2();
		concreteProduct2 = concreteFactory2.factory();
	}
}
```