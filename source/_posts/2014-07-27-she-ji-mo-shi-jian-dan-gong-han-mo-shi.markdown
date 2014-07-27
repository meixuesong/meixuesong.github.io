---
layout: post
title: "设计模式:简单工厂模式"
date: 2014-07-27 09:44:35 +0800
comments: true
categories: 
- 设计模式

---

简单工厂模式其实就是静态工厂方法模式，即通过静态工厂方法来创建对象。其结构可表示为：

![image](/myresource/images/image_blog_2014-07-27_1.png)

<!--more-->

来看个实际的例子，下图中，有多种水果。客户端不关心具体的水果是如何创建的，只需要告诉工厂方法，需要哪种水果类型，工厂方法负责具体水果的创建工作。

![image](/myresource/images/image_blog_2014-07-27_2.png)

工厂方法返回的是水果接口。水果接口也可以换成抽象类。这是针对抽象编程的一种体现。

```java
public class FruitFactory {
	public static Fruit getFruit(String type) {
		if (type.equalsIgnoreCase("apple")) {
			return new Apple();
		} else if (type.equalsIgnoreCase("orange")) {
			return new Orange();
		} else {
			throw new FruitFactoryException();
		}
	}
}
```

### 省略产品角色
如果具体产品只有一个（即只有一种水果）时，可以省略掉抽象产品角色，变成：

![image](/myresource/images/image_blog_2014-07-27_3.png)

### 合并工厂角色与抽象产品角色
有些情况下，工厂角色可以由抽象产品角色扮演，例如java.text.DateFormat类，如下图所示：

![image](/myresource/images/image_blog_2014-07-27_4.png)

### 三个角色全部合并
![image](/myresource/images/image_blog_2014-07-27_5.png)

```java
public class ConcreteProduct {
	public ConcreteProduct() {}
	
	public static ConcreteProduct factory() {
		return new ConcreteProduct();
	}
}
```

### 多个工厂方法
工厂类可以有一个或多个工厂方法，分别负责创建不同的产品对象。例如java.text.DateFormat类：

```java
	public final static DateFormat getDateInstance();
	public final static DateFormat getDateInstance(int style);
	public final static DateFormat getDateInstance(int style, Local locale);
```

###总结
简单工厂模式是非常基本的设计模式，会在较为复杂的设计模式中出现。它的核心是工厂类，客户端完全不关心构建的细节，只需消费产品。因此，简单工厂模式实现了对责任的分割。

但其缺点是当产品结构变得复杂时，工厂类将变得非常复杂。由于静态方法无法继承，因此工厂角色无法形成基于继承的等级结构。

在这种模式中，消费者(Client)和产品（Product）都满足“开－闭原则”，都能在引进新产品时，无需对现有代码进行修改。而工厂（Factory）则必须知道每一种产品以及如何创建它们，因此必须修改这个工厂的代码，不满足“开－闭”原则。