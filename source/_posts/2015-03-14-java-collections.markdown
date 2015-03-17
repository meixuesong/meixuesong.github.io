---
layout: post
title: "Java Collections"
date: 2015-03-14 20:51:05 +0800
comments: true
categories: 
- java
---
Java提供了一套完整的Collection框架，能够帮助我们减少开发工作量、提高程序运行速度和代码质量。本文学习Java Collection框架。

<!--more-->
## 1. 接口层级结构
核心Collection接口封装了各种类型的集合，它是Java Collections框架的基石。接口继承层次如下图所示：

![image](/myresource/images/image_blog_2015-03-14-colls-coreInterfaces.png)

注意，从上图可以看出，Map并不是真正的Collection。所有核心Collection接口都支持泛型。在声明Collection实例时，你可以也应该指明集合的元素类型，让编译器帮你校验放入集合的元素类型是否匹配，从而降低运行时错误。

类结构图

![image](/myresource/images/image_blog_2015-03-14-colls-classdiagram.jpg)

## 2. Collection接口
Collection类都有很方便的构造器。例如你有一个`Collection<String> c`，它可能是一个List、Set或其它Collection类型。通过构造方法可以转换成另一种Collection：

```java
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

```java
myShapesCollection.stream()
	.filter(e -> e.getColor() == Color.RED)
	.forEach(e -> System.out.println(e.getName()));
```

对多核系统，还可以请求并行流，这对超大Collection有帮助：

```java
myShapesCollection.parallelStream()
	.filter(e -> e.getColor() == Color.RED)
	.forEach(e -> System.out.println(e.getName()));
```

更多例子：

```java
//将Collection中的元素转换成一个String，用逗号分隔：
String joined = elements.stream()
    .map(Object::toString)
    .collect(Collectors.joining(", "));
//计算合计
int total = employees.stream()
	.collect(Collectors.summingInt(Employee::getSalary)));
```

#### 2.1.2 for-each

```java
for (Object o : collection)
    System.out.println(o);
```

#### 2.1.3 Iterator

```java
public interface Iterator<E> {
    boolean hasNext();
    E next();
    void remove(); //optional
}
```

注意remove方法删除最后一次next()方法返回的对象。因此，每调用一次remove方法之前都必须调用next方法，否则会抛出异常。remove方法也是迭代过程中唯一安全的修改Collection的方法。以下场景需要使用Iterator而不是for-each:

* 删除当前元素
* 并行遍历多个Collection

下面的代码演示了如何使用Iterator过滤Collection:

```java
static void filter(Collection<?> c) {
    for (Iterator<?> it = c.iterator(); it.hasNext(); )
        if (!cond(it.next()))
            it.remove();
}
```

### 2.2 Collection批量操作
Collection批量操作的方法大部分返回值都是boolean，如果Collection有变化则返回true: 

* `boolean containsAll(Collection<?> c)`
* `boolean addAll(Collection<? extends E> c)`
* `boolean removeAll(Collection<?> c)`
* `boolean retainAll(Collection<?> c)`（取交集）
* `void clear()`.

Collections.singleton(T o)用于创建包含一个元素“o”的Set，类似的方法还包括：`List<T> singletonList(T o)`， `<K,V> Map<K,V> singletonMap(K key, V value)`。示例：

```
//移除某个元素的所有实例
c.removeAll(Collections.singleton(e));
//移除所有null
c.removeAll(Collections.singleton(null));
```

### 2.3 Collections工具类
除了singleton方法，Collections工具类还有一些常用的方法，如：

* `unmodifiableXXX()`返回一个只读视图。(xxx可能是Collection, List, Map, Set, SortedMap, SortedSet)
* `synchronizedXXX()`返回一个同步（线程安全）的Collection。
* `sort(List<T> list, Comparator<? super T> c)`方法
* `shuffle`方法（打乱顺序）
* `min/max` 可传Comparator
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

对于HashSet，需要注意的是遍历性能与entry数量和bucket数量(容量)之和成线性关系。如果初始容量太大，则浪费空间和时间；反过来，如果初始容量太小则浪费增容时的复制时间。如果不指定初始容量，默认值为16. 过去通过指定一个初始容量能提高性能，但现在已经没必要了。LinkedHashSet的迭代时间与容量没有关系。

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
              " distinct words: " + distinctWords);
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
Set的批量操作并没有什么特殊的方法，但是利用Set元素不会重复这个特性，可以做一些有意思的事情。例如修改FindDups，找到不重复的单词和重复的单词：

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
HashSet通过hash table（实际上就是一个HashMap实例）实现。允许null元素。基本方法（如add, remove, contains, size）为常量时间，而遍历性能则与元素数量加桶数量之和成正比。因此，如果迭代性能要求高的话，不要将初始容量设置得太大。

### 3.4 TreeSet
TreeSet是基于TreeMap的NavigableSet实现。元素按natural ordering或Comparator排序。注意要正确地实现Set接口，就应该让Comparable与equals接口实现保持一致。因为Set不重复由equals决定，而顺序由Comparable决定。TreeSet提供降序或升序视图，但升序一般比降序性能更优。

TreeSet允许null元素，但一些方法的返回值也可能是null（不存在时），这样就会造成混乱。因此建议不要加入null元素。基本操作（add, remove, contains）的时间成本为log(n). TreeSet增加了NavigableSet接口的方法，常用方法如下表：

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

与HashSet一样，有两个参数影响其性能：初始容量和load factor。

### 3.6 EnumSet
EnumSet的所有元素必须是同一个枚举类型的值，不允许null元素。它的效率很高，是替代传统标志位的推荐方案，用long实现。Iterator按自然顺序（枚举中声明的顺序）返回元素。常用方法如下表：

方法| 说明
---|---
`static <E extends Enum<E>> EnumSet<E>	allOf(Class<E> elementType)` | 创建一个包括枚举类型所有值的EnumSet
`EnumSet<E> clone()` | 复制一份。
`static <E extends Enum<E>> EnumSet<E> complementOf(EnumSet<E> s)` | 创建一个同类型的EnumSet，其中的元素为枚举类型所有值减去s中的值。
`static <E extends Enum<E>> EnumSet<E> copyOf(Collection<E> c)` | 创建EnumSet，元素来自c。
`static <E extends Enum<E>> EnumSet<E> noneOf(Class<E> elementType)` | 创建一个空的EnumSet
`static <E extends Enum<E>> EnumSet<E> of(E e, E... rest)` | 创建包括指定元素的EnumSet
`static <E extends Enum<E>> EnumSet<E> range(E from, E to)` | 创建指定元素范围的EnumSet

### 3.7 CopyOnWriteArraySet
CopyOnWriteArraySet内部使用CopyOnWriteArrayList来实现所有操作。因此：

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

## 4. List接口
List接口继承自Collection，它比后者增加了以下类型的方法：

* Positional access 基于位置的访问方法，如get, set, addAll
* Search 搜索指定对象并返回数字索引，如indexOf, lastIndexOf
* Iteration 继承Iterator，增加增了List的特性。ListIterator。
* Rang-View sublist方法提供range相关操作。

Java提供两种普通List实现：ArrayList和LinkedList，前者通常有更好的性能，后者在特定场景有更好性能。如果你需要频繁地在List的起始位置插入元素，或者频繁遍历元素并删除，则使用LinkedList更合适。

另一个特殊的实现是CopyOnWriteArrayList，与CopyOnWriteArraySet类似。无需同步操作，不会有ConcurrentModificationException.

Arrays工具类提供了`asList()`方法，这样可以用List的方式查看数组。但是该操作并不是复制整个数组，对List的修改操作将会影响array，反过来也是如此。因此这个List并不是真正的List，它没有add, remove方法，因为数组不是变长的。如果List是定长的，也没有containsAll之类的bulk操作，可以考虑使用Arrays.asList。

ListIterator提供两个方向迭代的能力，因此多了hasPrevious和previous方法。ListIterator的构造方法有两种格式，默认格式不带参数，表示从头遍历。带int参数的格式表示从指定位置遍历。ListIterator提供了安全的修改方法add, remove和set。它们能够在迭代的过程中安全地修改List的内容。

* add()方法，在List当前位置插入一个对象。所谓当前位置就是：add方法增加对象后，调用previous()方法将返回这个对象。
* remove()方法，将当前元素删除。所谓当前元素就是：如果刚调用了next()或previous()方法，当前元素就是它们返回的元素。注：每调用一次remove()，都需要先调用一次next()或者previous()，如果刚调用了add()，也必须先调用一次next()或者previous()。
* set()方法，更新当前元素。当前元素的定义与remove()方法相同。每次set()之前，也必须调用next()或previous()。

`subList(int fromIndex, int toIndex)`方法提供了range-view操作。由于subList返回的只是List的一个view，因此对返回结果的修改会影响原List。例如下面的代码删除指定范围内的数据：

```
list.subList(fromIndex, toIndex).clear();
```

### 4.1 LinkedList
Doubly-linked列表，实现了List和Deque接口。由于是链表结构，因此基于索引的操作将导致从头遍历。常用的方法：

方法 | 说明
---|---
`void addFirst(E e)` | 在最前面插入
`void addLast(E e)` | 加到最后面
`boolean offer(E e)`, `boolean offerFirst(E e)`, `boolean offerLast(E e)` | 增加操作。默认是加到最后。如果操作成功返回true
`E element()` | 获取但不删除第1个元素
`E getFirst()/getLast()` | 返回第1个/最后一个元素
`E peek()` | 获取但不移除第一个元素
`E peekFirst()/peakLast()` | 获取但不移除第一个/最后一个元素，如果list为空则返回null
`E poll()` | 获取并删除第1个元素, 如果list为空则抛出NoSuchElementException
`E pollFirst()/pollLast()` | 获取并删除第一个/最后一个元素，如果list为空则返回null, 如果list为空则抛出NoSuchElementException
`E pop()` | stack pop
`void push(E e)` | stack push
`boolean remove(Object o)`, `E removeFirst()`, `boolean removeFirstOccurrence(Object o)`, `E removeLast()`, `boolean removeLastOccurrence(Object o)` | 与删除相关的操作，如果list为空则抛出NoSuchElementException

### 4.2 Stack
方法 | 说明
---|---
`boolean empty()` | Tests if this stack is empty.
`E peek()` | Looks at the object at the top of this stack without removing it from the stack.
`E pop()` | Removes the object at the top of this stack and returns that object as the value of this function.
`E push(E item)` | Pushes an item onto the top of this stack.
int search(Object o) | Returns the 1-based position where an object is on this stack

## 5. Queue接口
Queue接口增加了以下方法，它们的返回值有两种类型：抛出异常、返回特殊值：

```
public interface Queue<E> extends Collection<E> {
    E element();
    boolean offer(E e);
    E peek();
    E poll();
    E remove();
}
```

操作类型 | 抛出异常 | 返回特殊值
---|---|---
插入操作 | add(e) | offer(e) 成功返回true
删除操作 | remove() 队列为空时异常 | poll() 队列为空返回null
检查操作 | element() 队列为空时异常 | peek() 队列为空返回null


队列通常是FIFO的行为，但优先队列的顺序取决于它的值。java.util.concurrent下的一些队列有数量限制（bounded），但java.util下的队列没有数量限制。java.util.concurrent.BlockingQueue 继承自Queue，提供了阻塞的机制。

### 5.1 普通队列
LinkedList实现了Queue接口，提供FIFO队列操作add, poll等等。优先队列PriorityQueue的顺序取决于元素的natural ordering或构造方法的Comparator参数。

### 5.2 多线程队列
java.util.concurrent.BlockingQueue继承自Queue，其实现是线程安全的。所有队列方法使用内部锁或其它多线程控制实现原子操作。但是bulk操作，如addAll, containsAll, retainAll, removeAll并没有实现原子操作。例如`addAll(c)`执行时，如果另一线程在c中添加了元素则会导致addAll失败。

BlockingQueue不支持null元素。它可能有数量限制，否则最大为Integer.MAX_VALUE。它的方法有四种模式：

操作类型 |Throws exception | Special value | Blocks | Times out
---|---|---|---
Insert|add(e) | offer(e)| put(e) | offer(e, time, unit)
Remove|remove() | poll() | take() | poll(time, unit)
Examine|element() | peek() | not applicable | not applicable

JDK提供了以下实现：

* LinkedBlockingQueue — an optionally bounded FIFO blocking queue backed by linked nodes
* ArrayBlockingQueue — a bounded FIFO blocking queue backed by an array
* PriorityBlockingQueue — an unbounded blocking priority queue backed by a heap
* DelayQueue — a time-based scheduling queue backed by a heap
* SynchronousQueue — a simple rendezvous mechanism that uses the BlockingQueue interface
* LinkedTransferQueue — an unbounded TransferQueue based on linked nodes


## 6. Deque接口
音（deck），支持从两端插入和删除的队列。它同时包含了Queue和Stack接口方法。ArrayDeque和LinkedList实现了Deque接口。Deque支持FIFO和LIFO。

相关的方法参考LinkedList。LinkedBlockingDeque实现了多线程Deque。

## 7. Map接口
Java提供了三种通用的Map实现：HashMap, TreeMap和LinkedHashMap。它们的行为与HashSet, TreeSet和LinkedHashSet相似。如果你想要有序的Map，能够提供有序的keySet，使用TreeMap；如果想要最优性能，使用HashMap。如果既想要高性能，又想保持插入的顺序，使用LinkedHashSet。

JDK8中引入了相关的聚合操作，示例如下：

```
// Group employees by department
Map<Department, List<Employee>> byDept = employees.stream()
	.collect(Collectors.groupingBy(Employee::getDepartment));

// Compute sum of salaries by department
Map<Department, Integer> totalByDept = employees.stream()
	.collect(Collectors.groupingBy(Employee::getDepartment, Collectors.summingInt(Employee::getSalary)));

// Partition students into passing and failing
Map<Boolean, List<Student>> passingFailing = students.stream()
	.collect(Collectors.partitioningBy(s -> s.getGrade()>= PASS_THRESHOLD)); 

// Classify Person objects by city
Map<String, List<Person>> peopleByCity
	= personStream.collect(Collectors.groupingBy(Person::getCity));

//cascade two collectors to classify people by state 
Map<String, Map<String, List<Person>>> peopleByStateAndCity
	= personStream.collect(Collectors.groupingBy(Person::getState,
  Collectors.groupingBy(Person::getCity)))
```

Map提供了Collecton view，有三种方法：

* keySet 所有key的集合
* values 所有值。这不是一个Set，因为value会有重复。
* entrySet 所有key-value的集合

Map的遍历方法有多种：

```
for (KeyType key : m.keySet())
    System.out.println(key);
    
// Filter a map based on some 
// property of its keys.
for (Iterator<Type> it = m.keySet().iterator(); it.hasNext(); )
    if (it.next().isBogus())
        it.remove();
        
for (Map.Entry<KeyType, ValType> e : m.entrySet())
    System.out.println(e.getKey() + ": " + e.getValue());            
```

不用担心Map创建Collection view的性能。通过Collecton view iterator遍历时，可以调用Iterator的remove方法来删除map中的键值对。利用Map.Entry遍历时也可以调用entry.setValue方法来修改值。Collection view支持remove, removeAll, retainAll, clear, Iterator.remove操作。例如，以下命令会清空所有数据：

```
Set<Integer> set = map.keySet();
set.clear();
```		

Map的Collection view在很多场合能起到便利作用。以下是一些示例：

```
//判断一个Map的key是否包含另一个Map的key
if (m1.entrySet().containsAll(m2.entrySet())) {
    ...
}

//判断两个Map的key是否相同
if (m1.keySet().equals(m2.keySet())) {
    ...
}

//判断两个Map的key交集（注意新建了一个set，避免对Map产生影响）
Set<KeyType>commonKeys = new HashSet<KeyType>(m1.keySet());
commonKeys.retainAll(m2.keySet());
```

### 7.1 LinkedHashMap
LinkedHashMap的顺序通常是插入顺序，同一元素多次重复插入并不会修改它的位置。

LinkedHashMap还提供了一个特殊的构造方法，它创建的LinkedHashMap顺序是entry被访问的顺序。元素的访问时间越近，则它越靠前。因此这种LinkedHashMap非常适合做LRU(least recently used)缓存。构造方法如下：

```
public LinkedHashMap(int initialCapacity,
                     float loadFactor,
                     boolean accessOrder)
```   

影响这种LinkedHashMap元素顺序的访问方法包括：put, putInfoAbsent, get, getOrDefault, compute, computeIfAbsent, computeIfPresent, merge, replace(如果之前存在，替换动作成功)和putAll方法。其中putAll方法会对指定map中的所有元素都产生一次访问，访问的顺序取决于指定map的entryset iterator。除了以上方法外，其他方法都不会影响元素顺序，特别是作用于Collection view的方法也不会对元素顺序产生影响。

覆盖removeEldestEntry(Map.Entry)方法可以在Map移除旧Entry时自定义一些策略。

LinkedHashMap性能接近于HashMap，在遍历时性能比HashMap更优。因为LinkedHashMap的迭代性能只与size相关，而HashMap还与容量相关。

### 7.2 其它Map实现类
除了HashMap, TreeMap和LinkedHashMap, 还有一些其它的Map实现：

* EnumMap与EnumSet类似。
* WeakHashMap 弱引用，便于垃圾收集
* IdentityHashMap 在此Map中，当且仅当k1==k2时，认为两个key是相等的。（HashMap判断相等使用的是equals）很少用。 
* ConcurrentHashMap 高并发、高性能的Map。线程安全。






