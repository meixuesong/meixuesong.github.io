---
layout: post
title: "Java并发编程(三)"
date: 2014-09-02 23:13:06 +0800
comments: true
categories: 
- java
---
本文是《Java编程思想》第21章并发的读书笔记。[Java并发编程（一）](/blog/2014/08/30/javabing-fa-bian-cheng/)、[Java并发编程（二）](/blog/2014/09/02/javabing-fa-er/)

<!--more-->

##6. 新类库中的构件
java.util.concurrent引入的新类库，有助于编写更简单和健壮的并发程序。

##6.1 CountDownLatch
用于同步一个或多个任务，强制它们等待由其他任务执行的一组操作完成。可以向CountDownLatch对象设置一初始值，任务在这个对象上调用wait()方法都将阻塞，直到计数值为0。其它任务结束工作时，可以调用countDown()来减少这个计数值。

示例代码：

```java
public class LatchDemo {
	private static class Latch implements Runnable {
		private CountDownLatch latch;
		Latch(CountDownLatch latch) {
			this.latch = latch;
		}

		@Override
		public void run() {
			try {
				doSomething();
				System.out.println("Latch runing...");
				TimeUnit.SECONDS.sleep(3);
				System.out.println("Latch sleeped 3 seconds.");
				//2. 当完成后，调用countDown()，将计数减1
				latch.countDown();
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}

		private void doSomething() {}
	}
	
	private static class LatchWaiter implements Runnable {
		private CountDownLatch latch;
		LatchWaiter(CountDownLatch latch) {
			this.latch = latch;
		}

		@Override
		public void run() {
			try {
				System.out.println("LatchWaiter waiting...");
				//3. 一直等到latch的计数变为0
				latch.await();
				System.out.println("LatchWaiter exit wait...");
			} catch (InterruptedException e) {
				//todo
			}
		}

		private void doOtherthing() {}
	}

	public static void main(String[] args) {
		//1. 先赋一个值，例如1
		CountDownLatch latch = new CountDownLatch(1);
		ExecutorService exec = Executors.newCachedThreadPool();
		exec.execute(new Latch(latch));
		exec.execute(new LatchWaiter(latch));
		exec.shutdown();
	}
}
```

注意：CountDownLatch只会触发一次，计数值不能重置。

###6.2 CyclicBarrier
CyclicBarrier适用于有一组任务，它们并行工作，直到它们全部完成后，才一起向前移动。与CountDownLatch只会触发一次不同，CyclicBarrier可以多次重用。

```java
public class CyclicBarrierDemo {
	private static class Horse implements Runnable {
		private CyclicBarrier barrier;
		private String id;
		private int stepCount = 0;
		private static Random rand = new Random(5000);

		Horse(String id, CyclicBarrier barrier) {
			this.id = id;
			this.barrier = barrier;
		}

		@Override
		public void run() {
			doSomething();
			try {
				while (!Thread.interrupted()) {
					synchronized (this) {
						System.out.println(String.format("Thread %s is doing.",
								id));
						stepCount++;
						TimeUnit.MILLISECONDS.sleep(rand.nextInt(5000));
						System.out.println(String.format("Thread %s has done.",
								id));
					}
					// await：待所有线程都在这一步调用await方法。
					barrier.await();
				}
			} catch (InterruptedException e) {
				// ...
			} catch (BrokenBarrierException e) {
				// ...
			}
		}

		private void doSomething() {
		}

		private int getStepCount() {
			return stepCount;
		}
	}

	public static void main(String[] args) {
		final ExecutorService exec = Executors.newCachedThreadPool();
		int threadCount = 3;
		final Counter cycleCount = new Counter();

		// 注意构造方法的参数
		CyclicBarrier barrier = new CyclicBarrier(threadCount, new Runnable() {
			@Override
			public void run() {
				// 当所有threadCount线程结束时，执行到这里。
				System.out.println("All Thread has done." + cycleCount.count);
				cycleCount.count++;
				if (cycleCount.count == 2) {
					exec.shutdownNow();
				}
			}
		});
		for (int i = 0; i < threadCount; i++) {
			exec.execute(new Horse(String.valueOf(i), barrier));
		}
	}

	private static class Counter {
		int count = 0;
	}
}

/*output:
Thread 1 is doing.
Thread 2 is doing.
Thread 0 is doing.
Thread 1 has done.
Thread 2 has done.
Thread 0 has done.
All Thread has done.0
Thread 0 is doing.
Thread 1 is doing.
Thread 2 is doing.
Thread 2 has done.
Thread 1 has done.
Thread 0 has done.
All Thread has done.1
*/
```

###6.3 DelayQueue
DelayQueue是一个无界的BlockingQueue，用于放置实现了Delayed接口的对象，其中的对象只能在其到期时才能从队列中取走。队列是有序的，延迟时间最长的对象最先取出。可以使用多种获取方法：poll(取出并从队列删除，不等待), take(取出并从队列删除，如果队列中还没有则等待), peek(取出但不从队列删除，不等待，可能会返回未过期的)，详细区别见JavaDoc。

DelayQueue适合的场景包括：

1. 关闭空闲连接。服务器中，有很多客户端的连接，空闲一段时间之后需要关闭之。
2. 缓存。缓存中的对象，超过了空闲时间，需要从缓存中移出。
3. 任务超时处理。在网络协议滑动窗口请求应答式交互时，处理超时未响应的请求。

###6.4 PriorityBlockingQueue
这是一个很基础的优先级队列，具有可阻塞的读取操作。放入该队列的对象实现Comparable接口就可以轻松实现优先级调度了，优先级越小则优先级越高。代码示例：

```java
PriorityBlockingQueue<Runnable> queue = 
		new PriorityBlockingQueue<Runnable>();
ExecutorService exec = Executors.newCachedThreadPool();
exec.execute(new Producer(queue, exec));
exec.execute(new Consumer(queue));
```

### 6.5 ScheduledExecutor
通过使用ScheduledExecutor.schedule()（运行一次任务）或者scheduleAtFixedRate()（每隔规则的时间重复执行任务），你可以将Runnable对象设置为在将来的某个时刻执行。代码示例：

```java
public class SheduledThreadDemo {
	ScheduledThreadPoolExecutor scheduler = new ScheduledThreadPoolExecutor(10);
	
	public void repeat(Runnable event, long initialDelay, long period) {
		scheduler.scheduleAtFixedRate(event, initialDelay, period, TimeUnit.SECONDS);
	}
	
	public void schedule(Runnable event, long delay) {
		scheduler.schedule(event, delay, TimeUnit.SECONDS);
	}
}
```

### 6.6 Semaphore
普通的锁（concurrent.locks或synchronized锁）在任何时刻都只允许一个任务访问一项资源，而**计数信号量**允许n个任务同时访问这个资源。作为一个示例，Pool是一个对象池，管理者数量有限的对象，要使用对象可以先签出，用完后再签入。

Semaphore 可以很轻松完成信号量控制，Semaphore可以控制某个资源可被同时访问的个数，通过 acquire() 获取一个许可，如果没有就等待，而 release() 释放一个许可。比如在Windows下可以设置共享文件的最大客户端访问个数。 

Semaphore实现的功能就类似厕所有5个坑，假如有10个人要上厕所，那么同时只能有多少个人去上厕所呢？同时只能有5个人能够占用，当5个人中 的任何一个人让开后，其中等待的另外5个人中又有一个人可以占用了。另外等待的5个人中可以是随机获得优先机会，也可以是按照先来后到的顺序获得机会，这取决于构造Semaphore对象时传入的参数选项。单个信号量的Semaphore对象可以实现互斥锁的功能，并且可以是由一个线程获得了“锁”，再由另一个线程释放“锁”，这可应用于死锁恢复的一些场合。

```java
public class Pool<T> {
	private int size;
	private List<T> items = new ArrayList<T>();
	private volatile boolean[] checkedOut; //跟踪被签出的对象
	private Semaphore available;
	
	public Pool(Class<T> classObject, int size) {
		this.size = size;
		checkedOut = new boolean[size];
		available = new Semaphore(size, true); //size个许可，先进先出:true
		for(int i = 0; i < size; ++i) {
			try {
				//Assums a default constructor
				items.add(classObject.newInstance());
			} catch(Exception e) {
				throw new RuntimeException(e);
			}
		}
	}
	
	public T checkOut() throws InterruptedException {
		available.acquire(); //从Semaphore获取一个许可，如果没有将阻塞
		return getItem();
	}
	
	public void checkIn(T x) {
		if (releaseItem(x))
			//释放一个permit，返回到Semaphore， 可用许可加1
			available.release();
	}
	
	private synchronized T getItem() {
		for(int i=0; i < size; ++i) {
			if (! checkedOut[i]) {
				checkedOut[i] = true;
				return items.get(i);
			}
		}
		
		return null;
	}
	
	private synchronized boolean releaseItem(T item) {
		int index = items.indexOf(item);
		if (index == -1) return false;
		if (checkedOut[index]) {
			checkedOut[index] = false;
			return true;
		}
		
		return false;
	}
}
```

### 6.7 Exchanger
Exchanger用于实现两个人之间的数据交换，每个人在完成一定的事物后想与对方交换数据，第一个先拿出数据的人将一直等待第二个人拿着数据到来时，才能彼此交换数据。

好比两个毒贩要进行交易，一手交money，一手交drug，不管谁先来到接头地点后，就处于等待状态了，当另外一方也到达接头地点时，两者的数据就立即交换了，然后就可以各忙各的了。

示例代码如下和运行结果如下：

```java
public class ExchangerTest {
	public static void main(String[] args) {
		ExecutorService service = Executors.newCachedThreadPool();
		final Exchanger<String> exchanger = new Exchanger<String>();
		service.execute(new Runnable() {
			public void run() {
				try {
					String data1 = "money";
					System.out.println("线程"
							+ Thread.currentThread().getName() 
							+ "正在把数据" + data1 + "换出去");
					Thread.sleep((long) (Math.random() * 10000));
					String data2 = (String) exchanger.exchange(data1);
					System.out.println("线程"
							+ Thread.currentThread().getName() 
							+ "换回数据为" + data2);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		});
		service.execute(new Runnable() {
			public void run() {
				try {
					String data1 = "drug";
					System.out.println("线程"
							+ Thread.currentThread().getName() + "正在把数据"
							+ data1 + "换出去");
					Thread.sleep((long) (Math.random() * 10000));
					String data2 = (String) exchanger.exchange(data1);
					System.out.println("线程"
							+ Thread.currentThread().getName() + "换回数据为"
							+ data2);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		});
	}
}

/** output:
线程pool-1-thread-1正在把数据money换出去
线程pool-1-thread-2正在把数据drug换出去
线程pool-1-thread-2换回数据为money
线程pool-1-thread-1换回数据为drug
*/
```