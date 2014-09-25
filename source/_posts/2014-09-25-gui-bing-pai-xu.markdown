---
layout: post
title: "归并排序算法"
date: 2014-09-25 21:07:58 +0800
comments: true
categories: 
- 算法
---
所谓归并排序，是先把待排序数组分成两半，分别排序，然后将结果归并起来。归并排序最吸引人的地方是它能够保证将任意长度为N的数组排序所需时间和NlogN成正比。但其缺点是所需的额外空间和N成正比。

<!--more-->

## 1. 原地归并的抽象方法
实现归并是将两个不同的有序数组归并到第三个数组中。当归并一个大数组时，需要进行很多次归并，因此如果每次都创建一个新数组会有性能问题。所以要实现原地归并。下面的代码借助一个辅助数组，先将所有元素复制到辅助数组中，然后再把归并结果放回原数组。

```java
public abstract class AbstractMerge extends AbstractSort {
	//归并所需的辅助数组
	protected Comparable[] aux;
	/**
	 * 将a[lo..mid]和a[mid+1..hi]合并
	 * @param a
	 * @param lo
	 * @param mid
	 * @param hi
	 */
	public void merge(Comparable[] a, int lo, int mid, int hi) {
		int i = lo, j = mid + 1;
		
		//将a[lo..hi]复制到aux[lo..hi]
		for(int k = lo; k<= hi; k++) {
			aux[k] = a[k];
		}
		
		//再从aux归并到a[lo..hi]
		for(int k = lo; k <= hi; k++) {
			if (i > mid) {
				//左半边用尽，取右半边的元素
				a[k] = aux[j];
				j++;
			} else if (j > hi) {
				//右半边用尽，取左半边的元素
				a[k] = aux[i];
				i++;
			} else if (less(aux[j], aux[i])) {
				//右半边元素小于左半边元素，取右半边
				a[k] = aux[j];
				j++;
			} else {
				//左半边元素小于右半边元素，取左半边
				a[k] = aux[i];
				i++;
			}
		}
	}
}
```

有了这个归并方法，下面开始实现归并排序。

## 2. 自顶向下的归并排序
### 2.1 算法实现
下面的代码采用分治思想，通过递归实现两个子数组排序，并通过归并两个子数组完成整个数组的排序。

```java
public class Merge extends AbstractMerge {

	@Override
	public void sort(Comparable[] a) {
		aux = new Comparable[a.length];
		sort(a, 0, a.length - 1);
	}

	private void sort(Comparable[] a, int lo, int hi) {
		if (hi <= lo) return;
		
		int mid = lo + (hi - lo) / 2;
		//将左边排序
		sort(a, lo, mid);
		//将右边排序
		sort(a, mid + 1, hi);
		//归并结果
		merge(a, lo, mid, hi);
	}
}
```

性能：对于长度为N的任意数组，自顶向下的归并排序需要(1/2)NlgN至NlogN次比较。最多需要访问数组6NlgN次。将初级排序算法中的测试数组改为100万个随机整数，Shell排序耗时1217ms，而自顶向下的归并排序算法耗时为611ms。

### 2.2 算法优化
上述的归并算法还有优化的空间。例如对于小规模的子数组（如长度小于15），改用插入排序，一般可以将运行时间缩短10%~15%。

还可以添加一个判断条件，如果a[mid]小于等于a[mid+1]，就认为数组已经是有序的并跳过merge()方法。

另一种优化是不将元素复制到辅助数组，节省元素复制到辅助所用的时间（但空间不行）。实现这一点要调用两种排序方法，一种将数据从输入数组排序到辅助数组，一种将数据从辅助数组排序到输入数组。在递归调用的每个层次交换输入数组和辅助数组的角色。

实现上述三种优化的MergeX如下：

```java
public class MergeX {
    private static final int CUTOFF = 7;  // cutoff to insertion sort

    private MergeX() { }

    private static void merge(Comparable[] src, Comparable[] dst, int lo, int mid, int hi) {
        int i = lo, j = mid+1;
        for (int k = lo; k <= hi; k++) {
            if      (i > mid)              dst[k] = src[j++];
            else if (j > hi)               dst[k] = src[i++];
            else if (less(src[j], src[i])) dst[k] = src[j++];   // to ensure stability
            else                           dst[k] = src[i++];
        }
    }

    private static void sort(Comparable[] src, Comparable[] dst, int lo, int hi) {
        if (hi <= lo + CUTOFF) { 
        	//优化1，改用插入排序算法
            insertionSort(dst, lo, hi);
            return;
        }
        int mid = lo + (hi - lo) / 2;
        sort(dst, src, lo, mid);
        sort(dst, src, mid+1, hi);

        // if (!less(src[mid+1], src[mid])) {
        //    for (int i = lo; i <= hi; i++) dst[i] = src[i];
        //    return;
        // }

        // using System.arraycopy() is a bit faster than the above loop
        if (!less(src[mid+1], src[mid])) {
        	//优化2，跳过merge
            System.arraycopy(src, lo, dst, lo, hi - lo + 1);
            return;
        }

        merge(src, dst, lo, mid, hi);
    }

    public static void sort(Comparable[] a) {
        Comparable[] aux = a.clone();
        sort(aux, a, 0, a.length-1);  
    }

    private static void insertionSort(Comparable[] a, int lo, int hi) {
        for (int i = lo; i <= hi; i++)
            for (int j = i; j > lo && less(a[j], a[j-1]); j--)
                exch(a, j, j-1);
    }

    private static void exch(Comparable[] a, int i, int j) {
        Comparable swap = a[i];
        a[i] = a[j];
        a[j] = swap;
    }

    private static boolean less(Comparable a, Comparable b) {
        return (a.compareTo(b) < 0);
    }

    private static boolean isSorted(Comparable[] a) {
        return isSorted(a, 0, a.length - 1);
    }

    private static boolean isSorted(Comparable[] a, int lo, int hi) {
        for (int i = lo + 1; i <= hi; i++)
            if (less(a[i], a[i-1])) return false;
        return true;
    }

    public static void main(String[] args) {
    	//测试100万个随机整数的排序
    	int len = 1000000;
    	Integer[] array = new Integer[len];
		Random random = new java.util.Random();
		for(int i = 0; i < len; i++) {
			array[i] =  random.nextInt(1000000);
		}
    	
		long from = System.nanoTime();
        MergeX.sort(array);
        System.out.format("Merge sort, totoalTime: %dms \n", (System.nanoTime() - from) / 1000000);
        MergeX.isSorted(array);
    }
}

//output: MergeX sort, totoalTime: 361ms，比Merge的611ms又进步不少。 
```

### 3. 自底向上的归并排序
自顶向下的归并排序，在排序过程中，会先递归排序完左边，然后再递归排序右边，最后再归并到一起。而自底向上的归并排序，则是另一种思路。

它的思路是先归并微型数组，然后再归并得到的子数组，如此这般，直到将整个数组归并在一起。具体来说，就是两两归并（每个元素是大小为1的数组），然后四四归并（两个大小为2的数组）、八八归并。。。代码实现如下：

```java
public class MergeBU extends AbstractMerge {
	@Override
	public void sort(Comparable[] a) {
		int N = a.length;
		aux = new Comparable[N];
		for(int sz = 1; sz < N; sz = sz + sz) {
			for(int lo = 0; lo < N - sz; lo += sz + sz) {
				merge(a, lo, lo + sz - 1, Math.min(lo + sz + sz - 1, N - 1));
			}
		}
	}
}
```

性能：自底向上和自顶向上的归并排序所用的比较次数、数组访问次数正好相同，只是顺序不同。测试耗时：536ms 

自底向上的归并排序比较适合用链表组织的数据。想象一下将链表先按大小为1的子链表进行排序，然后是大小为2的子链表。。。这种方法只需要重新组织链表链接，就能将链表原地排序。

在最坏的情况下，没有任何基于比较的排序算法能够将比较次数做到小于NlgN。也就是说，在最坏的情况下，归并排序算法的比较次数是最小的算法之一。