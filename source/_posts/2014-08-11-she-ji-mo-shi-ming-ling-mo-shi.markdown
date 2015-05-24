---
layout: post
title: "设计模式:命令模式"
date: 2014-08-11 22:58:11 +0800
comments: true
toc: true
categories: 
- 设计模式
---

命令模式将发出命令和执行命令的责任分割开，委派给不同的对象。类图如下：

![image](/myresource/images/image_blog_20140811_233515.jpg)

<!--more-->
1. Client角色：创建具体命令对象，并确定接收者。
2. Command角色：声明抽象接口，通常是接口或抽象类。
3. ConcreteCommand角色：定义一个接收者和行为之间的弱耦合；负责调用接收者的相应操作。
4. Invoker角色：负责调用命令对象执行请求。
5. Reciever角色：负责具体实施和执行一个请求。任何一个类都可以成为接收者。

Client的示例代码：

```java
public static void main(String[] args) {
	Receiver receiver = new Receiver();
	Command command = new ConcreteCommand(receiver);
	Invoker invoker = new Invoker(command);
	invoker.action();
}
```

上面的代码中，invoker.action调用command.execute，execute方法调用receiver.action，receiver.action是真正实施命令的方法。

模式实现时，可以考虑命令是“重”还是“轻”。如果轻，则命令只是提供请求者与接收者之间的耦合。如果是重，则命令执行也可放在命令中，接收者可以省略。更常见的是中间情况，由命令类动态决定调用哪一个接收者类。如果要支持undo, redo，则命令类要存储状态信息。

可以把命令对象集合在一起，实现宏命令。命令模式的缺点是命令可能会非常多。命令模式可用于：

1. 需要在不同的时间指定请求，将请求排队。命令对象可以在序列化之后发送到另一台机器上。
2. 支持undo, redo操作。
3. 从日志中读回所有命令，重新执行execute方法，恢复系统数据。
4. 需要支持交易的系统，一个交易结构封装了一组数据更新命令。命令模式可以使系统增加新的交易类型。
