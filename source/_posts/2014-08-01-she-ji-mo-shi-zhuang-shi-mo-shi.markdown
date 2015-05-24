---
layout: post
title: "设计模式:装饰模式"
date: 2014-08-01 20:00:16 +0800
comments: true
toc: true
categories: 
- 设计模式
---

装饰模式以对客户端透明的方式扩展对象的功能。客户端并不会觉得对象在装饰前和装饰后有什么不同。装饰模式可以在不使用创造更多子类的情况下，将对象的功能加以扩展。其类图所下：

![image](/myresource/images/image_blog_2014-08-01_20.13.33.jpg)

<!--more-->

图中4个角色说明如下：

1. Component角色，一个抽象接口，被装饰对象和装饰对象都遵循的接口。在实际中可以是接口、抽象或具体类。
2. Concrete Component角色，被装饰的具体对象。
3. Decorator角色，持有Component对象的实例，可以是抽象类。
4. ConcreteDecorator角色，负责给构件对象贴上附加的责任。

### 什么情况下使用装饰模式？
1. 需要扩展一个类的功能，或给一个类增加附加责任。
2. 需要动态给一个对象增加功能，这些功能可以再动态地撤销。
3. 需要增加由一些基本功能的排列组合而产生的非常大量的功能，而继承关系就变得不现实。

### 装饰模式的优缺点
装饰模式的优点包括：

1. 可以动态地贴上一个需要的装饰，或者除掉一个不需要的装饰。
2. 通过使用不同的具体装饰类，以及这些装饰类的排列组合，可以创造出很多不同行为的组合。

装饰模式的缺点是比继承要使用更多的对象，更多的对象会使得查错变得困难。

### 装饰模式的简化
不论如何简化，必须保证：

1. ConcreteDecorator类必须实现/继承自一个共同的父类Component。
2. 尽量保持Component作为一个“轻”类。

常见的简化包括：

1. 没有Component，只有ConcreteComponent，此时，Decorator可以是ConcreteComponent的子类，ConcreteComponent扮演双重角色。
2. 没有Decorator，只有ConcreteDecorator，但如果有两个以上的。

### 其它
纯粹的装饰模式对客户端的要求是不要声明ConcreteDecorator类型的变量，而应当声明Component类型的变量。这也就是针对抽象编程。因此，ConcreteDecorator不能有Component接口之外的方法。但现实中的装饰模式允许改变接口，增加新方法，即客户端可以声明ConcreteDecorator类型的变量。这就有点像是适配器模式。

装饰模式与适配器模式其实是不一样的。适配器模式的目的是改变接口，常常改写或者增加新的方法来适配接口。而装饰模式是保持接口不变，增强或增加功能。它们的类图是不一样的。

以Java的IO库为例，Reader类型的对象读入字符(Character)流，而InputStreamReader是一种Reader类型，把InputStream类型对象包装起来，从而把byte的API转换成字符流的API。这就是适配器模式的例子。即InputStreamReader把InputStream的API适配成Reader的API。

而BufferredReader则是一个装饰类，因为它实现Reader，并且包装一个Reader，接口未变，但提供更优的性能。但它不是一个100％的装饰类，因为它提供了一个readLine()的新方法。

以InputStream相关类为例，如下所示：

![image](/myresource/images/image_blog_20140803_002859.jpg)

图中，红色类为适配器模式，将其它类型（如Byte数组）接口转换成InputStream接口。而绿色及其子类为装饰模式，各角色：

1. Component角色：InputStream
2. Concrete Component角色：红色的类
3. Decorator角色：绿色的类
4. ConcreteDecorator角色：最下面的四个类。

附各类的主要用途：

1. ByteArrayInputStream: 为多线程的通信提供缓冲区操作功能，接收Byte数组作为流的源。
2. FileInputStream：接收一个File对象作为流的源。
3. PipedInputStream：与PipedOutputStream配合使用，用于读入一个数据管道的数据，接收PipedOutputStream作为源。
4. StringBufferInputStream：接收一个String对象作为流的源。
5. FilterInputStream：过滤输入流，将另一个输入流作为流的源。
6. BufferInputStream：内部提供内存缓冲区，从此缓冲区提供数据。
7. DataInputStream：提供多字节的读取方法，读取原始数据类型的数据。
8. LineNumberInputStream: 提供带有行计数功能和按行号读取数据的过滤输入流。不常用，主要用于编译器。
9. PushbackInputStream：提供特殊功能，将已经读取的字节“推回”到输入流中。不常用，主要用于编译器。
10. ObjectInputStream：读取使用ObjectOutputStream序列化的流，将其反序列化。
11. SequenceInputStream：将两个已有的输入流连接起来，形成一个输入流。










