---
layout: post
title: "Java I/O"
date: 2014-09-14 21:22:58 +0800
comments: true
categories: 
- java
---

##1. File类
### 1.1 目录列表器
下面的代码示例，通过正则表达式过滤并返回指定文件的下级列表：

```java
	public static String[] dirList(String path, final String ptn) {
		File file = new File(path);
		if (ptn == null || "".equals(ptn.trim())) {
			return file.list();
		}
		
		FilenameFilter fnf = new FilenameFilter() {
			private Pattern pattern = Pattern.compile(ptn);
			@Override
			public boolean accept(File dir, String name) {
				return pattern.matcher(name).matches();
			}
		};
		
		return file.list(fnf);
	}
```

### 1.2 目录实用工具

```java
	public static File[] local(File dir, final String regex) {
		return dir.listFiles(new FilenameFilter() {
			private Pattern pattern = Pattern.compile(regex);

			public boolean accept(File dir, String name) {
				return pattern.matcher(new File(name).getName()).matches();
			}
		});
	}
	
以及File类的exists(), isDirectory(), isFile(), mkdirs(), delete(), renameTo()等方法。
```	

## 2. I/O流的典型使用方式
### 2.1 缓冲输入文件
下面的例子适用于字符输入：

```java
public class BufferedInputFile {
	// Throw exceptions to console:
	public static String read(String filename) throws IOException {
		// Reading input by lines:
		BufferedReader in = new BufferedReader(new FileReader(filename));
		String s;
		StringBuilder sb = new StringBuilder();
		while ((s = in.readLine()) != null)
			sb.append(s + "\n");
		in.close();
		return sb.toString();
	}

	public static void main(String[] args) throws IOException {
		System.out.print(read("BufferedInputFile.java"));
	}
}
```

###2.2 从内存输入
在下面的示例中，从BufferedInputFile.read()读入的String结果被用来创建一个StringReader。然后调用read()每次读取一个字符：

```java
public static class MemoryInput {
	public static void main(String[] args) throws IOException {
		StringReader in = new StringReader(
				BufferedInputFile.read("MemoryInput.java"));
		int c;
		while ((c = in.read()) != -1)
			System.out.print((char) c);
	}
}
```

###2.3 格式化的内存输入

```java
DataInputStream in = new DataInputStream(
		new ByteArrayInputStream(
				BufferedInputFile.read("FormattedMemoryInput.java")
				.getBytes()));

in.readInt();
in.readChar();			
				
DataInputStream in2 = new DataInputStream(
		new BufferedInputStream(
				new FileInputStream("TestEOF.java")));							
while (in.available() != 0)
	System.out.print((char) in.readByte());
/*注意available()的工作方式会随着媒介类型的不同而不同。
  表示“在没有阻塞的情况下所能读取的字节数”，
  对于文件，这意味着整个文件，但不同类型的流可能不是这样。
*/
```

###2.4 基本的文件输出
FileWriter可用于向文件写入数据，通常会用BufferedWriter将其包装。下例写入文本文件：

```java
PrintWriter out = new PrintWriter(
		new BufferedWriter(
				new FileWriter("something.out")));
out.println("Hello!");
out.close();

//对于文本文件有快捷方式：
PrintWriter out = new PrintWriter(file);
out.println("Hello!");
out.close();
```

### 2.5 存储和恢复数据

```java
public class StoringAndRecoveringData {
  public static void main(String[] args)
  throws IOException {
    DataOutputStream out = new DataOutputStream(
      new BufferedOutputStream(
        new FileOutputStream("Data.txt")));
    out.writeDouble(3.14159);
    out.writeUTF("That was pi");
    out.writeDouble(1.41413);
    out.writeUTF("Square root of 2"); 
    out.close();
    DataInputStream in = new DataInputStream(
      new BufferedInputStream(
        new FileInputStream("Data.txt")));
    System.out.println(in.readDouble());
    // Only readUTF() will recover the
    // Java-UTF String properly:
    System.out.println(in.readUTF());
    System.out.println(in.readDouble());
    System.out.println(in.readUTF());
  }
}
```

### 2.6 读写随机访问文件
使用RandomAccessFile，类似于组合使用DataInputStream和DataOutputStream。它不支持装饰，所以不能与InputStream和OutputStream子类的任何部分组合起来。可以假定其已经被正确地缓冲。

```java
public class UsingRandomAccessFile {
  static String file = "rtest.dat";
  static void display() throws IOException {
    RandomAccessFile rf = new RandomAccessFile(file, "r");
    for(int i = 0; i < 7; i++)
      System.out.println(
        "Value " + i + ": " + rf.readDouble());
    System.out.println(rf.readUTF());
    rf.close();
  }
  public static void main(String[] args)
  throws IOException {
    RandomAccessFile rf = new RandomAccessFile(file, "rw");
    for(int i = 0; i < 7; i++)
      rf.writeDouble(i*1.414);
    rf.writeUTF("The end of the file");
    rf.close();
    display();
    rf = new RandomAccessFile(file, "rw");
    rf.seek(5*8);
    rf.writeDouble(47.0001);
    rf.close();
    display();
  }
}
```

## 3. NIO
新的I/O速度提升来自于所使用的结构更接近于操作系统执行I/O的方式：通道和缓冲器。我们只和缓冲器交互，并把缓冲器派送到通道。通道要么从缓冲器获得数据，要么向缓冲器发送数据。以下示例演示了三种类型的流，用以产生可写、可读可写以及可读的通道。

```java
public class GetChannel {
	private static final int BSIZE = 1024;

	public static void main(String[] args) throws Exception {
		// Write a file:
		FileChannel fc = new FileOutputStream("/Users/mxs/Desktop/data.txt")
				.getChannel();
		fc.write(ByteBuffer.wrap("Some text ".getBytes()));
		fc.close();
		// Add to the end of the file:
		fc = new RandomAccessFile("/Users/mxs/Desktop/data.txt", "rw")
				.getChannel();
		fc.position(fc.size()); // Move to the end
		fc.write(ByteBuffer.wrap("Some more".getBytes()));
		fc.close();
		// Read the file:
		fc = new FileInputStream("/Users/mxs/Desktop/data.txt").getChannel();
		ByteBuffer buff = ByteBuffer.allocate(BSIZE);
		fc.read(buff);
		buff.flip();
		while (buff.hasRemaining())
			System.out.print((char) buff.get());
	}
} /*
 * Output: Some text Some more
 */// :~

```

### 3.1 转换数据

```java
public class BufferToText {
	private static final int BSIZE = 1024;

	public static void main(String[] args) throws Exception {
		FileChannel fc = new FileOutputStream("/Users/mxs/Desktop/data2.txt").getChannel();
		fc.write(ByteBuffer.wrap("Some text".getBytes()));
		fc.close();
		fc = new FileInputStream("/Users/mxs/Desktop/data2.txt").getChannel();
		ByteBuffer buff = ByteBuffer.allocate(BSIZE);
		fc.read(buff);
		buff.flip();
		// Doesn't work:
		System.out.println(buff.asCharBuffer());
		// Decode using this system's default Charset:
		buff.rewind();
		String encoding = System.getProperty("file.encoding");
		System.out.println("Decoded using " + encoding + ": "
				+ Charset.forName(encoding).decode(buff));
		// Or, we could encode with something that will print:
		fc = new FileOutputStream("/Users/mxs/Desktop/data2.txt").getChannel();
		fc.write(ByteBuffer.wrap("Some text".getBytes("UTF-16BE")));
		fc.close();
		// Now try reading again:
		fc = new FileInputStream("/Users/mxs/Desktop/data2.txt").getChannel();
		buff.clear();
		fc.read(buff);
		buff.flip();
		System.out.println(buff.asCharBuffer());
		// Use a CharBuffer to write through:
		fc = new FileOutputStream("/Users/mxs/Desktop/data2.txt").getChannel();
		buff = ByteBuffer.allocate(24); // More than needed
		buff.asCharBuffer().put("Some text");
		fc.write(buff);
		fc.close();
		// Read and display:
		fc = new FileInputStream("/Users/mxs/Desktop/data2.txt").getChannel();
		buff.clear();
		fc.read(buff);
		buff.flip();
		System.out.println(buff.asCharBuffer());
	}
} 
/*
 * Output: ???? Decoded using Cp1252: Some text Some text Some text
 */// :~
```

### 3.2 获取基本类型
下面的示例演示了怎样插入和抽取各种数值：

```java
public class GetData {
	private static final int BSIZE = 1024;

	public static void main(String[] args) {
		ByteBuffer bb = ByteBuffer.allocate(BSIZE);
		// Allocation automatically zeroes the ByteBuffer:
		int i = 0;
		while (i++ < bb.limit())
			if (bb.get() != 0)
				print("nonzero");
		print("i = " + i);
		bb.rewind();
		// Store and read a char array:
		bb.asCharBuffer().put("Howdy!");
		char c;
		while ((c = bb.getChar()) != 0)
			printnb(c + " ");
		print();
		bb.rewind();
		// Store and read a short:
		bb.asShortBuffer().put((short) 471142);
		print(bb.getShort());
		bb.rewind();
		// Store and read an int:
		bb.asIntBuffer().put(99471142);
		print(bb.getInt());
		bb.rewind();
		// Store and read a long:
		bb.asLongBuffer().put(99471142);
		print(bb.getLong());
		bb.rewind();
		// Store and read a float:
		bb.asFloatBuffer().put(99471142);
		print(bb.getFloat());
		bb.rewind();
		// Store and read a double:
		bb.asDoubleBuffer().put(99471142);
		print(bb.getDouble());
		bb.rewind();
	}
}

/* Output:
i = 1025
H o w d y !
12390
99471142
99471142
9.9471144E7
9.9471142E7
*///:~
```

### 3.3 视图缓冲器
视图缓冲器（View buffer）可以让我们通过某个特定的基本数据类型的视窗查看其底层的ByteBuffer。

```java
public class IntBufferDemo {
  private static final int BSIZE = 1024;
  public static void main(String[] args) {
    ByteBuffer bb = ByteBuffer.allocate(BSIZE);
    IntBuffer ib = bb.asIntBuffer();
    // Store an array of int:
    ib.put(new int[]{ 11, 42, 47, 99, 143, 811, 1016 });
    // Absolute location read and write:
    System.out.println(ib.get(3));
    ib.put(3, 1811);
    // Setting a new limit before rewinding the buffer.
    ib.flip();
    while(ib.hasRemaining()) {
      int i = ib.get();
      System.out.println(i);
    }
  }
} /* Output:
99
11
42
47
1811
143
811
1016
*///:~
```

```java
public class ViewBuffers {
  public static void main(String[] args) {
    ByteBuffer bb = ByteBuffer.wrap(
      new byte[]{ 0, 0, 0, 0, 0, 0, 0, 'a' });
    bb.rewind();
    printnb("Byte Buffer ");
    while(bb.hasRemaining())
      printnb(bb.position()+ " -> " + bb.get() + ", ");
    print();
    CharBuffer cb =
      ((ByteBuffer)bb.rewind()).asCharBuffer();
    printnb("Char Buffer ");
    while(cb.hasRemaining())
      printnb(cb.position() + " -> " + cb.get() + ", ");
    print();
    FloatBuffer fb =
      ((ByteBuffer)bb.rewind()).asFloatBuffer();
    printnb("Float Buffer ");
    while(fb.hasRemaining())
      printnb(fb.position()+ " -> " + fb.get() + ", ");
    print();
    IntBuffer ib =
      ((ByteBuffer)bb.rewind()).asIntBuffer();
    printnb("Int Buffer ");
    while(ib.hasRemaining())
      printnb(ib.position()+ " -> " + ib.get() + ", ");
    print();
    LongBuffer lb =
      ((ByteBuffer)bb.rewind()).asLongBuffer();
    printnb("Long Buffer ");
    while(lb.hasRemaining())
      printnb(lb.position()+ " -> " + lb.get() + ", ");
    print();
    ShortBuffer sb =
      ((ByteBuffer)bb.rewind()).asShortBuffer();
    printnb("Short Buffer ");
    while(sb.hasRemaining())
      printnb(sb.position()+ " -> " + sb.get() + ", ");
    print();
    DoubleBuffer db =
      ((ByteBuffer)bb.rewind()).asDoubleBuffer();
    printnb("Double Buffer ");
    while(db.hasRemaining())
      printnb(db.position()+ " -> " + db.get() + ", ");
  }
} 
/* Output:
Byte Buffer 0 -> 0, 1 -> 0, 2 -> 0, 3 -> 0, 4 -> 0, 5 -> 0, 6 -> 0, 7 -> 97,
Char Buffer 0 ->  , 1 ->  , 2 ->  , 3 -> a,
Float Buffer 0 -> 0.0, 1 -> 1.36E-43,
Int Buffer 0 -> 0, 1 -> 97,
Long Buffer 0 -> 97,
Short Buffer 0 -> 0, 1 -> 0, 2 -> 0, 3 -> 97,
Double Buffer 0 -> 4.8E-322,
*///:~
```

### 3.4 用缓冲器操纵数据

![image](/myresource/images/image_blog_20140916_001220.jpg)

### 3.5 缓冲器的细节
Buffer由数据和四个索引组成：mark, position, limit, capacity。相关的方法：

* capacity() 返回缓冲区容量。
* clear() 清空缓冲区，position设置为0，limit设置为容量。
* flip() 将limit设置为position, position设置为0.用于准备从缓冲区读取已经写入的数据。
* limit() 返回limit值。
* limit(int lim) 设置limit值。
* mark() 将mark设置为position。
* position() 返回position值。
* position(int pos) 设置position值。
* remaining() 返回（limit - position）。
* hasRemaining() 若有介于position和limit之间的元素，则返回true。