---
layout: post
title: "字符串排序"
date: 2014-11-15 09:49:02 +0800
comments: true
categories: 
- 算法
---
字符串是最常用的数据类型，因此它的排序算法非常重要。虽然Java的字符串排序已经非常快，但了解一些字符串的排序算法仍然很必要，也是进一步了解字符串其它应用的基础。

<!--more-->

在Java中表示字符串的两种方法：

操作 | 字符数组 | Java字符串
---|---|---
声明| char[] a| String s
根据索引访问字符| a[i] | s.charAt(i)
获取字符串长度| a.length | s.length()
表示方法转换| a = s.toCharArray(); | s= new String(a);

## 1. 字母表
字母表是字符串相关算法的基础，表示字符串由哪些字母组成。字符索引的数组能够提高算法的效率。在这个数组中，用字符作为索引来获取与之相关联的信息。在一些算法中会产生大量的这类数组。如果使用Java的String类，就必须使用大小为65536的数组。有了字母表，则只需要使用一个字母表大小的数组即可。

字母表(Alphabet)API定义如下：

方法 |  说明
---|---
Alphabet(String s) | 构造方法，根据s中的字符创建一张新的字母表
char toChar(int index) | 获取字母表中索引位置的字符
int toIndex(char c)  | 获取c的索引，在0到R-1之间
boolean contains(char c) | c在字母表中吗
int R() | 基数（字母表中的字符数量）
int lgR() | 表示一个索引所需的比特数
int[] toIndices(String s) | 将s转换为R进制的整数数组
String toChars(int[] indices) | 将R进制的整数数组转换为基于该字母表的字符串

### 标准字母表

名称 | R() | lgR() | 字符集
---|---|---|---
BINARY | 2 | 1 | 01
DNA | 4 | 2 | ACTG
OCTAL | 8 | 3 | 0..7
DECIMAL | 10 | 4 | 0..9
HEXADECIMAL | 16 | 4 | 0..9ABCDEF
PROTEIN | 20 | 5 | ACDEFGHIKLMNPQRSTVWY
LOWERCASE | 26 | 5 | a..z
UPPERCASE | 26 | 5 | A..Z
BASE64 | 64 | 6 | A..Za..z0..9+/
ASCII | 128 | 7 | ASCII字符集
EXTENDED_ASCII | 256 | 8 | 扩展ASCII字符集
UNICODE16 | 65536 | 16 | Unicode字符集

## 2. 键索引计数法
假设老师在统计学生分数时，学生被分为若干组，标号为0、1、2、3等。老师希望将全班同学按组分类，也就是按组排序。因为组的编号是较小的整数，使用键索引计数法来排序非常合适。

我们用一个数组a[]来保存数据。每个元素都保存了一个姓名和一个组号。组号在0到R-1之间，a[i].key()会返回指定学生的组号。键索引计数法通过四个步骤来完成排序。

**第一步，频率统计**
使用一个int数组count[]来计算每个键（组号）出现的频率。遍历一遍数组，如果键为r，则将count[r+1]加1。因此对第1组的学生，将会把count[2]++。（在第二步的代码中可以看到为什么是r+1）

```java
for (int i = 0; i < N; i++) {
	count[a[i].key() + 1]++;
}
```

**第二步，将频率转换为索引**
有了count[]中每个键出现的次数，就可以得到每个键在排序结果中的起始索引位置。假如第1组3个人，第2组5个人，那么第三种的同学在排序结果中的起始位置就是8. 因此可以将count[]转化为一张索引表。

```java
for (int r= 0; r < R; r++) {
	count[r+1] += count[r];
}
```

**第三步，数据分类**
在第二步中，得到了每个键的起始序号。我们就可以将所有元素（学生）移动到一个辅助数组aux[]。元素在aux[]中的位置由count[]值决定，在移动的过程中将count[]中对应的元素值加1。这个过程只需要遍历一遍数据就可以产生排序结果。并且这种方式是稳定的！键相同的元素在排序后会被聚集到一起，而且相对顺序没有变化。

```java
for (int i = 0; i < N; i++) {
	aux[count[a[i].key()]++]  = a[i];
}
```

**第四步，回写**
在第三步已经完成了排序，只需要将排序结果复制回原数组。

```java
for(int i = 0; i < N; i++) {
	a[i] = aux[i];
}
```

键索引计数法是一种对于小整数键排序非常有效却常常被忽略的排序方法。它排序N个键为0到R-1之间的整数的元素需要访问数组11N+4R+1次。也就是说**它突破了NlogN的排序算法运行时间下限（[快速排序算法](/blog/2014/09/27/kuai-su-pai-xu-suan-fa/)）。原因是什么？因为它是不需要比较的，它只通过key()方法访问数据。只要当R在N的一个常数因子范围之内，它都是一个线性时间级别的排序方法。**

理解键索引计数法的工作原理非常重要。学生的组号对应字母表中的元素，利用字母表大小的数组count[]来统计每个字母出现的次数，计算出每个字母在最终数组的起始序号，从而完成排序。

有了键索引计数法，我们来看如何实现两种字符串排序算法。

## 3. 低位优先(Least-Significant-DigitFirst, LSD)的字符串排序
这种算法适用于**键的长度相等**的字符串排序应用。例如对车牌号进行排序。它会从右往左检查键中的字符，所以称为低位优先。

如果字符串的长度均为W，在排序的过程中，从右向左，将每个位置的字符作为键，用键索引计数法将字符串排序W遍。理解了键索引计数法，实现低位优先的字符串排序就很容易了：

```java
public class LSD {
    public static void sort(String[] a, int W) {
        int N = a.length;
        int R = 256;   // extend ASCII alphabet size
        String[] aux = new String[N];

        for (int d = W-1; d >= 0; d--) {
            //将第d个字符用键索引计数法排序
            // 计算出现次数
            int[] count = new int[R+1];
            for (int i = 0; i < N; i++)
                count[a[i].charAt(d) + 1]++;

            // 将次数转换为索引
            for (int r = 0; r < R; r++)
                count[r+1] += count[r];

            // 移到辅助数组，进行排序
            for (int i = 0; i < N; i++)
                aux[count[a[i].charAt(d)]++] = a[i];

            // 回写数据
            for (int i = 0; i < N; i++)
                a[i] = aux[i];
        }
    }
}
```

低位优先的字符串排序算法能够将定长字符串排序，其中的键索引计数法的稳定性起了关键作用。

对于基于R个字符的字母表的N个以长为W的字符串为键的元素，低位优先的字符串排序需要访问~7WN+3WR次数组，使用的额外空间与N+R成正比。

## 4. 高位优先(MSD)的字符串排序
这种算法从左往右检查键中的字符，所以称为高位优先。它不一定要检查所有的输入才能完成排序。它是更通用的字符串排序算法，字符串的长度不一定相同。

和快速排序一样，高位优先的字符串排序会将数组切分为能够独立排序的子数组来完成排序任务，但它的切分会为每个首字母得到一个子数组，而不是像快速排序中那样产生固定的两个或三个切分。首先用键索引计数法将所有字符串按照首字母排序，然后（递归地）再将每个首字母所对应的子数组排序（忽略首字母，因为每个子数组中的首字母是相同的）。

由于高位优先字符串排序算法要处理不等长的字符串，因此要处理字符串已经结束的情况。因此约定charAt方法中，如果指定位置超出字符串长度则返回-1. 其它情况则加1后返回。因此字符串中的每个字符都可能产生R+1种不同的值，0表示结束，1表示字母表的第一个字符。而键索引计数法还需要一个额外的位置，所以count[]的长度应为R+2。

对于很小的子数组（15个以内），采用插入排序更快。

```java
public class MSD {
    private static final int R             = 256;   // 基数 extended ASCII alphabet size
    private static final int CUTOFF        =  15;   // 小数组的切换阈值 cutoff to insertion sort

    // sort array of strings
    public static void sort(String[] a) {
        int N = a.length;
        String[] aux = new String[N];
        sort(a, 0, N-1, 0, aux);
    }

    // return dth character of s, -1 if d = length of string
    private static int charAt(String s, int d) {
        assert d >= 0 && d <= s.length();
        if (d == s.length()) return -1;
        return s.charAt(d);
    }

    // sort from a[lo] to a[hi], starting at the dth character
    private static void sort(String[] a, int lo, int hi, int d, String[] aux) {

        // cutoff to insertion sort for small subarrays
        if (hi <= lo + CUTOFF) {
            insertion(a, lo, hi, d);
            return;
        }

        // 计算次数
        int[] count = new int[R+2];
        for (int i = lo; i <= hi; i++) {
            int c = charAt(a[i], d);
            count[c+2]++;
        }

        // 将次数转换为索引
        for (int r = 0; r < R+1; r++)
            count[r+1] += count[r];

        // 生成辅助数据内容，完成排序。
        for (int i = lo; i <= hi; i++) {
            int c = charAt(a[i], d);
            aux[count[c+1]++] = a[i];
        }

        // 回写
        for (int i = lo; i <= hi; i++) 
            a[i] = aux[i - lo];


        // 递归地以每个字符为键进行排序。
        for (int r = 0; r < R; r++)
            sort(a, lo + count[r], lo + count[r+1] - 1, d+1, aux);
    }


    // 插入排序算法insertion sort a[lo..hi], starting at dth character
    private static void insertion(String[] a, int lo, int hi, int d) {
        for (int i = lo; i <= hi; i++)
            for (int j = i; j > lo && less(a[j], a[j-1], d); j--)
                exch(a, j, j-1);
    }

    // exchange a[i] and a[j]
    private static void exch(String[] a, int i, int j) {
        String temp = a[i];
        a[i] = a[j];
        a[j] = temp;
    }

    // is v less than w, starting at character d
    private static boolean less(String v, String w, int d) {
        // assert v.substring(0, d).equals(w.substring(0, d));
        for (int i = d; i < Math.min(v.length(), w.length()); i++) {
            if (v.charAt(i) < w.charAt(i)) return true;
            if (v.charAt(i) > w.charAt(i)) return false;
        }
        return v.length() < w.length();
    }
}
```

### 4.1 三个必须解决的问题

#### 4.1.1 小型子数组
高位优先的字符串排序算法能够快速地将需要排序的数组切分小的数组，但这肯定会需要处理大量的微型数组，因此必须快速处理它们。**小型子数组对于高位优先的字符串排序性能至关重要！**假设要将数百万个不同的ASCII字符串排序，每个字符串最终都会产生一个只含有它自己的子数组，因此你需要将数百万个大小为1的子数组排序。每次排序还需要将count[]r 258个元素初始化为0并转化为索引。这个代价比排序其他部分高得多。如果使用Unicode(R=65536)则可能会慢上千倍！

所以对小型子数组要切换到插入排序。在一个典型应用中，当长度小于等于10时切换到插入排序能够将运行时间降低到原来的十分之一。

#### 4.1.2 等值键
如果字符串有大量重复的前缀，排序会较慢。高位优先字符串排序算法的最坏情况就是所有的键均相同。

#### 4.1.3 额外空间
为了进行切分，高位优先的算法使用了两个辅助数组：aux[]和count[]. aux可以在递归方法sort()外创建。而count[]所需的空间是主要问题，它在内循环中创建。

解决这三个问题需要新算法。

## 5. 三向字符串快速排序
在高位优先的字符串排序算法上改进快速排序。根据键的首字母进行三向切分，分成三个数组：首字母小于、等于和大于切分字符的三个数组。仅在中间子数组中的下一个字符（因为首字母就是切分字符）继续递归排序。这是一种将高位优先字符串排序与快速排序结合的算法。

这种算法不会像高位优先算法那样创建大量（空）子数组，它的切分总是只有三个。能解决所有高位优先字符串排序算法不擅长的各种情况。并且它也不需要额外的空间。

对于所有递归算法都可以通过对小型子数组进行特殊处理高效率，所以它同样使用到了插入排序。

和快速排序一样，最好在排序之前将数组打乱，或者将第一个元素和一个随机位置的元素交换以得到一个随机的切分元素。这么做主要是预防数组已经有序或者接近有序的最坏情况。

```java
public class Quick3string {
    private static final int CUTOFF =  15;   // cutoff to insertion sort

    // sort the array a[] of strings
    public static void sort(String[] a) {
        StdRandom.shuffle(a);
        sort(a, 0, a.length-1, 0);
        assert isSorted(a);
    }

    // return the dth character of s, -1 if d = length of s
    private static int charAt(String s, int d) { 
        assert d >= 0 && d <= s.length();
        if (d == s.length()) return -1;
        return s.charAt(d);
    }


    // 3-way string quicksort a[lo..hi] starting at dth character
    private static void sort(String[] a, int lo, int hi, int d) { 

        // cutoff to insertion sort for small subarrays
        if (hi <= lo + CUTOFF) {
            insertion(a, lo, hi, d);
            return;
        }

        int lt = lo, gt = hi;
        int v = charAt(a[lo], d);
        int i = lo + 1;
        while (i <= gt) {
            int t = charAt(a[i], d);
            if      (t < v) exch(a, lt++, i++);
            else if (t > v) exch(a, i, gt--);
            else              i++;
        }

        // a[lo..lt-1] < v = a[lt..gt] < a[gt+1..hi]. 
        sort(a, lo, lt-1, d);
        if (v >= 0) sort(a, lt, gt, d+1);
        sort(a, gt+1, hi, d);
    }

    // sort from a[lo] to a[hi], starting at the dth character
    private static void insertion(String[] a, int lo, int hi, int d) {
        for (int i = lo; i <= hi; i++)
            for (int j = i; j > lo && less(a[j], a[j-1], d); j--)
                exch(a, j, j-1);
    }

    // exchange a[i] and a[j]
    private static void exch(String[] a, int i, int j) {
        String temp = a[i];
        a[i] = a[j];
        a[j] = temp;
    }

    // is v less than w, starting at character d
    // DEPRECATED BECAUSE OF SLOW SUBSTRING EXTRACTION IN JAVA 7
    // private static boolean less(String v, String w, int d) {
    //    assert v.substring(0, d).equals(w.substring(0, d));
    //    return v.substring(d).compareTo(w.substring(d)) < 0; 
    // }

    // is v less than w, starting at character d
    private static boolean less(String v, String w, int d) {
        assert v.substring(0, d).equals(w.substring(0, d));
        for (int i = d; i < Math.min(v.length(), w.length()); i++) {
            if (v.charAt(i) < w.charAt(i)) return true;
            if (v.charAt(i) > w.charAt(i)) return false;
        }
        return v.length() < w.length();
    }

    // is the array sorted
    private static boolean isSorted(String[] a) {
        for (int i = 1; i < a.length; i++)
            if (a[i].compareTo(a[i-1]) < 0) return false;
        return true;
    }
}
```

要将含有N个随机字符串的数组排序，三向字符串快速排序平均需要比较字符~2NlnN次。

Java系统的标准实现中的字符串比较非常快，因此它的排序性能与上面的算法不相上下。

![image](/myresource/images/image_blog_2014-11-15-string-sort.jpg)



参考：[http://algs4.cs.princeton.edu/51radix/](http://algs4.cs.princeton.edu/51radix/)