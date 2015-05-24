---
layout: post
title: "设计模式:迭代子模式"
date: 2014-08-10 12:18:42 +0800
comments: true
toc: true
categories: 
- 设计模式
---

迭代子模式是最常见的几个设计模式之一，Java Collection广泛使用迭代子来遍历其元素。之所以需要迭代子模式，是因为它将迭代逻辑与聚集对象分离，两者可以自由演变。其结构示意图如下：

![image](/myresource/images/image_blog_20140810_163841.jpg)

<!--more-->

1. Iterator：定义遍历元素所需的接口。
2. ConcreteIterator：实现Iterator接口，维护迭代过程中的游标位置。
3. Aggregate：给出创建迭代子对象的接口。
4. ConcreteAggregate：实现创建迭代子对象的接口，返回一个合适的具体迭代子实例。
5. Client：拥有对聚集和迭代子对象的引用，调用迭代子对象的迭代接口。

### 宽接口与窄接口
宽接口是指聚集提供了可以用来修改聚集元素的方法；否则就是窄接口。宽接口的典型示例是公开了类的一个List，因此破坏了聚集对象的封装。

聚集对象可以提供两个接口，对迭代子公开宽接口，而对外提供窄接口。因此，可以将迭代子类设计成聚集类的内部成员类。

### Java Iterator和ListIterator
Java Collection接口方法iterator()返回Iterator，而Java的List接口的listIterator()返回ListIterator类型。

![image](/myresource/images/image_blog_20140810_163856.jpg)

ListIterator提供了安全的修改方法add, remove和set。它们能够在迭代的过程中安全地修改List的内容。

* add()方法，在List当前位置插入一个对象。所谓当前位置就是：add方法增加对象后，调用previous()方法将返回这个对象。
* remove()方法，将当前元素删除。所谓当前元素就是：如果刚调用了next()或previous()方法，当前元素就是它们返回的元素。**注：每调用一次remove()，都需要先调用一次next()或者previous()，如果刚调用了add()，也必须先调用一次next()或者previous()。**
* set()方法，更新当前元素。当前元素的定义与remove()方法相同。每次set()之前，也必须调用next()或previous()。
