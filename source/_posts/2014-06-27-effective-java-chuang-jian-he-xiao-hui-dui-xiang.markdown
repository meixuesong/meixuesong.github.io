---
layout: post
title: "Effective Java-创建和销毁对象"
date: 2014-06-27 09:20:04 +0800
comments: true
toc: true
categories: 
- Java

---

《Effective Java》是Java语言的经典著作，本文总结书中“创建和销毁对象”的论述。主要包括：

1. 用静态工厂方法代替构造器
2. 构造器参数比较多时，考虑使用Builder
3. 用私有构造方法或枚举强化单例属性
4. 通过private构造器强化不可实例化的能力
5. 避免创建不必要的对象
6. 消除过期的对象引用
7. 避免使用finalize方法

<!--more-->

##1.用静态工厂方法代替构造器

用静态工厂方法代替构造器有以下几个好处：

1. 静态工厂方法有名称，而构造器只能通过参数区分；
2. 静态工厂方法不必每次都创建一个新对象；
3. 静态工厂方法可以返回该类的任何子类；
4. 在创建参数化实例时，静态方法工厂使代码更加简单。

```java
//使用构造方法时：
Map<String, List<String>> m = new HashMap<String, List<String>>();

//假设有静态方法后：
public static <K, V> HashMap<K, V> newInstance() {
	return new HashMap<K, V>();
}

//只需要：
Map<String, List<String>> m = HashMap.newInstance();
```

实际上，Java 7和8在泛型类型推断上已经有了一些改进，可以让代码写得更简单些。因此上述第4条优势已经不明显。

静态工厂方法的缺点：

1. 类如果没有public或protected构造方法，就无法被子类化。
2. 与其它静态方法没什么区别，无法明确标识出来。全靠命名惯例，常用的静态方法名包括：valueOf, of, getInstance, newInstance, getType, newType。

##2.构造器参数比较多时，考虑使用Builder

构造器和静态方法的缺点是参数比较多时不方便，使用setter方法时，可能造成不一致，而且也无法把类做成不可变，影响线程安全。

使用Builder模式就可以很好地解决这个问题。

```java
public class BuilderDemoClass {
    //1个必须属性，2个可选属性。
    private final int a_required;
    private final int b;
    private final int c;

    public static class Builder {
        private int a_required;
        private int b;
        private int c;

        public Builder(int a) {
            this.a_required = a;
        }

        public Builder bb(int value) {
            this.b = value;

            return this;
        }

        public Builder cc(int value) {
            this.c = value;

            return this;
        }

        public BuilderDemoClass build() {
            return new BuilderDemoClass(this);
        }
    }

    private BuilderDemoClass(Builder builder) {
        a_required = builder.a_required;
        b = builder.b;
        c = builder.c;
    }

    public int getA_required() {
        return a_required;
    }

    public int getB() {
        return b;
    }

    public int getC() {
        return c;
    }
}
```

测试代码：

```java
public class BuilderDemoClassTest extends TestCase{
    public void testBuilder() {
        BuilderDemoClass c = new BuilderDemoClass.Builder(10).bb(20).cc(30).build();

        Assert.assertEquals(c.getA_required(), 10);
        Assert.assertEquals(c.getB(), 20);
        Assert.assertEquals(c.getC(), 30);
    }
}
```

##3.用私有构造方法或枚举强化单例属性

这一条说的是实现单例的几种方法，推荐使用枚举类型。

```java
public enum MySingleton {
	INSTANCE;
	
	public void doSomething() {
		...
	}
}

//调用：

MySingleton.INSTANCE.doSomething();
```

之前有过详细总结：[单例与枚举](http://blog.ubone.com/blog/2014/06/25/just-a-test/)

##4.通过private构造器强化不可实例化的能力

对于一些工具类，主要包括静态方法，可以将构造器private，避免其被实例化。

```java
public class UtilityClass {
	//强调不能被实例化
	private UtilityClass() {
		throw new AssertionError();
	}
	
	public static void someStaticMethod() {
		...
	}
}
```

##5.避免创建不必要的对象

* 最好是重用对象，而不是每次创建一个相同功能的对象。
* 对于同时提供了静态工厂和构造器的不可变类，通常使用静态工厂，例如Boolean.valueOf(String) 优先于Boolean(String)。
* 对于某些已知不会被修改的可变对象，如果频繁用到，可以先缓存起来。
* 优先使用基本类型而不是装箱基本类型，当心无意识的自动装箱。例如：

```java
    public void testAutoBoxing() {
        Long sum = 0L;
        for(long i = 0; i < Integer.MAX_VALUE; i ++) {
            sum += i;
        }
        
        System.out.println(sum);
    }
```

上面的代码每次增加sum时，都构造了一个实例。把Long sum改成long sum后，我的Thinkpad X230运行时间从15秒减少到了3.3秒。

##6.消除过期的对象引用

虽然Java有自动垃圾回收功能，但仍有许多要注意的事项。如果一个对象的引用被无意识地保留下来，则对象不会被回收，因此可能导致一连串的对象无法回收。

* 只要类是自己管理内存，就要警惕内存泄漏问题。 
* 缓存是内存泄漏的常见来源。
* 监听器和回调要注意显式取消注册。

##7.避免使用finalize方法

finalize方法通常是不可预期的、危险的，并且常常是没必要的。

* 无法保证该方法被执行，以及何时执行。因此时间敏感的工作绝不能放到该方法中。
* 由于每种JVM的垃圾回收算法不同，因此该方法在一种JVM上运行良好，并不代表在其它JVM上也能正常工作。
* 该方法的线程优先级比较低，因此无法保证它会运行。
* 绝不要依赖该方法去更新关键持久化状态。例如去释放一个锁。
* System.gc和System.runFinalization两个方法并不能保证finalize方法一定会被执行。所以不要被它们迷惑。 
* 唯一能确保该方法被执行的是System.runFi- nalizersOnExit和Runtime.runFinalizersOnExit。但它们是臭名昭著的方法，本身有严重问题，尽量不要使用。
* 使用该方法有严重的性能问题。
* 。。。

**有一万个理由不要使用finalize方法。因此你就别用它了！**










