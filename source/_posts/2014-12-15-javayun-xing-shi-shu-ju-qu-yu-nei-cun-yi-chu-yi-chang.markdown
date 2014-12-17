---
layout: post
title: "Java运行时数据区与内存溢出异常"
date: 2014-12-15 21:55:31 +0800
comments: true
categories: 
- java
---
JVM定义了各种运行时数据区用于程序执行。有些数据区随着JVM启动而创建，当JVM退出时销毁。另一些数据区则是随着线程而存亡。每个数据区都是内存，因此就存在内存溢出的异常。本文学习JVM有哪些数据区以及常见的内存溢出异常。

<!--more-->

## 1. 运行时数据区（Run-Time Data Areas）
根据[JVM规范](https://docs.oracle.com/javase/specs/jvms/se7/html/jvms-2.html#jvms-2.5)，运行时数据区主要分为以下部分。

### 1.1 程序计数器（Program Counter Register）
每个JVM线程拥有自己的程序计数器，各线程之间计数器互不影响，这部分区域可以称为线程私有的内存。在任何时间点，一个CPU核心都只会执行一个线程中某个方法的指令，这就是当前方法：

* 如果当前方法不是Native方法，程序计数器包含正在执行的虚拟机字节码指令的地址。
* 如果是Native方法计数器值为Undefined。

程序计数器所占内存非常小，也是唯一没有规定任何内存溢出异常的区域。

### 1.2 虚拟机栈（JVM Stacks）
每个线程同时也有一个私有的虚拟机栈，因此虚拟机栈的生命周期与线程相同。每个栈包括帧（frames），帧与方法调用相关，每当方法被调用，就会创建一个新的帧。当方法结束，帧也就被销毁。帧包括局域变量、自己的操作栈和当前方法的运行时常量池引用。

虚拟机栈与C语言中的栈相似，它包括局域变量和部分结果，并在方法调用和返回中扮演角色。除了push和pop帧，虚拟机栈并不提供其它直接操作。帧可能是在堆中分配内存。虚拟机栈的内存并不需要是连续的。

通常人们把Java内存分为堆和栈，其中栈就是虚拟机栈。虚拟机栈的内存可以是固定大小或者根据计算动态扩展。虚拟机栈涉及两个异常：

* StackOverflowError: 如果线程请求的栈深度大于允许的深度。
* OutOfMemoryError：如果栈是动态扩展的，扩展时无法申请足够的内存。

本地方法栈（Native Method Stack）与虚拟机栈发挥着相似的作用，但它是为Native方法服务。JVM规范并没有对其强制规定。HotSpot直接把本地方法栈和虚拟栈合二为一，相同对待。

栈虽然有两个异常，但实验时，如果是单线程操作，无论是栈帧太大还是虚拟机栈容量太小，基本只会出现StackOverflowError，示例如下：

```java
/**
* -Xss128k
*/
public class JavaVMStackSOF {
	private int stackLength = 1;
	public void stackLeak() {
		stackLength++;
		stackLeak();
	}
	
	public static void main(String[] args) {
		JavaVMStackSOF oom = new JavaVMStackSOF();
		try {
			oom.stackLeak();
		} catch(Throwable e) {
			...
		}
	}
}
```

实验中，只有多线程时，才会出现OutOfMemoryError。通过不停地创建线程，并且每个线程不停止，当线程足够多时就可以重现此异常。

### 1.3 堆（Heap）
堆是在JVM所管理的内存中最大的一块，它是所有线程共享的区域。当JVM启动时会创建此区域。所有对象实例和数组都在堆上分配（现在也有例外，参见[逸出分析](/blog/2014/12/06/li-jie-javaxing-neng-diao-you/)）。

堆中存储的对象由垃圾收集器负责回收。堆的大小可以是固定或者动态扩展。堆不需要连续内存空间，只要逻辑上连续即可。根据垃圾收集器的不同，堆内存有不同的管理方式。例如CMS采用分代收集算法，将堆分为年轻代和老年代；而G1则将堆分成大小相同的区域。详见[理解Java性能调优](/blog/2014/12/06/li-jie-javaxing-neng-diao-you/)。

堆涉及的内存异常为OutOfMemoryError，如果堆中没有内存用于实例分配并且无法再扩展时，就会抛出此异常。堆内存溢出很容易模拟，示例如下：

```java
/**
* -Xms20m -Xmx20m
*/
public static void main(String[] args) {
	List<SomeObject> list = new ArrayList<>();
	while(true) {
		list.add(new SomeObject());
	}
}
```


### 1.4 方法区（Method Area）
方法区也是所有线程共享的内存区域。它存储了每个类的信息，例如运行时常量池、属性和方法数据、方法和构造方法代码，包括类和实例初始化和接口初始化的特殊方法。

方法区随着虚拟机启动而创建。逻辑上它是堆的一部分，但JVM实现可以选择不对它进行垃圾收集或者压缩。JVM规范并没有强制规定它的位置和管理已编译代码的策略。它可以是固定大小或者动态扩展，也不需要是连续的。

对于HotSpot虚拟机来说，开发者更愿意把方法区称为永久代（Permanent Generation），但本质上两者并不等价。这仅仅是因为HotSpot设计团队使用永久代来实现方法区而已。但其它虚拟机（如Bea JRocket, IBM J9）并没有永久代的概念。

当方法区无法满足内存分配需求时，将抛出OutOfMemoryError异常。如果一些框架使用CGLib这类字节码技术，增强的类过多，或者JVM上的动态语言（如Groovy）持续创建类来实现语言动态特性，可能出现此异常。

### 1.5 运行时常量池
在[类文件与字节码](/blog/2014/12/04/lei-wen-jian-yu-zi-jie-ma/)中介绍了类文件的常量池，运行时常量池就是这个常量池的运行时表示。运行时常量池相对于类文件常量池主要有两个区别：

* 除了类文件中描述的符号引用外，还会把翻译出来的直接引用也存储在运行时常量池中。
* 运行时常量池可以在运行期间将新的常量加入池中。

运行时常量池的内存是从方法区分配出来的。当JVM创建类或接口时，会为它创建运行时常量池。因此它的内存受方法区内存限制，也可能抛出OutOfMemoryError异常。

### 1.6 直接内存
直接内存（Direct Memory）并不是JVM运行时数据区的一部分，也不是JVM规范定义的内存区域。但它也被频繁使用，可能导致OutOfMemoryError异常。

JDK 1.4中加入NIO类，引入了基于Channel与Buffer的I/O方式，可以使用Native函数库直接分配堆外内存，然后通过DirectByteBuffer对象作为这块内存的引用进行操作。由于避免了Java堆与Native堆之间复制数据，在一些场景能显著提高性能。

这部分内存虽然不受Java堆大小限制，但肯定会受本机总内存和寻址空间限制。因此动态扩展时可能出现OutOfMemoryError异常。

## 2. 内存Dump分析

在[理解Java性能调优](/blog/2014/12/06/li-jie-javaxing-neng-diao-you/)中介绍了jmap, jstat等工具可以查看内存映射和垃圾收集活动。这里介绍另一个工具Eclipse Memory Analyzer可以对堆内存溢出问题进行分析。首先需要生成堆转储文件。通过启用参数：

`-XX:+HeapDumpOnOutOfMemoryError`

JVM 就会在发生内存泄露时抓拍下当时的内存状态，也就是我们想要的堆转储文件。也可以在未溢出时用jmap创建转储文件。

有了转储文件，利用Eclipse Memory Analyzer tool打开该文件，就可以进行分析了。分析通常分为三步：

* 对内存状态获取一个整体印象。
* 找到最有可能导致内存泄露的元凶，通常也就是消耗内存最多的对象。
* 进一步查看这个内存消耗大户的具体情况，看看是否有什么异常行为。

![image](/myresource/images/image_blog_2014-12-17-20.30.59.jpg)


































