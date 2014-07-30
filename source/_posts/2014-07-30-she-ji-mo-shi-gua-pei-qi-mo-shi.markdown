---
layout: post
title: "设计模式:适配器模式"
date: 2014-07-30 22:31:42 +0800
comments: true
categories: 
- 设计模式
---

适配器模式分为类的适配器和对象的适配器。它们都是把被适配类的API转换成目标类的API。但前者使用继承关系，而后者使用委派关系。它们的结构如下图：

![image](/myresource/images/image_blog_2014-07-30_22.38.26.jpg) ![image](/myresource/images/image_blog_2014-07-30_22.40.21.jpg)

<!--more-->

上图中的三个角色：

1. Target接口，这是目标接口，表示要适配成这个接口。
2. Adaptee，这是被适配的对象，表示要将它适配成Target。
3. Adapter，适配器，将Adaptee适配成Target。

第一张图对应的是类的适配器，第二张图是对象的适配器。从图上看，区别主要是Adapter到Adaptee的连线不一样，一个是继承，一个是依赖。

## 类的适配器
先看类的适配器，即第一张图。Adapter继承自Adaptee，因此继承了方法operation1，再加上它自己实现的方法operation2，从而实现了Target接口，完成适配。由于是继承关系，因此Adaptee必须是一个类，不能是接口。

## 对象的适配器
对第二张图，Adaptee是被适配的接口，可以是接口或者类。Adapter包含一个对Adaptee的引用。Adapter的operation1方法，只需调用Adaptee.operation1，同时增加operation2，从而实现Target接口，完成适配。

因为没有了继承关系，因此一个适配器可以把多种不同的源适配到同一个目标。

## 什么情况下使用适配器模式
1. 系统需要使用现有类，而此类的接口不符合系统需要。
2. 建立一个可重复使用的类，用于与一些彼此没有太大关联的一些类一起工作。
3. 对象的适配器可用于改变多个已有的子类的接口。