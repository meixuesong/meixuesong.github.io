---
layout: post
title: "类文件与字节码"
date: 2014-12-04 20:40:02 +0800
comments: true
categories: 
- java
---
本篇学习类加载过程、类文件的分析工具和字节码。

<!--more-->

## 1. 类加载和类对象
一个.class文件定义了JVM的一种类型。类加入到JVM当前运行态中，首先要加载并连接，进行大量验证，然后提供一个代表该类型的Class对象给正在运行的系统，用于创建新的实例。

#### 加载
加载的过程首先要读取类文件的字节数据流，创建一个字节数组，然后产生对应的Class对象。这个过程会进行一些基本检查。加载结束时，Class对象还不成熟，类也不可用。

#### 连接
加载完成后，类必须连接起来。这分为三个步骤：验证、准备和解析。验证类文件符合预期，不会引起系统运行时错误。准备阶段会分配内存，准备好初始化类中的静态变量（但不会现在初始化变量）。解析阶段会检查类中引用的类型是否有未知类型，如果有会加载进来。

####初始化
一旦需要加载的其他类型全部定位并完成解析，VM就可以初始化这个类。这时所有静态变量都可以被初始化，所有静态初始化代码块都会运行。类的加载全部完成，已经可以使用了。

#### Class对象
加载和连接过程的最终结果是一个Class对象，可以使用这个新类型创建实例了。Class对象可以和反射API一起实现对方法、域和构造方法等类成员的间接访问，通过getSuperClass()返回其父类。

#### 类加载器
比较两个类是否“相等”，只有这两个类是由同一个类加载器加载的前提下才有意义。同一个Class文件，被同一个虚拟机加载，只要加载它们的类加载器不同，那这两个类必定不等。这里所指的“相等”，包括Class对象的equals()方法、isAssignableFrom()方法、isInstance()方法的返回结果以及instanceof关键字。

Java平台有几个经典的类加载器：

* 根（或引导）类加载器：通常在VM启动后不久实例化，一般用本地代码实现。可视为VM的一部分。负责加载系统的基础JAR(主要是rt.jar),而且不做验证工作。
* 扩展类加载器：用来加载安装时自带的标准扩展。一般包括安全性扩展。
* 应用（或系统）类加载器：应用最广泛的类加载器，负责加载应用类。
* 定制类加载器：在更复杂的环境，如EE或比较复杂的SE框架，通常会有些附加（即定制）的类加载器。

在实现类加载器时，Java推荐使用双亲委派模型。即定制类加载器继承自应用类加载器，应用类加载器继承自扩展类加载器，扩展类加载器继承自根类加载器。其工作过程是，如果一个类加载器收到了类加载的请求，它首先把这个请求委派给父类加载器去完成，每个层次的类加载器都是如此，因此所有的加载请求都最终应该传送到顶层的根类加载器。只有当父类加载器反馈自己无法完成加载请求（它的搜索范围中没有找到所需的类）时，子加载器才会尝试自己去加载。双亲委派模型的代码实现示例如下：

```java
protected synchronized Class<?> loadClass(String name, boolean resolve) throws ClassNotFoundException {
	//先检查类是否已经加载过了
	Class c = findLoadedClass(name);
	if (c == null) {
		try {
			if (parent != null) {
				c = parent.loadClass(name, false);
			} else {
				c = findBootstrapClassOrNull(name);
			}
		} catch(ClassNotFoundException e) {
			//如果父类抛出异常，说明父类加载器无法完成加载请求
		}
		
		if (c == null) {
			//父类无法加载时，调用本身的findClass方法进行类加载
			c = findClass(name);
		}
	}
	
	if (resolve) {
		resolveClass(c);
	}
	
	return c;
}
```

从JDK1.2之后，不再提倡用户覆盖loadClass()方法，而应当把自己的类加载逻辑放到findClass()方法中。随着用户对程序动态性的要求，双亲委派模型不一定成立。例如在OSGi中，类加载器变成了复杂的网状结构。

OSGi的Bundle类加载器之间只有规则，没有固定的委派关系。例如，某个Bundle声明了一个它依赖的Package，如果有其他Bundle声明发布了这个Package，那么所有对这个Package的类加载动作都会委派给发布它的Bundle类加载器去完成。一个Bundle类加载器为其他Bundle提供服务时，会根据Export-Package列表严格控制访问范围。如果一个类存在于Bundle的类库中但没有被Export，那么这个Bundle的类加载器能找到这个类，但不会提供给其他Bundle使用，而且OSGi平台也不会把其他Bundle的类加载请求分配给这个Bundle来处理。

假设有三个Bundle：A, B和C。A依赖了`java.*`包；B依赖于A、C和`java.*`包；C依赖于A。那么这三个Bundle的类加载器如下图所示：

![image](/myresource/images/image_blog_2015-01-21.jpg)

如上图所示，OSGi中类加载器的关系不再是双亲委派模型的树形结构，而是已经发展成网状结构。但带来灵活性的同时，也引入了额外的复杂度，带来了线程死锁和内存泄露的风险。

## 2. 方法句柄
反射代码有很多套路，要捕获各种讨厌的异常，代码看起来也不直观。Java 7为间接调用方法引入了java.lang.invoke包，即方法句柄，可以提高安全性和代码的可读性。

#### MethodHandle
它是对可直接执行的方法（或域、构造方法等）的类型化引用，是一个有能力安全调用方法的对象。

```java
MethodHandle mh = getTwoArgMH();
MyType ret;
try {
	//调用obj对象的句柄，传入参数arg0, arg1
	ret = mh.invokeExact(obj, arg0, arg1);
} catch(Throwable e) {
	//...
}
```

#### MethodType
它表示方法签名类型的不可变对象。每个方法句柄都有一个MethodType实例，用来指明方法的返回类型和参数类型。但它没有方法的名称和接收者类型。通过工厂方法可以得到MethodType实例：

```java
//第一个参数为返回类型，随后是方法参数的类型。
//toString()
MethodType mtToString = MethodType.methodType(String.class);
//setter方法
MethodType mtSetter = MethodType.methodType(void.class, Object.class);
//Comparator<String>定义的compareTo()方法
MethodType mtStringComparator = MethodType.methodType(int.class, String.Class, String.class);
```

#### 查找方法句柄
通过lookup对象，你给出持有所需方法的类、方法名称以及你所需方法签名相匹配的MethodType，就可以得到方法句柄：

```java
public MethodHandle getToStringMH() {
	MethodHandle mh;
	MethodType mt = MethodType.methodType(String.class);
	MethodHandles.Lookup lk = MethodHandles.lookup();
	
	try {
		mh = lk.findVirtual(getClass(), "toString", mt);
	} catch(NoSuchMethodException | IllegalAccessException mhx) {
		//...
	}
	
	return mh;
}
```

>如果不是从当前类中查找，则只能看到或取得public方法的句柄。方法句柄总是在安全管理之下安全使用。没有反射中setAccessible()那种破解方法。

有了方法句柄，就可以执行它了。执行方法有两个：invokeExact()和invoke()。前者要求参数类型完全匹配，后者可以在不太匹配时做些修改后执行（如装箱或拆箱）。

#### 示例：反射、代理和方法句柄的使用对比
现在通过一个实例来对比这三种方法。下面的代码演示了如何通过这三种方法来访问私有方法cancel()：

```java
public class ThreadPoolManager {
	//...
	private void cancel(final ScheduledFuture<?> hndl) {
		//...
	}
	
	/* 反射方法
	* 使用方法简单示例：
	* Method meth = manager.makeReflective();
	* meth.invoke(hndl);
	*/
	public Method makeReflective() {
		Method method = null;
		try {
			Class<?> argTypes = new Class[] {ScheduledFuture.class};
			method = ThreadPoolManager.class.getDeclaredMethod("cancel", argTypes);
			method.setAccessible(true);
		} catch(IllegalArgumentException | NoSuchMethodException | SecurityException e) {
			//...
		}
		
		return method;
	}
	
	/* 代理方法
	*  使用方法简单示例：
	*  CancelProxy proxy = manager.makeProxy();
	*  proxy.invoke(manager, hndl);
	*/
	public static class CancelProxy {
		private CancelProxy() {}
		public void invoke(ThreadPoolManager mae, ScheduledFuture<?> hndl) {
			mae.cancel(hndl);
		}
	}
	
	public CancelProxy makeProxy() {
		return new CancelProxy();
	}
	
	/* 方法句柄
	* 使用方法简单示例：
	* MethodHandle mh = manager.makeMh();
	* mh.invokeExact(manager, hndl);
	*/
	public MethodHandle makeMh() {
		MethodHandle mh;
		MethodType desc = MethodType.methodType(void.class, ScheduledFuture.class);
		try {
			mh = MethodHandles.lookup().findVirtual(ThreadPoolManager.class, "cancel", desc);
		} catch(NoSuchMethodException | IllegalAccessException e) {
			//...
		}
		
		return mh;
	}
}
```

三种方法的比较：

方法 | 访问控制 | 类型纪律 | 性能  
---|---|---|---
反射 | 必须使用setAccesible。会被安全管理器禁止 | 不匹配就抛异常 | 较慢
代理 | 内部类可以访问受限方法 | 静态，为了代理全部代理类，可能需要更多PermGen | 跟其他方法一样快
方法句柄 | 取决于上下文，与安全管理器没有冲突 | 运行时是类型安全的，不占用PermGen | 力求跟其他方法调用一样快

方法句柄还有一个特性，可以在静态上下文中确定当前类。例如下面的代码改写了logger的创建方式，可以不用将类名写死：

```java
Logger logger = LoggerFactory.getLogger(MyClass.class);
//可改为：
Logger logger = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());
```

## 3. 了解类文件
### 3.1 类文件的结构
Class文件是一组以8位字节为基础单位的二进制流，各数据项目严格按照顺序紧凑排列，中间没有添加任何分隔符。当遇到需要占用8位字节以上的数据项时，会按照高位在前（Big-Endian，最高位字节在地址最低位，最低位字节在地址最高位。SPARC, POWERPC是这种方式，而x86则相反）的方式分割成若干个8位字节进行存储。

Class文件格式采用类似C语言结构体的伪结构来存储数据，这种伪结构只有两种数据类型：无符号数和表。无符号数属于基本数据类型，u1, u2,u4,u8分别代表1，2，4，8个字节的无符号数。无符号数用来描述数字、索引引用、数量值或者按照UTF8编码构成字符串值。表是由多个无符号数或者其他表作为数据项构成的复合数据类型。所有表都习惯以“_info”结尾。整个Class文件本质上就是一张表。

无论是无符号数还是表，当需要描述同一类型但数量不定的多个数据时，经常会用一个前置的计数器（表示数量）加若干连续的数据项（某一类型的集合）形式来表示。

每个Class文件的头4个字节称为**魔数**（Magic Number），值为`0xCAFEBABE`，其作用是确定这个文件是否为虚拟机所接受。紧接魔数之后的是4个字节的**Class文件版本号**。第5，6字节是次版本号，第7，8字节是主版本号。（JDK1.0的版本号是45.0，JDK1.7.0可生成的Class文件主版本号最大值为51）

版本号之后是**常量池**入口。常量池中的常量数量是不固定的，所以先有一项u2类型的数据表示常量池容量数值（constant_pool_count）。它从1开始计数，0被空出来，用于某些指向常量池的索引值的数据在特定情况下表达“不引用任何一个常量池项目”的含义。

常量池主要存放两大类常量：字面量（Literal）和符号引用（Symbolic References）。字面量比较接近于常量概念，如字符串、声明为final的常量值等。而符号引用则包括类和接口的全限定名（Full Qualifed Name）、字段的名称和描述符以及方法的名称和描述符。当虚拟机运行时，需要从常量池获得对应的符号引用，瑞在类创建时或运行时解析、翻译到具体的内存地址中。

常量池中每一项常量都是一个表，JDK1.7之前共有11种不同的表结构数据，1.7又增加了三种以支持动态语言调用。这14种表的第1位是u1类型的标志位，代表当前这个常量属于哪种常量类型。每种常量类型均有自己的结构。

**访问标志**紧跟常量池，用两个字节表示。主要用于识别Class是类还是接口，是否public，是否abstract类型，是否final等。

**类索引、父类索引和接口索引集合**按顺序排列在访问标志之后。类索引用于确定这个类的全限定名，父类索引用于确定父类的全限定名，他们都用两个u2类型的索引值表示。接口索引集合用于描述这个类实现了哪些接口，由于这是可变的，因为入口有一个计数器表示索引表的容量。

**字段表集合**（Field_info）用于描述接口或类中声明的亦是。包括类变量和实例变量，但不包括方法的局域变量。信息包括作用域（public/private/protected）、实例还是类变量(static)、可变性（final）、并发可见性(volatile)、可否序列化（transient）、数据类型、字段名等。字段表集合不会列出父类或实现接口中继承的字段，但可能列出原本Java代码中不存在的字段（如向内部类添加指向外部类实例的字段）。

**方法表集合**与字段表集合相似。但方法里的Java代码编译成字节码指令后存放在方法属性表集合中一个名为“Code”的属性里面。Code属性表包含方法的很多信息。只说几个重要的：

* max_stack:方法的操作数栈（Operand Stacks）深度最大值
* max_locals:局部变量所需的存储空间。单位为Slot，局部变量分配内存的最小单位。byte,int等长度不超过32位的数据类型，每个局部变量占用1个Slot，doublue和long需要2个Slot。并不是方法中用到多少个局部变量，所占Slot之和就是所需存储空间，Slot是可以重用的，当代码执行超过一个局部变量的作用域时，这个局部变量的Slot就可以被其他局部变量使用。
* code_length:字节码长度
* code: 存储字节码指令的一系列字节流。
* exception_table:异常表，编译器使用异常表而不是简单的跳转命令来实现Java异常及finally处理机制。

方法表除了Code属性，还有还有多种其他属性。例如Exceptions属性（即方法声明中的throws列表的异常）、LineNumberTable属性（javac用`-g:none`或`-g:lines`参数。如果不生成LineNumberTable属性，则异常中不会显示出错的行号）、LocalVariableTable属性（javac用`-g:none`或`-g:vars`参数，如果不生成这项信息，IDE只会显示arg0, arg1等，丢失了原有的参数名）。


**属性表集合**，Class文件、字段表、方法表都可以携带自己的属性表集合，以用于描述某些场景专有的信息。

由于类文件是二进制文件，和它打交道并不容易。Oracle JVM的javap这个工具可以用来探视类文件内部和反编译。

我们以一个简单的Java类作为示例：

```java
public class Sample {
	private byte b;
	private char c;
	private double d;
	private float f;
	private int i;
	private Integer Int;
	private long l;
	private String s;
	private boolean bl;
	private int[] array;
	
	//getter, setter
```

###3.2 查看类文件的方法和属性

```java
$ javap  Sample.class 
Compiled from "Sample.java"
public class com.ubone.tdd.chapter1.javaio.Sample {
  public com.ubone.tdd.chapter1.javaio.Sample();
  public byte getB();
  public void setB(byte);
  public char getC();
  //其它getter, setter方法...
}
```

javap默认显示public, protected和包级protected级别的方法和属性。加上-p选项后可以显示private方法和属性。

###3.3 方法签名的内部形式
JVM内部用的方法签名使用紧凑形式，例如int用I表示。这称为类型描述符：

* B: byte
* C: char(16位Unicode字符)
* D: double
* F: float
* I: int
* J: long
* L<类型名称>: 引用类型，如：Ljava/lang/String
* S: short
* Z: boolean
* [: array-of

使用javap -s可以输出签名的类型描述符：

```java
$ javap -s Sample.class 
Compiled from "Sample.java"
public class com.ubone.tdd.chapter1.javaio.Sample {
  public com.ubone.tdd.chapter1.javaio.Sample();
    Signature: ()V

  public byte getB();
    Signature: ()B

  public void setB(byte);
    Signature: (B)V

  public char getC();
    Signature: ()C

  public void setC(char);
    Signature: (C)V

  public double getD();
    Signature: ()D

  public void setD(double);
    Signature: (D)V

  public float getF();
    Signature: ()F

  public void setF(float);
    Signature: (F)V

  public int getI();
    Signature: ()I

  public void setI(int);
    Signature: (I)V

  public java.lang.Integer getInt();
    Signature: ()Ljava/lang/Integer;

  public void setInt(java.lang.Integer);
    Signature: (Ljava/lang/Integer;)V

  public long getL();
    Signature: ()J

  public void setL(long);
    Signature: (J)V

  public java.lang.String getS();
    Signature: ()Ljava/lang/String;

  public void setS(java.lang.String);
    Signature: (Ljava/lang/String;)V

  public boolean isBl();
    Signature: ()Z

  public void setBl(boolean);
    Signature: (Z)V

  public int[] getArray();
    Signature: ()[I

  public void setArray(int[]);
    Signature: ([I)V
}
```

###3.4 常量池
常量池是为类文件中的其他（常量）元素提供快捷访问方式的区域。通过javap -v可以查看常量池的信息：

```
Constant pool:
   #1 = Class              #2             //  com/ubone/tdd/chapter1/javaio/Sample
   #2 = Utf8               com/ubone/tdd/chapter1/javaio/Sample
   #3 = Class              #4             //  java/lang/Object
   #4 = Utf8               java/lang/Object
   #5 = Utf8               b
   #6 = Utf8               B
   #7 = Utf8               c
   #8 = Utf8               C
   #9 = Utf8               d
  #10 = Utf8               D
  #11 = Utf8               f
  #12 = Utf8               F
  #13 = Utf8               i
  #14 = Utf8               I
  #15 = Utf8               Int
  #16 = Utf8               Ljava/lang/Integer;
  #17 = Utf8               l
  #18 = Utf8               J  
  ...
  #70 = Utf8               getL
  #71 = Utf8               ()J
  #72 = Fieldref           #1.#73         //  com/ubone/tdd/chapter1/javaio/Sample.l:J
  #73 = NameAndType        #17:#18        //  l:J
  #74 = Utf8               setL
  #75 = Utf8               (J)V
  ...
```

如上所示，常量池的条目是带有类型的，它们还会相互引用。例如类型为Class的条目会引用类型为Utf8的条目。后者是个字符串，因此第1行为类的名称。

72行的Fieldref定义了一个域，解析这个域需要名称、类型和它所在的类。`#1.#73`表示来自类`#1`,域为`#73`。`#73`的NameAndType描述名称和类型，分别来自17和18，即类型J(Long)，名称为`l`。

## 4. 字节码
字节码的基本特性：

* 字节码是程序的中间表示形式，介于人类可读的源码和机器码之间。
* 字节码由javac产生。
* 某些高级语言特性在编译时已经从字节码去掉。例如for语句在字节码中被转换成分支指令。
* 每个操作码都由一个字节表示（因此叫做字节码）。
* 字节码可以进一步编译成机器码，也就是“即时编译”。

### 反编译类
javap可以用于反编译类：

```
$ javap -c -p Sample.class 
Compiled from "Sample.java"
public class com.ubone.tdd.chapter1.javaio.Sample {
  private byte b;

  private char c;
  ...
  
    public com.ubone.tdd.chapter1.javaio.Sample();
    Code:
       0: aload_0       
       1: invokespecial #28                 // Method java/lang/Object."<init>":()V
       4: return        
  ...
  
  public long getL();
    Code:
       0: aload_0       
       1: getfield      #72                 // Field l:J
       4: lreturn       

  public void setL(long);
    Code:
       0: aload_0       
       1: lload_1       
       2: putfield      #72                 // Field l:J
       5: return        


```

代码前的数字表示从方法开始算起的字节码偏移量。先看构造方法，由于void构造方法总会隐式调用父类的构造方法。因此有invokespecial指令。对于方法getL()和setL()也可以看到相应的操作码和参数。

javac产生的字节码没有经过特别优化，是非常简单的表示形式。大部分优化工作由JIT编译器来完成。

### 运行时环境
JVM没有处理器寄存器，而是使用堆栈机完成所有的计算和操作，所以理解堆栈机的操作对理解字节码至关重要。方法在运行时需要一块内存区域作为计算堆栈来计算新值。另外，每个运行的线程都需要一个调用堆栈来记录当前正在执行的方法。来看下面的代码是如何完成计算的：

`return 3 + petRecords.getNumberOfPets("Ben");`

系统首先会把3压入操作数栈，然后把接收对象（petRecords）压入计算堆栈，传入的参数尾随其后。然后invoke操作符会调用方法getNumberOfPets，把控制权移交给被调用的方法。进入新方法后，需要启用不同的操作数栈，所以已经在调用者操作数栈中的值不可能影响被调用方法的计算结果。

当getNumberOfPets完成时，返回结果会被放到调用者的操作数栈中，进程中与getNumberOfPets相关的部分也会从调用堆栈中移走。然后相加运算得到结果。

### 操作码
JVM字节码由操作码（opcode）序列构成，每个指令后可能会跟一些参数（Operands，操作数）。每个操作码由一个单字节值表示，所以最多有255个操作码。目前用了200个左右。大致可以分为以下几类，摘要说明如下：

>* 参数：操作码参数。如果参数出现在括号中，表示可选。以i打头的参数用来作为常量池或局部变量中的查询索引的几个字节。如果有多个此类参数，会合并在一直。例如i1,i2表示从这两个字节生成一个16位的索引。
* 堆栈布局：展示栈在操作码执行前后的状态。
* 表中操作码并不全，只用于示例。

加载和储存操作码，这个族系负责将值加载到栈或者检索值。有很多不同形式的变体。如dload操作码把双精度数从局部变量加载到栈上。

![image](/myresource/images/image_blog_2014-12-05-5-4.jpg)

数学运算操作码用来执行数学运算。

![image](/myresource/images/image_blog_2014-12-05-5-5.jpg)

![image](/myresource/images/image_blog_2014-12-05-5-6.jpg)

![image](/myresource/images/image_blog_2014-12-05-5-7.jpg)



**平台操作操作码**

在字节码这一级，构造方法被转换成带有特殊名称<init>的方法。不能由用户代码调用，但可以由字节码调用。这便形成了一个与对象创建直接相关的不同的字节码模式：new之后跟着一个dup，然后是一个调用<init>方法的invokespecial.

![image](/myresource/images/image_blog_2014-12-05-5-8.jpg) 

>为了节省字节，很多字节码都有快捷方式。










