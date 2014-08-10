---
layout: post
title: "设计模式:观察者模式"
date: 2014-08-10 11:36:40 +0800
comments: true
categories: 
- 设计模式
---

观察者模式也称为发布-订阅模式，它定义了一种一对多的依赖关系，让多个观察者同时监听一个主题对象。当主题对象的状态发生变化时，会通知观察者对象，使它们能够自动更新自己。它的类图如下所示：

![image](/myresource/images/image_blog_20140810_115301.jpg)

在实际应用中，如果有多个ConcreteSubject，也可以将Subject变成抽象类，将observers和notifyObservers方法上移到抽象Subject。




