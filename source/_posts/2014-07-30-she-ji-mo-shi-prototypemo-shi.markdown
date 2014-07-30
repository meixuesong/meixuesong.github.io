---
layout: post
title: "设计模式: 原型（Prototype）模式"
date: 2014-07-30 20:58:15 +0800
comments: true
categories: 
- 设计模式
---

原型（Prototype）模式的用处是：对于给定的原型对象，用复制的方法创建出更多的同类型对象。之前学习的工厂方法模式常常需要有一个与产品等级相同的等级结构，而原型模式则不需要这样。Java语言天生就支持原型模式。原型模式的结构图如下：

![image](/myresource/images/image_blog_2014-07-30_21.10.50.jpg)

<!--more-->

## `clone()`方法
Java的Object类提供了`protected Object clone()`方法，用于复制对象。而`Cloneable`接口用于在运行期告诉JVM可以安全地使用`clone()`方法，否则JVM将会抛出`CloneNotSupportedException`异常。

```java
//复制一个pandaA
pandaB = pandaA.clone();
```

一般而言，clone方法满足以下描述：

1. `x.clone() != x`，也就是说复制出来后，不是同一个对象。
2. 复制对象与被复制对象是同一种类型。
3. 在Java的API中，`x.clone().equals(x)`是成立的，因此建议要遵守这一条。

## 深复制和浅复制
* 浅复制：对象所有的变量与原来的对象值相同，所有对其它对象的引用仍然指向原来的对象。
* 深复制：对象所有的变量与原来的对象值相同，所有对其它对象的引用也指向被复制的新对象。

`clone()`方法是浅复制，而深复制可以通过序列化实现。例如：

```java
public class DeepCloneDemo implements Serializable {
	private String name;

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}
	
	public DeepCloneDemo deepClone() throws IOException, ClassNotFoundException {
		ByteArrayOutputStream bo = new ByteArrayOutputStream();
		ObjectOutputStream oo = new ObjectOutputStream(bo);
		oo.writeObject(this);
		
		ByteArrayInputStream bi = new ByteArrayInputStream(bo.toByteArray());
		ObjectInputStream oi = new ObjectInputStream(bi);
		
		return (DeepCloneDemo) oi.readObject();
	}

	@Override
	public int hashCode() {
		//...
	}

	@Override
	public boolean equals(Object obj) {
		//...
	}
}


//测试代码
public class DeepCloneDemoTest extends TestCase{
	public void testDeepClone() {
		DeepCloneDemo demo = new DeepCloneDemo();
		demo.setName("Demo");
		
		try {
			DeepCloneDemo demo2 = demo.deepClone();
			Assert.assertFalse(demo2 == demo);
			Assert.assertEquals(demo, demo2);
			
		} catch (ClassNotFoundException | IOException e) {
			e.printStackTrace();
			Assert.assertFalse(true);
		}
	}
}
```

注意要实现Serializable接口。如果不希望某个属性被序列化，可以使用`transient`关键字，例如：`private transient int age;`。

## 什么时候用原型模式
如果类是动态加载的，给每个类配备clone方法，就可以在运行时创建。

原型模式的优点是：允许动态地增加或减少产品类；提供简化的创建结构，不需要工厂方法那样的等级结构；为软件提供动态加载新功能的能力；

原型模式的缺点是：每个类都必须有clone方法，这对新类来说很容易，但已有的类就不一定，例如引用了不支持序列化的间接对象时，或者含有循环结构的时候。