---
layout: post
title: "设计模式:组合（Composite）模式"
date: 2014-07-31 21:08:30 +0800
comments: true
categories: 
- 设计模式
---

组合模式将对象以树状结构组织起来，达成“部分－整体”的层次结构，使得客户端对单个对象和组合对象的使用具有一致性。结构示意图：

![image](/myresource/images/image_blog_2014-07-31_21.14.15.jpg)

<!--more-->

此模式涉及三个角色：

1. Component角色：定义共有的接口及其默认行为。
2. Leaf角色：叶节点，不能有下级子对象。
3. Composite角色：树枝节点，可以有下级子对象的节点。

组合模式根据实现方式的不同，分为安全方式和透明方式。区别主要在于接口的定义。Composite角色拥有add、remove、getChild等方法，这些方法对于Leaf角色完全没有用处。因此Component角色是否定义这些方法，就形成了两种实现方式。

### 透明方式
这种方式在Component中定义所有的方法，不管这些方法对于Leaf角色是否有用。这样做的好处是所有角色都有相同的接口，客户端可以统一的方式对待所有对象。缺点是不够安全，因为Leaf角色的add方法没有意义，可能在运行期出错。透明方式的组合模式结构图如下：

![image](/myresource/images/image_blog_2014-07-31_21.29.20.jpg)

可以看出，这种方式的Leaf和Composite没有什么区别，都实现了Component的所有接口方法。但Leaf角色的add, remove等方法都是平庸实现。

### 安全方式
这种方式的Component只定义公共的接口，不包括Composite角色的add, remove等方法。结构如下图：

![image](/myresource/images/image_blog_2014-07-31_22.11.35.jpg)

不论采用哪种方式，其中composite属性都是指向父节点的引用。这样就可以很容易地遍历所有的父对象。
