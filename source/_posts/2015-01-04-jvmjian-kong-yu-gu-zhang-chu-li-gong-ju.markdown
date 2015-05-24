---
layout: post
title: "JVM监控与故障处理工具"
date: 2015-01-04 21:42:42 +0800
comments: true
toc: true
categories: 
- Java
---

本文介绍常用的Java虚拟机性能监控与故障处理工具。

<!--more-->

## 1. JDK命令行工具
### 1.1 [jps](http://docs.oracle.com/javase/7/docs/technotes/tools/share/jps.html)
与Unix下的ps命令相似，可以列出正在运行的虚拟机进程并显示主类（main()函数所在类）类名以及LVMID(Local Virtual Machine Identifier)。LVMID与PID是一致的。命令格式：

`jps [options] [hostid]`

选项 | 用途
---|---
-q | 只输出LVMID
-m | 输出JVM启动时传递给主类main()函数的参数
-l | 输出主类全名
-v | 输出JVM启动时的JVM参数

### 1.2 [jstat](http://docs.oracle.com/javase/7/docs/technotes/tools/share/jstat.html)，虚拟机统计信息监视工具

在[理解Java性能调优](/blog/2014/12/06/li-jie-javaxing-neng-diao-you/)中已经有描述。

### 1.3 [jinfo](http://docs.oracle.com/javase/7/docs/technotes/tools/share/jinfo.html), Java配置信息工具
用于实时查看和调整虚拟机各项参数。

### 1.4 [jmap](http://docs.oracle.com/javase/7/docs/technotes/tools/share/jmap.html), Java内存映像工具

在[理解Java性能调优](/blog/2014/12/06/li-jie-javaxing-neng-diao-you/)中已经有描述。

### 1.5 [jhat](http://docs.oracle.com/javase/7/docs/technotes/tools/share/jhat.html)， 堆转储快照分析工具

用于分析堆转储快照，内置一个微型HTTP服务器，分析结果后可在浏览器中查看。但这个工具并不常用。

### 1.6 [jstack](http://docs.oracle.com/javase/7/docs/technotes/tools/share/jstack.html), Java堆栈跟踪工具
用于生成虚拟机当前时刻的线程快照（threaddump），即当前每一条线程正在执行的方法堆栈集合。主要目的是定位线程出现长时间停顿的原因，如死锁、死循环、请求外部资源等。

当线程出现停顿时，通过jstack查看各线程的调用堆栈，就可以知道没有响应的线程到底在后台做什么。

选项 | 用途
---|---
-F | 当正常输出的请求不被响应时，强制输出线程堆栈
-l | 除堆栈外，显示关于锁的附加信息
-m | 如果调用本地方法的话，显示C/C++堆栈

## 2. JDK的可视化工具
### 2.1 JConsole
基于JMX的可视化监视、管理工具。直接通过集令后运行jconsol。

### 2.2 [VisualVM](http://visualvm.java.net/)，多合一故障处理工具

VisualVM Is Designed For You:

* **Application Developer**: Monitor, profile, take thread dumps, browse heap dumps
* **System Administrator**: Monitor and control Java applications across the entire network
* **Java Application User**: Create bug reports containing all the necessary information

在命令行执行`jvisualvm`即可


