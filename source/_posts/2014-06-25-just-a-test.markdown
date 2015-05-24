---
layout: post
title: "单例与枚举"
date: 2014-06-25 09:21:22 +0800
comments: true
toc: true
categories: 
- Java
---

在《Effective Java》中，提到创建单例的三种方法以及枚举类型的使用。

<!--more-->

##单例实现
作者首先说明Java 1.5之前的两种单例实现方法：

###方法一：Singleton with public final field

```java
// Singleton with public final field
   public class Elvis {
       public static final Elvis INSTANCE = new Elvis();
       private Elvis() { ... }
       public void leaveTheBuilding() { ... }
   }
```

这种方法通过私有构造方法，并提供public static final属性实现单例。但其缺点是，通过反射，及AccessibleObject.setAccessible(true)方法，可以调用私有构造方法。

###方法二：Singleton with static factory

```
// Singleton with static factory
public class Elvis {
	private static final Elvis INSTANCE = new Elvis(); 
	private Elvis() { ... }
	public static Elvis getInstance() { return INSTANCE; }
	public void leaveTheBuilding() { ... }
}
```   

这种方法也是通过私有构造方法，并提供public static方法实现单例。但其缺点时反序列化后，会创建一个新的实例。为了解决这个问题，要增加readResolve方法：

```
// readResolve method to preserve singleton property
   private Object readResolve() {
        // Return the one true Elvis and let the garbage collector
        // take care of the Elvis impersonator.
       return INSTANCE;
   }

```   

readResolve方法用于替换从Stream流中读出的对象，确保不会反序列化出来另一个实例。

###方法三：Enum实现单例

Java 1.5以后，可以使用枚举类型实现单例：

```
// Enum singleton - the preferred approach
   public enum Elvis {
       INSTANCE;
       public void leaveTheBuilding() { ... }
   }
```   

**只有一个元素的enum类型是实现单例最好的方法。**不存在序列化、反射等影响。

上面的简单例子似乎不太清晰，到底怎么用呢？就如下面这样：

```
public enum MySingleton {
    INSTANCE;

    private String name;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void otherMethod() {
        ...
    }
}


//调用示例
MySingleton.INSTANCE.setName("ABCD");
```

枚举类型究竟还有哪些功能呢？

##枚举类型

###枚举类型的基本用法

枚举类型最基本的用法就像下面的例子：

```
public enum Day {
    SUNDAY, MONDAY, TUESDAY, WEDNESDAY,
    THURSDAY, FRIDAY, SATURDAY 
}

public class EnumTest {
    Day day;
    
    public EnumTest(Day day) {
        this.day = day;
    }
    
    public void tellItLikeItIs() {
        switch (day) {
            case MONDAY:
                System.out.println("Mondays are bad.");
                break;
                    
            case FRIDAY:
                System.out.println("Fridays are better.");
                break;
                         
            case SATURDAY: case SUNDAY:
                System.out.println("Weekends are best.");
                break;
                        
            default:
                System.out.println("Midweek days are so-so.");
                break;
        }
    }
    
    public static void main(String[] args) {
        EnumTest firstDay = new EnumTest(Day.MONDAY);
        firstDay.tellItLikeItIs();
        EnumTest thirdDay = new EnumTest(Day.WEDNESDAY);
        thirdDay.tellItLikeItIs();
        EnumTest fifthDay = new EnumTest(Day.FRIDAY);
        fifthDay.tellItLikeItIs();
        EnumTest sixthDay = new EnumTest(Day.SATURDAY);
        sixthDay.tellItLikeItIs();
        EnumTest seventhDay = new EnumTest(Day.SUNDAY);
        seventhDay.tellItLikeItIs();
    }
}

//The output is:

Mondays are bad.
Midweek days are so-so.
Fridays are better.
Weekends are best.
Weekends are best.

```

还可以对枚举类型遍历：

```
for (Day p : Day.values()) {
	...
}
```

其它大家熟知的用法还包括：

```
public enum Coin {
    PENNY(1), NICKEL(5), DIME(10), QUARTER(25);

    Coin(int value) {
        this.value = value;
    }

    private final int value;

    public int value() {
        return value;
    }
}
```

###枚举类型的高级用法

####枚举常量的自引用（Self-Reference）限制

```
//有错误代码
enum Color {
    RED, GREEN, BLUE;
    Color() { colorMap.put(toString(), this); }

    static final Map<String,Color> colorMap =
        new HashMap<String,Color>();
}
```

上面的代码中，colorMap并未初始化，所以构造方法会出错！可以改成：

```
enum Color {
    RED, GREEN, BLUE;

    static final Map<String,Color> colorMap =
        new HashMap<String,Color>();
    static {
        for (Color c : Color.values())
            colorMap.put(c.toString(), c);
    }
}
```

####Enum Constants with Class Bodies

枚举类型还能这么玩：

```java
enum Operation {
    PLUS {
        double eval(double x, double y) { return x + y; }
    },
    MINUS {
        double eval(double x, double y) { return x - y; }
    },
    TIMES {
        double eval(double x, double y) { return x * y; }
    },
    DIVIDED_BY {
        double eval(double x, double y) { return x / y; }
    };

    // Each constant supports an arithmetic operation
    abstract double eval(double x, double y);

    public static void main(String args[]) {
        double x = Double.parseDouble(args[0]);
        double y = Double.parseDouble(args[1]);
        for (Operation op : Operation.values())
            System.out.println(x + " " + op + " " + y +
                               " = " + op.eval(x, y));
    }
}


java Operation 2.0 4.0
2.0 PLUS 4.0 = 6.0
2.0 MINUS 4.0 = -2.0
2.0 TIMES 4.0 = 8.0
2.0 DIVIDED_BY 4.0 = 0.5
```
