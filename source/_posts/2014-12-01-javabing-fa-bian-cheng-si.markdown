---
layout: post
title: "Java并发编程(四)"
date: 2014-12-01 22:43:50 +0800
comments: true
toc: true
categories: 
- java
---

在学习了《Java编程思想》中关于[并发编程](/blog/2014/09/02/javabing-fa-bian-cheng-san/)的内容后，继续学习Java并发编程。

<!--more-->

## 1. 常用的并发构件
### 为什么是synchronized?

这个单词的意思是同步，那么Java中synchronized表示什么意思呢？其实就是同步被锁定对象的主内存块。

* 当进入一个synchronized代码块时，持有锁的线程和被锁定对象主内存中的视图会进行同步。
* 当synchronized代码块执行完之后，被锁定对象所做的任何修改会在线程锁释放之前刷回到主内存中。

而volatile变量，在使用之前总是会从主内存中再读出来。线程所写的值总会在指令完成之前被刷回到主内存中。volatile变量不会引入线程锁，是真正线程安全的。**但只有写入时不依赖当前状态（读取的状态）的变量才应该声明为volatile变量。对于要关注当前状态的变量，只能借助线程锁保证绝对安全性。**

### Lock有什么好处？

* 添加不同类型的锁，比如读取锁和写入锁。
* 对锁的阻塞没有限制，即允许在一个方法中上锁，在另一个方法中解锁。
* 如果线程得不到锁，比如锁由另外一个线程持有，就允许该线程后退或继续执行，或者做点别的事情——运用tryLock()方法。
* 允许线程尝试取锁，并可以在超过等待时间后放弃。

Lock接口的两个实现类：

* ReentranLock: 本质上与同步块一样，但更灵活些。
* ReentranReadWriteLock: 在读多写入的时候，性能更好。

### ConcurrentHashMap
ConcurrentHashMap是HashMap的并发版本，改进了Collections.synchronizedMap()功能。它是concurrent包中最有用的类之一，不仅提供了多线程的安全性，而且性能更优。它提供了原子操作的新方法：

* putIfAbsent(): 如果没有对应键，则将键值对添加到HashMap中。
* remove(): 如果键存在，且值与当前状态相等，则用原子方式移除键值对。
* replace(): 当键存在时，进行原子替换。

### CopyOnWriteArrayList
它是标准ArrayList的替代品，通过copy-on-write来实现线程安全性，对修改列表的任何操作都会创建一个新复本。当快速、一致的数据快照（不同的读取器读到的数据偶尔可能会不一样）比完美的同步以及性能上的突破更重要时，这种共享数据的方法非常理想，经常出现在非关键任务中。

### Queue
Java有些多线程编程模型在很大程度上依赖于Queue实现线程安全性。BlockingQueue是最简单的实现。向队列put()时，如果队列满则放入线程会等待。从队列take()时，如果队列空，则取出线程阻塞。

Queue接口全是泛型`Queue<E>`，利用这一点把工作项封装到一个人工容器中会更方便。例如工作单元MyAwesomeClass，与其用`BlockingQueue<MyAwesomeClass>`不如使用`BlockingQueue<WorkUnit<MyAwesomeClass>>`：

```java
public class WorkUnit<T> {
	private final T workUnit;
	public T getWork() {return workUnit;}
	public WorkUnit(T workUnit) {
		this.workUnit = workUnit;
	}
}
```

有了这层间接引用，可以添加额外的元数据而不用牺牲MyAwesomeClass的完整性。例如在WorkUnit中添加用于测试、性能指标和运行时系统信息等。

除了基本的put()和take()方法，BlockingQueue还提供了还超时的放入和取出方法：offer(E e, long timeout, TimeUnit unit)和poll(long timeout, TimeUnit unit)。

Java 7还引入了TransferQueue，本质上是多了transfer()操作的BlockingQueue。在BlockingQueue中，当上游线程池比下游快时，可能会引发一些问题，导致LinkedBlockingQueue溢出。反之，如果下游比上游快，则可能队列经常空着。TransferQueue可以优化这种情况，调控上/下游的速度。当消费线程在等待时，transfer()操作会马上把工作项传给它，否则就会阻塞直到取走工作项的线程出现。可以把这看做“挂号信”选项，即正在处理工作项的线程在交付当前工作项之前不会开始其他工作项的工作。

用TransferQueue取代BlockingQueue的代码性能可能会更好，因为前者的实现考虑了现代编译器和处理器的特性，执行效率更高。

## 2. 控制执行
如果每个工作单元都启动一个新线程执行，效率会太低。因此可以利用线程池来执行工作单元/任务。

### 任务建模
任务建模可以采用三种办法：Callable, Future接口和FutureTask类。

#### Callable接口
Callable接口代表一段可以调用并返回结果的代码，典型用法是匿名实现类：

```java
final MyObject obj = new MyObject();

Callable<String> cb = new Callable<String>() {
	public String call() throws Exception {
		return obj.someMethod();
	}
};

String s = cb.call();
```

#### Future接口
Future接口用来表示异步任务。主要有三个方法：

* get()，获取结果，如果没执行完会阻塞，直到能取得结果。
* cancel()，在结束前取消。
* isDonw()，判断是否结束。

```java
interface ArchiveSearcher { String search(String target); }
 class App {
   ExecutorService executor = ...
   ArchiveSearcher searcher = ...
   void showSearch(final String target)
       throws InterruptedException {
     Future<String> future
       = executor.submit(new Callable<String>() {
         public String call() {
             return searcher.search(target);
         }});
     displayOtherThings(); // do other things while searching
     try {
       displayText(future.get()); // use future
     } catch (ExecutionException ex) { cleanup(); return; }
   }
 }
```

#### FutureTask类
FutureTask类是Future接口的常用实现类，实现了Runnable接口，因此可以由执行者调度。它提供的方法基本是Future和Runnable接口的组合：get(), cancel(), isDone(), isCancelled()和run()。它还提供了两个很方便的构造器：一个以Callable为参数，另一个以Runnable为参数。

```java
FutureTask<String> future =
       new FutureTask<String>(new Callable<String>() {
         public String call() {
           return searcher.search(target);
       }});
executor.execute(future);
```

### ScheduledThreadPoolExecutor(STPE)
STPE是Executors类工厂方法的众多执行者之一。它有以下特点：

* 可以预定线程池大小，也可自适应
* 所安排的任务可以定期执行，也可只运行一次。

```java
ScheduledExecutorService stpe = Executors.newScheduledThreadPool(2);

final Runnable msgReader = new Runnable() {
	public void run() {
		//...
	}
};

//每10毫秒唤醒一个线程。该线程可以尝试poll一个队列...
ScheduledFuture<?> hndl = stpe.scheduleAtFixedRate(msgReader, 10, 10, TimeUnit.MILLISECONDS);
```

## 3.分支/合并框架
这是Java 7重点突出的框架之一，用于轻量级并发，实现线程池中任务的自动调度。

先来看看之前的并发算法可能存在的问题。如果某个线程的运行队列都是小任务，而另一个全是大任务。那么小任务的线程可能会空闲很多。而基于Work-Stealing（工作窃取）算法的ForkJoin则可以很好地解决此问题。

![image](/myresource/images/image_blog_2014-12-02-fork-join.GIF)

* 分支/合并框架引入一种新的执行者服务，称为ForkJoinPool
* ForkJoinPool处理比线程更小的并发单元ForkJoinTask
* ForkJoinTask是一种由ForkJoinPool以更轻量化的方式所调度的抽象
* 通常使用两种任务（尽管都表示为ForkJoinTask实例）：“小型”任务是无需耗费太多时间就可以直接执行的任务；“大型”任务是需要分解（可能多次分解）后再执行的任务。

这个框架的关键特性之一就是这些轻量的任务都能生成新的ForkJoinTask实例，而这些实例将仍由执行它们父任务的线程池来安排调度。这就是分而治之。例如在归并算法中，就可以将左侧、右侧的排序任务视为一个ForkJoinTask，在递归过程中，不断产生小型任务执行。下面的示例是一个对微博按时间归并排序的例子：

```java
//RecursiveAction继承自ForkJoinTask<Void>
public class MicroBlogUpdateSorter extends RecursiveAction {
  private static final int SMALL_ENOUGH = 32;
  private final Update[] updates;
  private final int start, end;
  private final Update[] result;

  public MicroBlogUpdateSorter(Update[] updates_) {
    this(updates_, 0, updates_.length);
  }

  public MicroBlogUpdateSorter(Update[] upds_, int startPos_, int endPos_) {
    start = startPos_;
    end = endPos_;
    updates = upds_;
    result = new Update[updates.length];
  }

  private void merge(MicroBlogUpdateSorter left_, MicroBlogUpdateSorter right_) {
    int i = 0;
    int lCt = 0;
    int rCt = 0;
    while (lCt < left_.size() && rCt < right_.size()) {
      result[i++] = (left_.result[lCt].compareTo(right_.result[rCt]) < 0) ? left_.result[lCt++]
          : right_.result[rCt++];
    }
    while (lCt < left_.size())
      result[i++] = left_.result[lCt++];
    while (rCt < right_.size())
      result[i++] = right_.result[rCt++];
  }

  public int size() {
    return end - start;
  }

  public Update[] getResult() {
    return result;
  }

  @Override
  protected void compute() {
	  //如果数组太小，就用系统排序
    if (size() < SMALL_ENOUGH) {
      System.arraycopy(updates, start, result, 0, size());
      Arrays.sort(result, 0, size());
    } else {
      int mid = size() / 2;
      MicroBlogUpdateSorter left = new MicroBlogUpdateSorter(updates, start,
          start + mid);
      MicroBlogUpdateSorter right = new MicroBlogUpdateSorter(updates, start
          + mid, end);
      invokeAll(left, right);
      merge(left, right);
    }
  }
  
    public static void main() {
    List<Update> lu = new ArrayList<Update>();
    String text = "";
    final Update.Builder ub = new Update.Builder();
    final Author a = new Author("Tallulah");

    for (int i = 0; i < 256; i++) {
      text = text + "X";
      long now = System.currentTimeMillis();
      lu.add(ub.author(a).updateText(text).createTime(now).build());
      try {
        Thread.sleep(1);
      } catch (InterruptedException e) {
      }
    }
    Collections.shuffle(lu);
    Update[] updates = lu.toArray(new Update[0]); // Avoid allocation by passing
                                                  // zero-sized array
    MicroBlogUpdateSorter sorter = new MicroBlogUpdateSorter(updates);
    ForkJoinPool pool = new ForkJoinPool(4);
    pool.invoke(sorter);

    for (Update u : sorter.getResult()) {
      System.out.println(u);
    }
  }
}
```


如果下面这些问题答案是肯定的，那么就适合于使用分支/合并框架：

* 问题的子任务是否无需与其他子任务有显式的协作或同步也可以工作？
* 子任务是不是不会对数据进行修改，只是经过计算得出结果？
* 对于子任务来说，分而治之是不是很自然的事？子任务是不是会创建更多的子任务，而且它们要比派生出它们的任务粒度更细？











