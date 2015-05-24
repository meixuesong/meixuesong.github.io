---
layout: post
title: "快速排序算法"
date: 2014-09-27 10:38:32 +0800
comments: true
toc: true
categories:
- 算法 
---
快速排序可能是应用最广泛的算法，原因是它实现简单、速度快。它完美地实现了原地排序（只需要一个很小的辅助栈），并且时间与NlgN成正比。它的内循环比大多数排序算法都要短小，因此理论上要更快。但它的主要缺点是非常脆弱，实现时要非常小心才能避免低劣的性能。

<!--more-->
## 1. 算法理论
快速算法也是一种分治的排序算法，它将一个数组分成两个子数组，将两部份独立地排序。但与归并排序将两个子数组分别排序再归并到整个数组排序不同，快速排序时，当两个子数组都有序时整个数组也就自然有序了。

快速排序算法的关键是切分，通过切分使数组满足下面三个条件：

1. 对于某个j, a[j]已经排定;
2. a[lo]到a[j-1]中的所有元素都不大于a[j];
3. a[j+1]到a[hi]中的所有元素都不小于a[j];

因为切分过程总能排定一个元素，因此递归调用切分过程就能够正确地将数组排序。切分实现方法如下：先随意取a[lo]作为切分元素，然后从数组的左端开始向右扫描直到找到一个大于等于它的元素，再从数组右端向左扫描直到找到一个小于等于它的元素，交换它俩的位置。如此继续，当两个指针相遇时，只需要将切分元素和左子数组最右侧的元素a[j]交换然后返回j即可。j即满足上述三个条件。

## 2. 算法实现
下面是排序算法的实现。需要注意的是还有几个细节需要完善，它们可能导致错误或影响性能。

```java
public class Quick extends AbstractSort {
	@Override
	public void sort(Comparable[] a) {
		StdRandom.shuffle(a); //打乱数组，消除对输入的依赖
		sort(a, 0, a.length - 1);
	}
	
	private static void sort(Comparable[] a, int lo, int hi) {
		if (hi <= lo) return;
		
		int j = partition(a, lo, hi);
		sort(a, lo, j - 1);
		sort(a, j + 1, hi);
	}
	
	private static int partition(Comparable[] a, int lo, int hi) {
		//i, j分别代表左右扫描指针
		int i = lo, j = hi + 1;
		Comparable v = a[lo]; //选择切分元素
		
		while(true) {
			//从左往右扫描
			while (less(a[++i], v)) {
				if (i == hi) break; //冗余，可以去除。
			}
			
			//从右往左扫描
			while (less(v, a[--j])) {
				if (j == lo) break; //冗余，可以去除。
			}
			
			//检查两指针是否相遇
			if (i >= j) break; 
			
			exchange(a, i, j);
		}
		
		//与切分元素交换
		exchange(a, lo, j);
	
		//现在满足：a[lo .. j-1] <= a[j] <= a[j+1 .. hi]
		return j;
	}
}
//对一百万个随机整数排序，时间大致在350ms，但加上shuffle后，时间在600多ms.
```

## 3. 性能特点
快速排序算法的内循环用一个递增的索引将数组元素和一个定值比较，因此内循环非常短。归并和希尔排序需要在内循环中移动数据，所以它们通常比快速排序要慢一些。

快速排序算法的另一个优势是比较的次数很少。其效率最终还是依赖切分数组的效果。最好的情况下，每次都正好能将数组对半分。尽管事情并不总会这么顺利，但平均而言切分元素都能落在数组的中间。如果将切分位置的概率考虑到算法中，将使递归更复杂，而结果还是类似的。

它有一个潜在的缺点，切分不平衡时效率会相当低效。例如第一次从最小的元素切分，第二次从第二小的元素切分。。。这样每次调用只会移除一个元素。这也是快速排序前先随机排序(shuffle)的主要原因。

## 4. 算法改进
如果排序代码会执行很多次或者将用在大型数组上，那么就需要进行一些改进。

### 4.1 切换到插入排序
由于小数组的快速排序比插入排序慢，并且小数组时的递归调用也会消耗资源，因此在排序小数组时应该切换到插入排序。

可以在sort方法中，将`if (hi <= lo) return;`替换为：`if (hi <= lo + M) {Insertion.sort(a, lo, hi); return;}`。M的最佳值和系统相关，但一般在5~15之间在大多数情况下都能令人满意。

### 4.2 三取样切分
第二个改进的方法是使用子数组的一小部分元素的中位数来切分数组。人们发现将取样大小设为3并用大小居中的元素切分效果最好。

### 4.3 熵最优的排序
对于有大量重复元素的数组，快速排序算法仍然会递归调用，而三向切分的快速排序算法可以更好地处理这种情况。

```
public class Quick3way extends AbstractSort {
	@Override
	public void sort(Comparable[] a) {
		StdRandom.shuffle(a); //打乱数组，消除对输入的依赖
		sort(a, 0, a.length - 1);
	}
	
	private static void sort(Comparable[] a, int lo, int hi) {
		if (hi <= lo) return;
		
		int lt = lo, i = lo + 1, gt = hi;
		Comparable v = a[lo];
		while (i <= gt) {
			int cmp = a[i].compareTo(v);
			if (cmp < 0) {
				exchange(a, lt++, i++);
			} else if (cmp > 0) {
				exchange(a, i, gt--);
			} else {
				i++;
			}
		}//现在a[lo..lt-1] < v = a[lt..gt] < a[gt+1..hi]
		
		sort(a, lo, lt - 1);
		sort(a, gt + 1, hi);
	}
}

//（不含shuffle的时间）对于一百万随机整数，排序时间也在350ms左右。但如果存在大量重复时，时间将降到250ms左右。
```

对有大量重复元素的数组排序时，三向切分算法具有更高的效率。而在最差的情况下，也就是没有重复元素时，它的效率与标准快速排序算法相当。因此，三向切分的快速排序成为排序函数的最佳算法选择。

在基于比较的排序算法中，经过精心调优的快速排序算法性能最好。但它不是终点，还有完全不需要比较的排序算法！
