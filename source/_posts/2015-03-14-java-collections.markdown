---
layout: post
title: "Java Collections(1)"
date: 2015-03-14 20:51:05 +0800
comments: true
categories: 
- java
---
Java提供了一套完整的Collection框架，能够帮助我们减少开发工作量、提高程序运行速度和代码质量。本文学习Collection接口和Set。

<!--more-->
## 1. 接口层级结构
核心Collection接口封装了各种类型的集合，它是Java Collections框架的基石。接口继承层次如下图所示：

![image](/myresource/images/image_blog_2015-03-14-colls-coreInterfaces.png)

注意，从上图可以看出，Map并不是真正的Collection。所有核心Collection接口都支持泛型。在声明Collection实例时，你可以也应该指明集合的元素类型，让编译器帮你校验放入集合的元素类型是否匹配，从而降低运行时错误。

## 2. Collection接口
Collection类都有一个便利构造器。例如你有一个`Collection<String> c`，它可能是一个List、Set或其它Collection类型。通过构造方法可以转换成另一种Collection：

```
List<String> list = new ArrayList<String>(c);
```

基本的Collection操作包括：

* `int size()`
* `boolean isEmpty()`
* `boolean contains(Object element)`
* `boolean add(E element)`
* `boolean remove(Object element)`
* `Iterator<E> iterator()`

操作整个Collection的相关方法：

* `boolean containsAll(Collection<?> c)`
* `boolean addAll(Collection<? extends E> c)`
* `boolean removeAll(Collection<?> c)`
* `boolean retainAll(Collection<?> c`)（交集，只保留c中存在的元素）
* `void clear()`

此外还有数组的操作：`Object[] toArray()`,  `<T> T[] toArray(T[] a) `

### 2.1 遍历Collection
有三种方法遍历Collection：聚合操作、for-each和Iterator。

#### 2.1.1 聚合操作
JDK8之后，推荐使用聚合操作来遍历Collection。聚合操作常常与lambda表达式一起让代码更具表达力。下面的代码完成遍历并打印红色的对象的name:

```
myShapesCollection.stream()
	.filter(e -> e.getColor() == Color.RED)
	.forEach(e -> System.out.println(e.getName()));
```

对多核系统，还可以请求并行流，这对超大Collection有帮助：

```
myShapesCollection.parallelStream()
	.filter(e -> e.getColor() == Color.RED)
	.forEach(e -> System.out.println(e.getName()));
```

更多例子：

```
//将Collection中的元素转换成一个String，用逗号分隔：
String joined = elements.stream()
    .map(Object::toString)
    .collect(Collectors.joining(", "));
//计算合计
int total = employees.stream()
	.collect(Collectors.summingInt(Employee::getSalary)));
```

#### 2.1.2 for-each

```
for (Object o : collection)
    System.out.println(o);
```

#### 2.1.3 Iterator

```
public interface Iterator<E> {
    boolean hasNext();
    E next();
    void remove(); //optional
}
```

注意remove方法会删除最后一次next()方法返回的对象。因此，每调用一次remove方法之前都必须调用next方法，否则会抛出异常。remove方法也是迭代过程中唯一安全的修改Collection的方法。以下场景需要使用Iterator而不是for-each:

* 删除当前元素
* 并行遍历多个Collection

下面的代码演示了如何使用Iterator过滤任何Collection:

```
static void filter(Collection<?> c) {
    for (Iterator<?> it = c.iterator(); it.hasNext(); )
        if (!cond(it.next()))
            it.remove();
}
```

### 2.2 Collection批量操作
Collection批量操作的方法大部分返回值都是boolean，如果Collection有变化则返回true: `boolean containsAll(Collection<?> c)`, `boolean addAll(Collection<? extends E> c)`, `boolean removeAll(Collection<?> c)`, `boolean retainAll(Collection<?> c)`（取交集）, and `void clear()`.

Collections.singleton(T o)用于创建包含一个元素“o”的Set，类似的方法还包括：`List<T> singletonList(T o)`， `<K,V> Map<K,V> singletonMap(K key, V value)`。示例：

```
//移除某个元素的所有实例
c.removeAll(Collections.singleton(e));
//移除所有null
c.removeAll(Collections.singleton(null));
```

### 2.3 Collections工具类
除了singleton方法，Collections工具类还有一些常用的方法，如：

* unmodifiableXXX()返回一个只读视图。
* synchronizedXXX()返回一个同步（线程安全）的Collection。
* sort(List<T> list, Comparator<? super T> c)方法
* shuffle方法（打乱顺序）
* min/max 可传Comparator
* `copy(List<? super T> dest, List<? extends T> src)` 复制所有元素到另一个List。dest的数量必须大于等于src，操作完成后，src中的所有元素会覆盖dest中相应位置（index）的元素。
* `int frequency(Collection<?> c,Object o)` 返回c中o出现的次数。
* `fill(List<? super T> list, T obj)` 将所有元素替换成obj。

### 2.4 Array操作
Collection提供了toArray()方法，用于转换成数组。示例：

```
Object[] a = c.toArray();
```

如果已知Collection中的元素是字符串类型，如Collection<String> c，则可以直接转换成字符串数组：

```
String[] a = c.toArray(new String[0]);  //0没有意义，只是和new String一起表示是字符串数组。
```


## 3. Set
Set是一种不能包含重复元素的Collection。Set接口只继承了Collection接口的方法，并增加了禁止重复元素的限制，它依赖于equals和hashCode方法的行为。Set包括三种类型：

* HashSet 元素保存在hash表中，高性能，但无法保证迭代顺序。
* TreeSet 元素保存在红黑树中，有序，但比HashSet慢不少。
* LinkedHashSet hash表加linked list实现，顺序为插入顺序。避免HashSet顺序的不确定性，同时性能接近HashSet。

对于HashSet，需要注意的是遍历性能与数量和容量之和成线性关系。如果初始容量太大，则浪费空间和时间；反过来，如果初始容量太小则浪费增容时的复制时间。如果不指定初始容量，默认值为16. 过去通过指定一个初始容量能提高性能，但现在已经没必要了。LinkedHashSet的迭代时间与容量没有关系。

除了上面三种标准Set实现，还有两个特殊的Set实现：EnumSet和CopyOnWriteArraySet.

EnumSet是用于枚举类型的高性能Set实现。所有元素必须是同一种枚举类型。内部采用bit-vector实现，通常是一个long。它支持在指定范围内遍历，也可以替代传统的标志位。示例如下：

```
for (Day d : EnumSet.range(Day.MONDAY, Day.FRIDAY))
    System.out.println(d);
        
EnumSet.of(Style.BOLD, Style.ITALIC)
```

CopyOnWriteArraySet是由copy-on-write数组实现的Set. 所有修改操作，如add, set, remove都会复制一个新的数组拷贝，因此不需要锁。只适合于很少修改、但频繁遍历的Set。

HashSet、TreeSet和LinkedHashSet的实现并不是同步的。因此如果多个线程同时访问一个Set，且有线程会修改Set，就必须进行同步处理，或者使用Collections.synchronizedSet方法对其封装。最好在创建时就完成此操作，以HashSet为例：

```
Set s = Collections.synchronizedSet(new HashSet(...));
```

### 3.1 基本操作

假设你有一个Collection c，下面的代码可以让你方便地去除重复：

```java
Collection<Type> noDups = new HashSet<Type>(c);
//如果要保持原来的顺序，可以：
Collection<Type> noDups = new LinkedHashSet<Type>(c);

//如果是JDK8，你还可以这么玩：
c.stream().collect(Collectors.toSet()); // no duplicates
//另一个例子，将姓名放到一个TreeSet中
Set<String> set = people.stream()
.map(Person::getName)
.collect(Collectors.toCollection(TreeSet::new));
```

方法 | 描述
---|---
int size() | 返回元素数量
boolean isEmpty() | 是否为空
boolean add() | 增加元素，如果之前不存在，返回true
boolean remove() | 删除元素，如果之前存在此元素，返回true
`Iterator<E> iterator()` | 迭代器

JDK8聚合操作与for-each操作示例：

```java
//JDK8
public class FindDups {
    public static void main(String[] args) {
        Set<String> distinctWords = Arrays.asList(args).stream()
		.collect(Collectors.toSet()); 
        System.out.println(distinctWords.size()+ 
                           " distinct words: " + 
                           distinctWords);
    }
}
//for-each
public class FindDups {
    public static void main(String[] args) {
        Set<String> s = new HashSet<String>();
        for (String a : args)
               s.add(a);
               System.out.println(s.size() + " distinct words: " + s);
    }
}
//运行
java FindDups i came i saw i left
//结果：
4 distinct words: [left, came, saw, i]
```

上面的代码使用的是HashSet，所以顺序是乱的。如果你改成TreeSet/LinkedHashSet，则结果变为：

```
//TreeSet
4 distinct words: [came, i, left, saw]
//LinkedHashSet
4 distinct words: [i, came, saw, left]
```

### 3.2 批量操作
Set的指操作并没有什么特殊的方法，但是利用Set元素不会重复这个特性，可以做一些有意思的事情。例如修改FindDups，找到不重复的单词和重复的单词：

```
public class FindDups2 {
    public static void main(String[] args) {
        Set<String> uniques = new HashSet<String>();
        Set<String> dups    = new HashSet<String>();

        for (String a : args)
            if (!uniques.add(a))
                dups.add(a);

        // Destructive set-difference
        uniques.removeAll(dups);

        System.out.println("Unique words:    " + uniques);
        System.out.println("Duplicate words: " + dups);
    }
}

//output:
Unique words:    [left, saw, came]
Duplicate words: [i]
```

### 3.3 HashSet
HashSet通过hash table（实际上就是一个HashMap实例）实现。允许null元素。基本方法（如add, remove, contains, size）为常量时间，而遍历性能则与元素数量加容量之和成正比。因此，如果迭代性能要求高的话，不要将初始容量设置得太大。

### 3.4 TreeSet
TreeSet是基于TreeMap的NavigableSet实现。元素按natural ordering或Comparator排序。注意要正确地实现Set接口，就应该保持Comparable与equals一致。因为Set不重复由equals决定，而顺序由Comparable决定。提供降序或升序视图，但升序一般比降序性能更优。

TreeSet允许null元素，但null与一些方法的返回值（不存在时返回null）可能造成混乱。因此建议不要加入null元素。基本操作（add, remove, contains）的时间成本为log(n). TreeSet增加了的NavigableSet接口的方法，常用方法如下表：

方法 | 说明
---|---
E ceiling(E e) | 返回大于等于e的最小元素，如果没有返回null
E higher(E e) | 返回大于e的最小元素，如果没有返回null
E floor(E e) | 返回小于等于e的最大元素，如果没有返回null
E lower(E e) | 返回小于e的最大元素，如果没有返回null
`Iterator<E>` descendingIterator() | 返回降序迭代器。
`NavigableSet<E>` descendingSet() | 返回降序视图
E first() | 返回第一个（最小的）元素
E last() | 返回最后一个（最大的）元素
`NavigableSet<E>` headSet(E toElement, boolean inclusive) | 返回小于toElement的元素，如果inclusive=true表示返回结果包含toElement。
`NavigableSet<E>` tailSet(E fromElement, boolean inclusive) | 返回大于（等于，如果inclusive=true）的元素。
E pollFirst() | Retrieves and removes the first (lowest) element, or returns null if this set is empty.
E pollLast() | Retrieves and removes the last (highest) element, or returns null if this set is empty.
`NavigableSet<E>` subSet(E fromElement, boolean fromInclusive, E toElement, boolean toInclusive) | 取子集。
Object clone() | 返回TreeSet实例的浅拷贝

### 3.5 LinkedHashSet
LinkedHashSet会保持插入的顺序，但是如果多次添加一个元素，并不会改变元素原来的的位置。允许null元素。

与HashSet一样，有两个参数影响其性能：初始容量和load factor。同样地，它也没有提供更多的方法。

### 3.6 EnumSet
EnumSet的所有元素必须是同一个枚举类型的值，不允许null元素。它的效率很高，是替代传统标志位的推荐方案。Iterator按自然顺序（枚举中声明的顺序）返回元素。常用方法如下表：

方法| 说明
---|---
static `<E extends Enum<E>> EnumSet<E>`	allOf(Class`<E>` elementType) | 创建一个包括枚举类型所有值的EnumSet
EnumSet<E> clone() | 复制一份。
static `<E extends Enum<E>>` `EnumSet<E>` complementOf(`EnumSet<E>` s) | 创建一个同类型的EnumSet，其中的元素为枚举类型所有值减去s中的值。
static `<E extends Enum<E>>` `EnumSet<E>` copyOf(`Collection<E> c`) | 创建EnumSet，元素来自c。
static `<E extends Enum<E>>` `EnumSet<E>` noneOf(`Class<E> elementType`) | 创建一个空的EnumSet
static `<E extends Enum<E>>` `EnumSet<E>` of(E e, E... rest) | 创建包括指定元素的EnumSet
static `<E extends Enum<E>>` `EnumSet<E>` range(E from, E to) | 创建指定元素范围的EnumSet

### 3.7 CopyOnWriteArraySet
内部使用CopyOnWriteArrayList来实现所有操作。因此：

* 最适合那些size小，读操作远多于修改操作，在遍历中需要防止其它线程干扰的场景。
* 它是线程安全的。
* 修改操作成本较高，因为通常要复制整个数组。
* Iterator不支持remove操作。
* 通过iterator遍历很快，不会受其它线程影响，因为它依赖一个在iterator创建时的数组只读镜像。

示例代码：

```
class Handler { void handle(); ... }

 class X {
   private final CopyOnWriteArraySet<Handler> handlers
     = new CopyOnWriteArraySet<Handler>();
   public void addHandler(Handler h) { handlers.add(h); }

   private long internalState;
   private synchronized void changeState() { internalState = ...; }

   public void update() {
     changeState();
     for (Handler handler : handlers)
       handler.handle();
   }
 }
```





