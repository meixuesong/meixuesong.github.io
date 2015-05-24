---
layout: post
title: "java并发编程（二）"
date: 2014-09-02 21:03:49 +0800
comments: true
toc: true
categories: 
- java
---

本文是《Java编程思想》第21章并发的读书笔记。[Java并发编程（一）](/blog/2014/08/30/javabing-fa-bian-cheng/)

<!--more-->

##3. 终结任务
### 3.1 阻塞
一个任务进入阻塞状态，可能有如下原因：

1. 调用sleep(milliseconds)
2. 调用wait()挂起线程，直到线程得到了notify()或notifyAll()（Java5中的signal或signalAll）
3. 等待某个输入/输出完成
4. 试图在某个对象上调用同步控制方法，但对象锁不可用。

早期代码中还有suspend()和resume()来阻塞和唤醒线程，但现在已经被废止了（可能导致死锁），还有stop()也已经废止了（因为不释放线程获得的锁）。

### 3.2 中断
有几种方法中断线程。

一是声明一个变量canceled，然后正常的run方法中循环检查它的值，从而决定是否跳出循环，退出run方法。

二是调用Thread类的interrupt()方法，该方法提供了离开run()循环而不抛出异常的第二种方式。这种方式必须持有Thread对象。


如果调用Executor的shutdownNow()，那么它将发送一个interrupt()调用给它启动的所有线程。如果想只中断某一个线程，可以使用Future的cancel方法。下面是各种中断的示例：

#### 中断Sleep Runnable
```java
public class ThreadInterrupt {
	
	public static void main(String[] args) {
		ExecutorService exec = Executors.newCachedThreadPool();
		Future f = exec.submit(new SleepInterruptThread());
		try {
			TimeUnit.SECONDS.sleep(1);
			f.cancel(true);
			
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		System.out.println("退出主程序");
	}
}

public class SleepInterrupt implements Runnable {
	@Override
	public void run() {
		try {
			TimeUnit.SECONDS.sleep(10);
			System.out.println("end sleep 10s");
		} catch (InterruptedException e) {
			e.printStackTrace();
		}

		System.out.println("exit SleepInterrupt run");
	}
}
```

上面的代码可以正常中断Sleep线程，捕获了InterruptedException异常。

#### 中断Sleep Thread

```java
public class ThreadInterrupt {
	
	public static void main(String[] args) {
		Thread f = new SleepInterruptThread();
		f.start();
		try {
			TimeUnit.SECONDS.sleep(1);
			f.interrupt();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		System.out.println("退出主程序");
	}
}

public class SleepInterruptThread extends Thread {
	@Override
	public void run() {
		try {
			TimeUnit.SECONDS.sleep(5);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}

		System.out.println("exit SleepInterrupt run");
	}
}

```

上面的代码可以正常中断Sleep线程，捕获了InterruptedException异常。

#### 中断IO线程
```java
public class ThreadInterrupt {
	public static void main(String[] args) {
		ExecutorService exec = Executors.newCachedThreadPool();
		Future f = exec.submit(new IOInterrupt(System.in));
		try {
			TimeUnit.SECONDS.sleep(1);
			f.cancel(true);
			
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		System.out.println("退出主程序");
	}
}

public class IOInterrupt implements Runnable {
	private InputStream in;

	public IOInterrupt(InputStream is) {
		in = is;
	}

	@Override
	public void run() {
		try {
			in.read();
		} catch (IOException e) {
			e.printStackTrace();
		}

		System.out.println("exit run");
	}
}

```
**对于IO阻塞线程，则无法进行中断！从catch语句中没有InterruptedException也可以看出。**同样无法中断的还有SynchronizedBlocked，也就是如果线程进入synchronized方法或临界区中后，将无法中断。

对于网络访问这样的IO阻塞，如果不能中断有时挺烦人的。一个较笨的办法是关闭底层资源（例如关闭连接。）示例如下：

```java
InputStream socketInput = new Socket("localhost", 8080).getInputStream();
exec.execute(new IOBlocked(socketInput));
//...
exec.shutdownNow(); //无法中断线程
//...
socketInput.close(); //关闭后，解除阻塞。
```

**Java提供的各种nio类具有更人性化的I/O中断，被阻塞的nio通道会自动地响应中断。**

**synchronized方法或临界区上的阻塞，存在锁住程序的可能。而ReentrantLock上的阻塞则具备被中断的能力。**例如当线程1 lock后，线程2也请求lock，在等待的过程中将产生阻塞，调用Thread.interrupt或Future.cancel可以将其中断。

### 3.3 检查中断
当你在线程上调用interrupt()时，如何保证安全地退出run方法，释放该释放的资源？

如果类必须响应interrupt()，那么就必须建立一种策略。当创建了需要清理的对象后，就必须紧跟try-finally子句，使得无论run()循环如何退出，都能正常清理。

## 4. 线程之间的协作
###4.1 wait()与notifyAll()
调用sleep()和yield()时，锁并没有被释放。而调用wait()时，线程的执行被挂起，对象上的锁被释放。wait()表示无限期等待下去，直到notify或notifyAll，它也可以传入参数表示时间到期后恢复。当wait恢复时，会首先重新获取进入wait时释放的锁，在这个锁变为可用之前，是不会被唤醒的。

**只能在同步控制方法或者同步控制块里调用wait(), notify()和notifyAll()！**否则虽然能够编译通过，但运行时将报异常：IllegalMonitorStateException。为什么要这样设计？[这篇博客](http://javarevisited.blogspot.sg/2011/05/wait-notify-and-notifyall-in-java.html)作了解释。如果不这样做，就没有锁，就可能导致下一节中的“错失的信号”。

当从wait唤醒时，往往需要判断特定条件是否满足，如果不满足就返回到wait中，惯用的方法就是使用while来编写这种代码。下例是一个汽车打蜡抛光的示例，其它两个线程未列出。

```java
class Car {
private boolean waxOn = false;
public synchronized void waxed() {
waxOn = true;
notifyAll();
}
public synchronized void buffed() {
waxOn = false;
notifyAll();
}
public synchronized void waitForWaxing() throws InterruptedException {
while (waxOn == false) {
wait();
}
}
public synchronized void waitForBuffing() throws InterruptedException {
while (waxOn == true) {
wait();
}
} 
}

```

####错失的信号
当两个线程协作时，要特别注意可能会错过某个信号，例如下例T1通知T2，但是有可能T2收不到这个信号：

```java
T1:
synchronized(shareMonitor) {
     //<setup condition for T2>
     shareMonitor.notify();
}

T2:
while(someCondition) {
     //Point 1
     synchronized(shareMonitor) {
          shareMonitor.wait();
     }
}
```

以上代码运行到Point1时，如果调度到了T1，则T2收不到通知，就会永远在那里等待。T2正确的做法是：

```java
synchronized(shareMonitor) {
     while(someCondition) {
          shareMonitor.wait();
     }
}
```

###4.2 notify()与notifyAll()
两者的不同之处在于，前者只唤醒一个线程，而后者唤醒同一锁定的所有线程。当有多个等待线程时，notify唤醒哪一个线程由调度决定。notifyAll唤醒多个线程后，它们将先为锁而战，先取得锁的线程先执行。

什么情况下使用notify或者notifyAll？在多个等待的线程中，如果它们都在等同一个条件，并且当条件变为真时，只有一个线程从中受益，那么用notify比notifyAll更好，因为它避免浪费CPU循环。 notify()只唤醒其中一个。因此当你使用notify时要确保只唤醒正确的那个。

notifyAll并不是唤醒所有等待线程，而是等待某个特定锁的所有线程。

### 4.3 生产者和消费者
除了wait()、notify()和notifyAll()方法用于同步方法或者同步代码块外，也可以使用Lock、Condition、await()、signal()和signalAll()方法。示例如下：

```java
class Car {
	private Lock lock = new ReentrantLock();
	private Condition condition = lock.newCondition();
	private boolean waxOn = false;
	public void waxed() {
		lock.lock();
		try {
			waxOn = true;
			condition.signalAll();
		} finally {
			lock.unlock();
		}
	}
	
	public void waitForWaxing() throws InterruptedException {
		lock.lock();
		try {
			while (waxOn == false) 
				condition.await();
		} finally {
			lock.unlock();
		}
	}
	
	//...
}
```

注意，每个lock()的调用都必须紧跟一个try-finally子句，以保证所有情况都可以释放锁。在await()、signal()或signalAll()之前，必须拥有这个锁。

使用wait()和notifyAll()这样的方法来解决任务互操作的问题比较复杂。在典型的生产者-消费者实现中，常使用先进先出队列来存储被生产和消费的对象。BlockingQueue接口提供了这样的同步队列，该接口有多种实现，常见的是LinkedBlockingQueue和ArrayBlockingQueue(固定尺寸)。

如果消费者试图从队列中获取对象，而此时该队列为空，那么消费者将挂起，直到队列中有可消费的内容。阻塞队列可以解决很多问题，比wait()和notifyAll()相比，要简单得多，也更加可靠。示例如下：

```java
class LiftOffRunner implements Runnable {
	private BlockingQueue<LiftOff> rockets;
	public LiftOffRunner(BlockingQueue<LiftOff> queue) {
		rockets = queue;
	}
	
	public void add(LiftOff lo) {
		try {
			rockets.put(lo);
		} catch(InterruptedException e) {
			print("Interrupted during put");
		}
	}
	
	public void run() {
		try {
			while(! Thread.interrupted)) {
				LiftOff rocket = rockets.take(); //阻塞直至rockets中有东西
				rocket.run();
			}
		} catch(InterruptedException e) {
			print("Exiting LiftOffRunner");
		}
	}
}

//其它线程可以往rockets中添加内容，无需同步方法或者锁。
```

### 4.4 任务间使用管道进行输入/输出
通过输入/输出在线程间进行通信也很有用。这种管道在Java IO库中的对应物就是PipedWriter类和PipedReader类。这也是“生产者-消费者”的变体。示例如下：

```java
class Sender implements Runnable {
	private PipedWriter out = new PipedWriter();
	public PipedWriter getWriter() { return out;}
	public void run() {
		try {
			while (true) {
				for(char c = 'A'; c <= 'z'; c++) {
					out.write(c);
					TimeUnit.MILLISECONDS.sleep(rand.nextInt(500));
				}
			}
		} catch(IOException e) {
			//...
		} catch(InterruptedException e ) {
			//...
		}
	}
}


class Receiver implements Runnable {
	private PipedReader in;
	public Receiver(Sender sender) {
		in = new PipedReader(sender.getWriter());
	}
	
	public void run() {
		try {
			while (true) {
				print("read: " + (char) in.read());
			}
		} catch (IOException e) {
			//...
		}
	}
}

//与普通I/O不能interrupt不同，PipedReader是可以中断的。

```

相比之下，BlockingQueue使用起来更加健壮而容易。

##5. 死锁
当以下四个条件同时满足时，就会发生死锁：

1. 互斥条件。任务使用的资源中至少有一个是不能共享的。
2. 至少有一个任务必须持有一个资源且正在等待获取一个当前被别的任务持有的资源。
3. 资源不能被任务抢占，任务必须把资源释放当作普通事件。
4. 必须有循环等待。A等待B持有的资源，B又等待C持有的资源，这样一直下去之后，直到X在等待A所持有的资源。

要防止死锁，只需破坏上述四条中的任意一条。破坏第4条是最容易的。
