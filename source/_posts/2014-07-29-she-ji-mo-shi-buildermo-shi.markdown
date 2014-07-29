---
layout: post
title: "设计模式:Builder模式"
date: 2014-07-29 22:28:54 +0800
comments: true
categories: 
- 设计模式

---

Builder模式感觉没什么特别的，甚至都不值得称为一种模式。无非就是由Director构建部分，然后再使用一个方法完成构建过程。但Builder模式对于参数太多的构造器却非常有用。先看Builder模式的类图：

![image](/myresource/images/image_blog_2014-07-29_22.38.17.png)

[这篇博客](/blog/2014/06/27/effective-java-chuang-jian-he-xiao-hui-dui-xiang/)建议当构造器参数比较多时，考虑使用Builder模式。这是一种非常优雅的方式。

我觉得Builder模式的好处一是使客户端的代码很清晰，不需要那么多的set方法；二是实现了产品构建的原子性，也就是可以在build时，确保产品构建是有效的，如果某些部分或者参数有问题、冲突，就能够在build时失败，避免残次的半成品出现。

