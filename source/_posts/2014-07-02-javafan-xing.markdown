---
layout: post
title: "Java泛型"
date: 2014-07-02 22:24:37 +0800
comments: true
categories: 
- Java

---

Java泛型功能强大，用起来也很简单。看到一些代码，有时候用?号，有时候又可以直接使用`<T>`，都有哪些区别呢？系统地了解一下吧。

<!--more-->

##1.参数化类型

参数化类型，也就是泛型。

```java
List<String> list = new ArrayList<String>();

Map<String, Date> map = new HaspMap<String, Date>();
```

上面这些都是很常见的用法。或者我们创建一个参数化的类型：

```java
public class MultiHashMap<K, V> {
	private Map<K, List<V>> map = new HashMap<>();  //Java 7中可以省略类型了。	
	public void put(K key, V value) {
		List<V> values = map.get(key);
		...
	}
}
```

##2.擦拭法

要实现参数化类型，有多种方法。C++采用的方法是为每种参数化类都创建一个全新的类型定义。例如`MultiHashMap<Date, String>`将会创建一个新类：

```java
//注：这不是Java的做法。
public class MultiHashMap<Date, String> {
	...
}

```

但这不是Java的做法。Java使用一种叫做“擦拭法”的方法。每个类型参数缺省使用顶级类如Object，客户端的绑定信息被擦去。例如MultiHashMap会被翻译成：

```java
public class MultiHashMap {
	private Map map = new HashMap();
	
	public void put(K key, V value) {
		List values = (List)map.get(key);
		...
	}
}	
```

这个上限也可以指定，例如：

```java
public class EventMap<K extends java.util.Date, V> {

}
```

表示K必须是Date或者其子类。

##3.通配符

假设你有个方法想对某种类型的List进行遍历处理：

```java
    public static String concatenate(List<Object> list) {
    	
    ｝   
```

一旦你如上面一样定义了`List<Object>`参数，则无法将其它类型的列表传入。例如将`List<String>`类型作为参数传入将导致无法编译。这时候你可以使用通配符：

```java
    public static String concatenate(List<?> list) {
    	//遍历时就可以使用Object了。
    	for(Object item : list) {
    		...
    	}
    ｝
```

但通配符也隐含了一些问题。例如，下面的代码编译错误：

```java
public static void pad(List<?> list, Object object, int count) {
	for (int i = 0; i < count; i ++) {
		list.add(object);
	}
}
```

错误的原因是`List<?>`指示了一个未知的类型，编译器无法判断指定的操作是否安全，因此它就全部禁止了。

> `List<?>`声明了List中包含的元素类型是未知的。通配符所代表的其实是一组类型，但具体的类型是未知的。`List<?>`所声明的就是所有类型都是可以的。但是`List<?>`并不等同于`List<Object>`。`List<Object>`实际上确定了List中包含的是Object及其子类，在使用的时候都可以通过Object来进行引用。而`List<?>`则其中所包含的元素类型是不确定。其中可能包含的是String，也可能是 Integer。如果它包含了String的话，往里面添加Integer类型的元素就是错误的。正因为类型未知，就不能通过`new ArrayList<?>()`的方法来创建一个新的ArrayList对象。因为编译器无法知道具体的类型是什么。

那么应该如何解决这个问题呢？可以使用泛型方法：

```java
public class SomeClass {
    public static <T> void pad(List<T> list, T object, int count) {
        for(int i = 0; i < count; i++) {
            list.add(object);
        }
    }

    public static void main(String[] args) {
        List<String> list = new ArrayList<String>();
        pad(list, "Hello", 5);

        System.out.println(list);
    }
}

//结果为：
[Hello, Hello, Hello, Hello, Hello]
```

再来个例子，将通配符与泛型方法结合起来用，将一个List从头至尾交换一遍：

```java
    static void inPlaceReverse(List<?> list) {
        int len = list.size();
        for(int i = 0; i < len; i++) {
            swap(list, i, len - 1 - i);
        }
    }
    
    private static <T> void swap(List<T> list, int i, int opposite) {
        T temp = list.get(i);
        list.set(i, list.get(opposite));
        list.set(opposite, temp);
    }
```

**通配符的上、下界**，super和extends

因为对于`List<?>`中的元素只能用Object来引用，在有些情况下不是很方便。在这些情况下，可以使用上下界来限制未知类型的范围。 如`List<? extends Number>`说明List中可能包含的元素类型是Number及其子类。而`List<? super Number>`则说明List中包含的是Number及其父类。当引入了上界之后，在使用类型的时候就可以使用上界类中定义的方法。比如访问 `List<? extends Number>`的时候，就可以使用Number类的intValue等方法。

##总结

擦拭法是理解问题的关键。

##参考

* 《Agile Java》 
* [http://www.infoq.com/cn/articles/cf-java-generics](http://www.infoq.com/cn/articles/cf-java-generics)