---
layout: post
title: "Java并发编程（一）"
date: 2014-08-30 21:58:15 +0800
comments: true
categories: 
- java
---

本文是《Java编程思想》第21章并发的读书笔记。

<!--more-->

操作系统：抢占式（调度机制会周期性地中断线程，将上下文切换到另一个线程）、协作式（每个任务自己放弃控制）。

## 1. 基本线程机制
###1.1 定义任务

```java
public class LiftOff implements Runnable {
     public void run() {
          //...
          Thread.yield(); //声明，我已经干完重要的事，可以把CPU让给其他任务了。
     }
}
```

###1.2 Thread类

```java
Thread t = new Thread(new LiftOff());
t.start();
```

###1.3 使用Executor

```java
ExecutorService exec = Executors.newCachedThreadPool(); //or newFixedThreadPool, newSingleThreadExecutor
exec.execute(new LiftOff());

exec.shutdown(); //防止加入新任务。
```

###1.4 从任务中产生返回值
Runnable不返回任何值，Callable接口可以返回值。两者的区别只是后者的方法是call()而不是run()。

```java
class TaskWithResult implements Callable<String> {
     public String call() {
          return "result";
     }
}

ExecutorService exec = Executors.newSingleThreadExecutor();
Future<String> future = exec.submit(new TaskWithResult());
String result = future.get(); //get方法会一直等线程结束后返回结果。isDone()查询Future是否已经完成。
```

###1.5 休眠

```java
public class SleepingTask extends LiftOff {
     public void run() {
          try {
               while(countDown-- > 0) {
                    //...
                    TimeUnit.MILLISECONDS.sleep(100);
               }
          } catch(InterruptedException e) {
               //...
          }
     }
}
```

###1.6 优先级

```java
     public void run() {
          Thread.currentThread().setPriority(Thread.MAX_PRIORITY);
     }
```

Windows有7个优先级， Solaris有2^31个优先级。各操作系统不一致，因此建议只使用三个优先级：Thread.MAX_PRIORITY, NORM_PRIORITY, MIN_PRIORITY。

###1.7 后台线程
后台线程指程序运行时在后台提供通用服务的线程，并且不属性程序中不可或缺的部分。**当所有非后台线程结束时，程序就终止了，同时会杀死所有后台线程。**如果有非后台线程还在运行，则程序不会终止。

要设置为后台线程，必须在线程启动之前调用setDaemon()方法。

```java
     Thread daemon = new Thread(new LiftOff() );
     daemon.setDaemon(true); //必须在start()方法前调用
     daemon.start(); 
```

可以通过定制的ThreadFactory创建后台线程，例如：

```java
public class DaemonThreadFactory implements ThreadFactory {
     public Thread newThread(Runnable r) {
          Thread t = new Thread(r);
          t.setDaemon(true);
          //还可以设置优先级、名称等，这些将成为新线程的默认值。
          
          return t;
     }
}

ExecutorService exec = Executors.newCachedThreadPool(new DaemonThreadFactory()); //这个Factory将用于创建新的线程。
exec.execute(new LiftOff()); 
```

`isDaemon()`方法用于判断是否后台线程。后台线程创建的任何线程都将自动设置为后台线程。

注意！对于后台线程，在不会执行`finally`子句的情况下就会终止其`run()`方法：

```java
class ADaemon implements Runnable {
	public void run() {
		try {
			//...
			TimeUnit.SECONDS.sleep(1);
		} catch(InterruptedException e) {
			//...
			//注意，此时已经是false, 因为异常被捕获时将清理这个标志
			print("isInterrupted(): " + isInterrupted()); 
		} finally {
			print("会运行到这吗？")
		}
	}
}

public class DaemonsDontRunFinally {
	public static void main(String[] args) {
		Thread t = new Thread(new ADaemon());
		t.setDaemon(true);
		t.start();
	}
}
```

一旦`setDaemon(true)`，finally并没有被执行。因为一旦main结束，所有后台线程就立即终止了。

### 1.8 编码的变体
除了实现Runnable，也可以直接继承Thread类。但是由于Java不支持多重继承，所以继承自Thread适应的场景要少一些。

```java
private class SampleThread extends Thread{
	public SampleThread() {
		super("线程名称");  //线程名称可通过getName()获取。
	}
	
	public void run() {
		//...
	}
}
```

自管理的Runnable

```java
public class SelfManaged implements Runnable {
	private Thread t = new Thread(this);
	public SelfManaged() {
		t.start();  //注，不建议在构造器中启动线程，可能会有问题，建议使用Executor
	}
	
	public void run() {
		//...
	}
	
	public static void main(String[] args) {
		new SelfManaged();
	}
}
```

### 1.9 加入一个线程
某个线程在另一个线程t上调用`t.join()`方法，此线程被挂起，直到t线程结束（即`t.isActive() == false`）。join方法也可以加超时参数，表示如果时间到期还未结束的话，join()方法总能返回。

### 1.10 捕获异常
线程中的未捕获的异常会导致系统不稳定，但常规方法并不能在外面捕获这些异常，因此需要借助特殊处理。下面的例子创建了一个新类型的ThreadFactory，它将在每个新创建的Thread对象上附着一个Thread.UncaughtExceptionHandler。

```java
class MyUncaughtExceptionHandler implements Thread.UncaughtExceptionHandler {
	@Override
	public void uncaughtException(Thread t, Throwable e) {
		// TODO Auto-generated method stub
	}
}

class HandlerThreadFactory implements ThreadFactory {

	@Override
	public Thread newThread(Runnable r) {
		Thread t = new Thread(r);
		t.setUncaughtExceptionHandler(new MyUncaughtExceptionHandler());
		
		return t;
	}
}

ExecutorService exec = Executors.newCachedThreadPool(new HandlerThreadFactory());
exec.execute(new SomeThread());
```

如果你知道将要在代码中处处使用相同的异常处理器，那么更简单的方式是在Thread类中设置一个表态域，示例如下：

```
Thread.setDefaultUncaughtExceptionHandler(new MyUncaughtExceptionHandler());
```

## 2. 共享受限资源
### 2.1  解决共享资源竞争
Java提供了关键字synchronized，为防止资源冲突提供支持。如果某个线程处于一个对synchronized方法的调用中，那么这个线程在从该方法返回之前，其它所有调用类中任何synchronized方法的线程都会被阻塞。也就是说，对于某个特定对象来说，其所有synchronized方法共享同一个锁。

线程可以多次获得对象的锁，例如先调用synchronized方法获得锁后，又调用该类的其它方法获得锁。JVM会跟踪对象加锁的计数，每次调用加1，离开synchronized方法时减1。当计数变为0则锁被完全释放。

synchronized static方法可以在类的范围内防止对static数据的并发访问。

如果你正在写一个变量，它可能接下来被另一个线程读取，或者在读取一个上一次已经被另一个线程写过的变量，那么你必须使用同步，并且，读写线程都必须用相同的监视器锁同步。

Lock对象也用于解决共享资源竞争。它必须被显式地创建、锁定和释放。

```java
public class MutexEvenGenerator extends IntGenerator {
	private Lock lock = new ReentrantLock();
	public int next() {
		lock.lock();
		try {
			//...
			
			//注意！必须在try中返回值，以避免lock.unlock之后将数据暴露给其它线程。
			return someValue; 
		} finally {
			lock.unlock();
		}
		
		//不要在这里返回值
	}
}
```

Lock提供了更细粒度的控制能力。使用Lock，可以更加自由地控制锁。例如尝试获得锁，如果获取不到，可以先干点别的事：

```java
boolean captured = lock.tryLock();

//设置超时时间，超时则触发异常。
try {
	boolean captured = lock.tryLock(2, TimeUnit.SECONDS);
} catch(InterruptedException e) {
}

```

### 2.2 原子性和易变性
原子性可用于除long、double之外的所有基本类型上的“简单操作”（读取和写入）。可以保证它们会被当作不可分（原子）的操作来操作内存。但JVM在读取和写入64位（long和double变量）时，可以拆成两个32位操作。因此可能导致“字撕裂”。作为普通开发者，**不要依赖原子操作而移除了同步，那会得不偿失。**

关键字`volatile`可以帮助获得原子性。`volatile`还确保了数据的可视性。当一个域声明为`volatile`时，那么只要对它进行了写操作，即使使用了本地缓存，其它读操作也可以看到这个修改。因为`volatile`域会被立即写入主内存中，而读取操作就发生在主存中。

非`volatile`域上的原子操作不必刷新到主存，因此其它任务读取该域时可能看不到新值（修改操作的任务可以看到新值）。如果多个任务(线程)在同时访问某个域，那么这个域就应该是`volatile`的，否则这个域就应该经由同步来访问。同步也会导致向主存刷新。

### 2.3 原子类
Java引入了AtomicInteger, AtomicLong, AtomicReference等特殊的原子性变量类，它们提供机器级别上的原子性。常规编程很少派上用场，但在涉及性能调优时，会有用武之地。

需要强调的是，Atomic类被设计用来构建java.util.concurrent中的类，因此只有在特殊情况下才在自己的代码中使用它们。通常依赖于锁（Lock, synchronized）更安全一些。

### 2.4 临界区(Critical section)
以下同步控制块就是临界区：

```java
synchronized(synObject) {
	//这部分代码一次只能被一个线程访问
}
```

使用同步控制块，可以防止整个方法都同步，显著提高性能。但要注意，上面例子中，只要没有退出同步控制块，那么被同步对象synObject的所有同步方法都无法被其它线程调用。

### 2.5 线程本地存储
去除变量共享，在线程本地存储也是防止共享资源冲突的一种方法。如果你有5个线程都要使用变量x所表示的对象，那么线程本地存储就会生成5个用于x的不同的存储块。ThreadLocal对象用于线程本地存储。

ThreadLocal对象通常当作静态域存储。示例如下：

```java
public class ThreadLocalVariableHolder {
	private static final ThreadLocal<Integer> value = new ThreadLocal<Integer>() {
		@Override
		protected synchronized Integer initialValue() {
			return 10;
		}
	};
	
	public static int get() {
		return value.get();
	}
	
	public static void increment() {
		value.set(value.get() + 1);
	}
}


public class Accessor implements Runnable {
	@Override
	public void run() {
		ThreadLocalVariableHolder.increment();
		//..
	}
}
```
