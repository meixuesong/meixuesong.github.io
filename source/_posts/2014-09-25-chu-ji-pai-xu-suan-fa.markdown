---
layout: post
title: "初级排序算法"
date: 2014-09-25 20:25:11 +0800
comments: true
toc: true
categories: 
- 算法
---
即使只使用类库提供的排序函数，学习排序算法仍然具有实际意义。因为排序算法是解决其他问题的第一步，类似的技术能够有效解决其它类型的问题。本文学习一些初级的排序算法，包括选择排序、插入排序和希尔排序。

<!--more-->
## 1. 排序模板
不同的排序程序只是在排序算法上不同，但排序的框架是相同的。因此先建立一个排序模板，在此基础上实现各种算法。

```java
public abstract class AbstractSort {
	protected final Logger logger = LoggerFactory.getLogger(getClass());
	
	//待实现的算法
	public abstract void sort(Comparable[] a);
	
	//进行比较
	protected static boolean less(Comparable v, Comparable w) {
		return v.compareTo(w) < 0;
	}
	
	//交换位置
	protected static void exchange(Comparable[] a, int i, int j) {
		Comparable t = a[i];
		a[i] = a[j];
		a[j] = t;
	}
	
	//打印数组
	protected static void show(Comparable[] a) {
		for (int i = 0; i < a.length; i++) {
			System.out.print(a[i] + " ");
		}
		System.out.println();
	}
	
	//验证是否为有序状态
	public static boolean isSorted(Comparable[] a) {
		for (int i = 1; i < a.length; i++) {
			if (less(a[i], a[i-1]))
				return false;
		}
		
		return true;
	}
}
```

为了粗略验证各种算法的效率，以10万的随机整数数组为对象进行排序，测试代码如下：

```java
public class SortTest extends TestCase {
	Integer[] array;
		
	@Override
	public void setUp() {
		int len = 1000000;
		array = new Integer[len];
		Random random = new java.util.Random();
		for(int i = 0; i < len; i++) {
			array[i] =  random.nextInt(100000000);
		}
	}
	
	public void testSort() {
		long from = System.nanoTime();
		AbstractSort sorter = new Selection();//或其它算法
		sorter.sort(array);
		System.out.format("totoalTime: %dms \n", (System.nanoTime() - from) / 1000000);		
		Assert.assertTrue(AbstractSort.isSorted(array));
	}
}
```

## 2. 选择排序(Selection)
选择排序是最简单的排序算法，即**不断地选择剩余元素中的最小者**：先找到数组中最小的元素，然后跟第一个元素交换。接下来在剩下的元素中找最小的元素，跟第二个元素交换。如此往复，直到整个数组遍历结束。代码实现如下：

```java
public class Selection extends AbstractSort{
	@Override
	public void sort(Comparable[] a) {
		int len = a.length;
		for(int i = 0; i < len; i ++) {
			int min = i;
			for (int j = i + 1; j < len; j++) {
				if (less(a[j], a[min])) {
					min = j;
				}
			}
			
			exchange(a, i, min);
		}
	}
}
```

性能：对于长度为N的数组，需要进行大约N^2/2次比较和N次交换。运行上面的测试代码，耗时：11424ms 

## 3. 插入排序(Insertion)
与选择排序一样，当前索引左边的所有元素都是有序的，但它们的最终位置还不确定，后续元素将会跟前面的元素比较，并插入适当的位置。当索引到达数组的最右端时，排序完成。代码实现如下：

```java
public class Insertion extends AbstractSort {
	@Override
	public void sort(Comparable[] a) {
		int len = a.length;
		for(int i = 1; i < len; i++) {
			for(int j = i; j > 0 && less(a[j], a[j-1]); j--) {
				exchange(a, j, j-1);
			}
		}
	}
}
```

性能：插入排序的性能取决于数组的初始顺序。对于一个很大且其中的元素已经有序或接近有序的数组进行排序效率很高。插入排序平均需要大约N^2/4次比较和N^2/4次交换。最坏的情况下则需要N^2次比较和N^2/2次交换。也就是说最坏的情况下（如初始排序是倒序的），插入排序比选择排序还要慢。运行上面的测试代码，耗时：15208ms，由于是随机数组，因此比选择排序还要慢。

## 4. 希尔排序(Shell)
希尔排序其实是基于插入排序。既然插入排序对有序数组效率很高，但对于乱序数组，元素只能一点一点地从一端移动到另一端。那么希尔排序就改进这一点，交换不相邻的元素，最终用插入排序将局部有序的数组排序。

其思想是使任意间隔为h的元素有序，称为h有序数组。排序时，如果h很大，我们就能将元素移动到很远的地方，为实现更小的h有序创造方便。代码实现如下：

```java
public class Shell extends AbstractSort {
	@Override
	public void sort(Comparable[] a) {
		int n = a.length;
		int h = 1;
		while (h < n/3) {
			h = 3 * h + 1;
		}
		//h:1, 4, 13, 40, 121, 364, 1093, ...
		
		while (h >= 1) {
			//这部分就是插入排序，但将位移由1变为了h
			for (int i = h; i < n; i++) {
				for (int j = i; j >= h && less(a[j], a[j-h]); j -= h) {
					exchange(a, j, j-h);
				}
			}
			
			h = h / 3;
		}
		
		draw();
	}
}
```	

性能：此算法的性能不仅取决于h，还取决于h之间的数学性质，比如它们的公因子。有很多论文研究不同的递增序列，但上面的代码似乎已经相当好，更优的递增序列有待发现。希尔排序对任意排序的数组表现也很好。运行上面的测试代码，耗时：160ms 

希尔排序对于中等大小的数组运行时间是可以接受的。它的代码量很小，不需要额外的内存空间。其它更高效的算法除了对于很大的N，它们可能只会比希尔排序快最多两倍，而且更复杂。
	
