---
layout: post
title: "Effective Java-方法"
date: 2014-08-20 19:32:51 +0800
comments: true
toc: true
categories: 
- java
---
读书笔记：

38. 检查参数的有效性
39. 必要时进行保护性拷贝
40. 谨慎设计方法签名
41. 慎用重载
42. 慎用可变参数
43. 返回零长度的数组或者集合，而不是null
44. 为所有导出的API元素编写文档注释

<!--more-->

## 38 检查参数的有效性
检查方法参数的有效性，以便更早地发现问题。对于公有方法，要用Javadoc的@throw标签在文档中说明违反参数限制时会抛出的异常。例如：IllegalArgumentException, IndexOutOfBundsException或NullPointerException。对于非公有方法，一般采用断言来检查参数。

通常在计算过程之前，应该进行有效性检查。但如果有效性检查工作成本较高，或者有效性检查已经隐含在计算过程中，那么就不用先进行检查。但计算过程中由于参数的问题造成的异常可能不是方法文档中标明的那个异常，此时可以使用异常转译（第61条）技术，将其转换为正确的异常。

##39 必要时进行保护性拷贝
如果类的内部状态使用了客户端传入的对象，而该对象是可变的，那么尽量不要直接引用这个外部对象，而是将其复制一份。对于构造器的每个可变参数进行保护性拷贝是必要的。而且保护性拷贝应该在有效性检查之前进行。如果参数类型可以被不可信任方子类化，那么不要使用clone方法进行保护性拷贝。

对于访问方法(如get)，为了防御类似的攻击，可以返回内部属性的保护性拷贝。例如对于Date类属性，在返回时，可以新建一个Date对象返回。另一种方式是返回Date.getTime()，即返回long基本类型的时间。访问方法在进行保护性拷贝时，允许使用clone方法，原因是我们知道返回类型时什么，只要它不会是其他某个潜在不可信子类，就可以使用clone方法。

对于内部长度非零的数组，在返回给客户端之前，应该总是进行保护性拷贝。另一种解决方案是，返回数组的不可变视图。（见第13条）

如果类信任它的调用者不会修改内部组件，例如在同一个包中，那么不进行保护性拷贝也是可以的，但类文档中应该清楚说明，调用者绝不能修改受到影响的参数或返回值。

##40 谨慎设计方法签名
1. 谨慎选择方法的名称。
2. 不要过于追求提供便利的方法。每个方法都应该尽其所能，方法太多会使类难以学习。只有某一项操作经常使用时，才考虑为其提供快捷方式。
3. 避免过长的参数列表。解决方法：一是将方法分解成多个方法；二是创建辅助类（一般为静态成员类），保存这些参数。三是使用Builder模式。

对于参数类型，优先使用接口。

对于boolean参数，优先使用两个元素的枚举类型。它使代码更易于阅读和编写。而且未来扩展时，可以轻易增加更多状态。

##41 慎用重载
下面的代码执行结果可能与预期不同：
```java
public static String classify(List<?> list) {
     return "List";
}

public static String classify(Collection<?> c) {
     return "Collection";
}

public static void main(String[] args) {
     Collection<?> c = new ArrayList<BigInteger>();
     System.out.println(classify(c));
     //结果是Collection
}
```

原因是重载(overload)方法的选择是静态的，即在编译期决定。而被覆盖(override)的方法的选择是动态的，即在运行时决定。在上面的例子中，程序编译时，参数的类型是Collection，所以打印的结果是Collection。正如[访问者模式](/blog/2014/08/19/she-ji-mo-shi-fang-wen-zhe-mo-shi)提到的：

>Java语言支持静态的多分派和动态的单分派。对于Java方法重载（Overload），在编译期会根据方法的接收者类型和方法的所有参量类型进行分派，因此是静态多分派。而方法覆盖（Override），是在运行时仅仅根据方法的接收者类型进行分派。

因此，安全而保守的策略是，永远不要导出两个具有相同参数数目的重载方法。如果方法使用了可变参数，最好是不要重载它。例如ObjectOutputStream类中，没有使用重载方法，而是对于每种类型都提供了read和write方法: writeBoolean(boolean), writeInt(int)。对于构造器，没有办法使用不同的方法名称，但可以使用静态工厂方法或者Builder模式。

Java 1.5的自动装箱出现之后，重载也导致了一些麻烦。例如下面的代码：

```java
List<Integer> list = new ArrayList<Integer>();
for(int i = -3; i < 3; i++) {
     list.add(i);
}

for(int i= 0; i < 3; i++) {
     list.remove(i);
}

System.out.println("list: " + list);
//打印结果：list: [-2, 0, 2]
```

原因是List.remove是重载方法：`remove(int i); remove(Object o);` 所以为了达到预期效果，要改为：`list.remove((Integer)i);`

因此，能够重载方法并不意味着就应该重载方法。请慎用重载方法。

##42 慎用可变参数
可变参数接受0或多个指定类型的参数。如果希望参数最少要1个，则可以这样定义方法：

```java
public void someOperation(int a, int... otherArgs) {
}
```

##43 返回零长度的数组或者集合，而不是null
如果返回null，那么客户端始终要进行null判断。返回零长度的数组或集合时，不用在这个级别担心性能问题。

##44 为所有导出的API元素编写文档注释
其中要注意的是，文档注释也应该描述类或者方法的线程安全性。
