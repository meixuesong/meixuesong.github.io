---
layout: post
title: "优先队列"
date: 2014-09-27 23:08:56 +0800
comments: true
toc: true
categories: 
- 算法
---
优先队列是广泛使用的一种抽象数据类型。例如如果你需要从10亿个元素中选出最大的十个，你不可能对10亿规模的数组排序。对于这些类似的场景，我们不一定要求它们全部有序，或者不一定要一次就将它们排序。我们会收集一些元素，处理当前键值最大的元素，然后再收集更多的元素，再处理当前键值最大的元素。例如应用程序的事件优先级，模拟系统，任务调度等。在这种情况下，优先队列应该支持两种操作：**删除最大元素和插入元素。**

<!--more-->

## 1. API
先定义优先队列的API框架：

```java
public interface IMaxPQ<T extends Comparable<T>> {
	public void insert(T v);
	public T max();
	public T delMax();
	public boolean isEmpty();
	public int size();
}
```

## 2. 实现方法
优先队列可以使用有序或无序的数组或链表来实现。其思路非常简单，插入时，向数组或链表增加元素。如果数组或链表是有序的，新元素就应该在适当的位置。而删除时，找出最大的元素进行删除。

上面的实现方法性能非常差，在最坏的情况下，需要线性时间来完成。而基于堆的实现则能够保证更好的性能。

### 2.1 堆的定义
在二叉堆的数组中，每个元素都要保证大于等于另外两个特定位置的元素。如果把所有元素画成一棵二叉树，就是父结点要大于等于子结点，此时表示**堆有序**。

完全二叉树只用数组就可以表示。根结点在位置1，其子结点在位置2和3。位置k的结点的父结点的位置为k/2, 它的两个子结点的位置分别为2k和2k+1。

### 2.2 堆的算法
堆的有序化过程涉及上浮和下沉。当某个结点的优先级上升时，我们需要由下至上恢复堆的顺序（上浮）。当某个结点的优先级下降时，我们需要由上至下恢复堆的顺序（下沉）。

#### 2.2.1 上浮
如果某个结点的优先级上升，比它的父结点更大，那么就需要交换它和它的父结点。交换后，还要继续判断是否比现在的父结点更大，一直到遇到更大的父结点。

#### 2.2.2 下沉
下沉与上浮正好相反，当某个结点的优先级下降时，需要**与它的两个结点中的较大者比较**，如果比子结点小，就进行交换。交换后继续与子结点比较，直到比它的两个子结点都大。

#### 2.2.3 算法实现

```java
public class MaxPQ<T extends Comparable<T>> implements IMaxPQ<T>{
	private T[] pq;
	private int n = 0;
	
	public MaxPQ(int maxN) {
		pq = (T[]) new Comparable[maxN + 1];
	}
	
	@Override
	public void insert(T v) {
		pq[++n] = v;
		swim(n);
	}

	@Override
	public T max() {
		if (n > 0) {
			return pq[1];
		}
		
		return null;
	}

	@Override
	public T delMax() {
		T max = pq[1];    //根结点最大
		exchange(1, n--); //与最后一个结点交换
		pq[n + 1] = null; //防止对象游离
		sink(1);          //恢复堆的有序性
		
		return max;
	}

	@Override
	public boolean isEmpty() {
		return n == 0;
	}

	@Override
	public int size() {
		return n;
	}
	
	private boolean less(int i, int j) {
		return pq[i].compareTo(pq[j]) < 0;
	}
	
	private void exchange(int i, int j) {
		T t = pq[i]; pq[i] = pq[j]; pq[j] = t;
	}
	
	//上浮
	private void swim(int k) {
		while (k > 1 && less(k / 2, k)) {
			exchange(k / 2, k);
			k = k / 2;
		}
	}
	
	//下沉
	private void sink(int k) {
		while (2 * k <= n) {
			int j = 2 * k;
			if (j < n && less(j, j + 1)) {
				j++;
			}
			
			if (!less(k, j)) {
				break;
			}
			
			exchange(k, j);
			k = j;
		}
	}
}
```

**对于含有N个元素的基于堆的优先队列，插入元素操作只需不超过(lgN + 1)次比较，删除最大元素的操作需要不超过2lgN次比较！**

#### 2.2.4 多叉堆
用数组表示的完全三叉树构造堆也很容易。位置k的结点大于等于3k-1, 3k, 3k+1的结点，小于等于位于(k+1)/3的结点。甚至任意的d叉树也不困难，只是需要平衡在树高和每个结点的d个子结点中找到最大值的代价。

#### 2.2.5 动态数组大小
上面代码中的数组大小是固定的，如果要实现动态数组大小，只需要根据情况在insert中增加数组长度，在delMax中减少数组长度。

## 3. 堆排序
使用优先队列，我们有了一种新的排序方法：堆排序。把所有元素插入一个查找最小元素的优先队列，然后重复调用删除最小元素的操作来将它们按顺序删除。

堆排序分为两个阶段：构造堆和下沉排序。

### 3.1 堆的构造
对于N个给定元素的数组，最简单的堆构造方法是从左至右遍历数组，用swim()保证指针左侧的所有元素已经是一棵堆有序的完全树。但一个更聪明更高效的办法是从右至左用sink()函数构造子堆。如果一个结点的两个子结点都已经是堆了，那么在该结点上调用sink可以将它们变成一个堆。这个过程会递归地建立起堆的秩序。开始时我们只需要扫描数据中的一半元素，最后在位置1上调用sink方法，扫描结束。

### 3.2 下沉排序
当堆构造完成后，将堆中的最大元素删除，然后放到堆缩小后数组中空出的位置。

### 3.3 算法实现

```java
public class PQSort {
	public void sort(Comparable[] a) {
		int n = a.length;
		//构造堆
		for(int k = n/2; k >= 1; k--) {
			sink(a, k, n);
		}
		
		//下沉排序
		while (n > 1) {
			exchange(a, 1, n--);
			sink(a, 1, n);
		}
	}
	
	private void sink(Comparable[] a, int k, int n) {
		while (2 * k <= n) {
			int j = 2 * k;
			if (j < n && less(a, j, j+1)) {
				j++;
			}
			
			if (!less(a, k, j)) {
				break;
			}
			
			exchange(a, k, j);
			k = j;
		}
	}
	
	private static boolean less(Comparable[] a, int i, int j) {
		//要减1
		return a[i - 1].compareTo(a[j - 1]) < 0;
	}
	
	private static void exchange(Comparable[] a, int i, int j) {
		//要减1
		Comparable t = a[i - 1];
		a[i - 1] = a[j - 1];
		a[j - 1] = t;
	}
}
```
对于一百万随机整数，排序时间大约在750ms。


用堆实现的优先队列在现代应用程序中越来越重要，因为它能在**插入操作和删除最大元素操作**混合的动态场景中保证对数级别的运行时间。

## 小结
学完了常用的算法，总结一下。各种算法的性能特点如下表：

![image](/myresource/images/IMG_20140928_224145.jpg)

快速排序是最快的通用排序算法。

Java中，java.util.Arrays.sort()方法会根据不同的参数类型选择排序方法。对于原始数据类型使用（三向切分）快速排序，对引用类型使用归并排序。这种选择实际上暗示着用速度和空间（对于原始数据类型）来换取稳定性（对于引用类型）。
