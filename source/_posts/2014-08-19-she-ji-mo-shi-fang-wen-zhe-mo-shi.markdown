---
layout: post
title: "设计模式:访问者模式"
date: 2014-08-19 22:17:28 +0800
comments: true
categories: 
- 设计模式
---
访问者(Visitor)模式的目的是封装一些施加于某种数据结构元素之上的操作，一旦这些操作需要修改的话，接受这个操作的数据结构则可以保持不变。假如要对一个不同类型的聚集进行遍历，为了判断不同的类型对象，需要写很多的if else，而访问者模式可以解决此问题。示意类图如下：

![image](/myresource/images/image_blog_20140819_232009.jpg)

<!--more-->

1. Visitor角色：声明一个或多个访问操作。
2. ConcreteVisitor角色：实现接口方法。
3. Node角色：声明一个接受操作，接受一个访问者对象作为一个参数。
4. Concrete Node角色：实现接受操作。
5. ObjectStructure角色：遍历结构中的所有元素，如果需要，提供高层次的接口让访问者对象可以访问每一个元素；如果需要，可以设计成一个复合对象或者一个聚集，如List或Set。

### 单分派和多分派
方法的接收者（即方法所属的对象）和方法的参量统称为方法的宗量。单分派语言根据一个宗量的类型进行方法的选择，多分派语言根据多于一个的宗量的类型对方法进行选择。

Java语言支持静态的多分派和动态的单分派。对于Java方法重载（Overload），在编译期会根据方法的接收者类型和方法的所有参量类型进行分派，因此是静态多分派。而方法覆盖（Override），是在运行时仅仅根据方法的接收者类型进行分派。

在访问者模式中，数据结构的每一个节点都可以接受一个访问者的调用，此节点向访问者对象传入节点对象，而访问者对象则反过来执行节点对象的操作。这样的过程就叫做“双重分派”。

### 示例代码

```java

//class ConcreteVisitor
public void visitA(NodeA node) {
	System.out.println(node.operationA());
}

//class NodeA
public void accept(Visitor visitor) {
	visitor.visitA(this);
}

//class ObjectStructure
public void action(Visitor visitor) {
	for(Enumeration e = nodes.elements(); e.hasMoreElements();) {
		node = (Node)e.nextElement();
		node.accept(visitor);
	}
}

//class Client
public static void main(String[] args) {
	ObjectStructure aObjects = new ObjectStructure();
	aObjects.add(new NodeA());
	aObjects.add(new NodeB());
	Visitor visitor = new ConcreteVisitor();
	aObjects.action(visitor);
}

```

### 访问者模式的优缺点
访问者模式仅应当用在被访问的类结构非常稳定的情况。如果出现需要加入新的Node的情况，则必须在每一个访问对象中加入一个对应于这个新节点的访问操作，这将是一个大规模修改，违背“开-闭”原则。

如果系统有比较稳定的数据结构，又有易于变化的算法，使用访问者模式就比较合适。

访问者模式的优点包括：

1. 增加新的操作变得非常容易，只需要增加一个新的访问者。
2. 此模式将行为集中到一个访问者对象中，而不是分散到节点类中。因此可以在访问的过程中将执行操作的状态积累在自己内部（例如计算合计值）。

访问者模式的缺点：增加新的节点类变得很困难。每增加一个新的节点都要在抽象访问者角色中增加一个新的抽象操作，并在每个具体访问者类中增加相应的具体操作。

访问者模式是一个存争议的设计模式。



——《Java与模式》读书笔记