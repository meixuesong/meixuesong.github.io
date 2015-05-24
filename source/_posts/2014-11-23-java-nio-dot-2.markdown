---
layout: post
title: "Java NIO.2"
date: 2014-11-23 10:59:37 +0800
comments: true
toc: true
categories: 
- java
---
Java 7提供了新的NIO(或称为NIO.2, JSR-203)，这是一组新的类和方法，用于取代File类与文件系统的交互，提供新的异步处理类并简化Socket与通道的编码工作。

<!--more-->
在Java 1.4之前，Java缺乏对非阻塞I/O的支持，1.4引入了非阻塞I/O，为I/O操作抽象出缓冲区和通道层；提供字符集的编码和解码能力；能够将文件映射为内存数据；实现正则表达式。Java 7进一步扩展了NIO的能力。

## 1. PATH
Path相关的类包括：

* Path：获取路径信息
* Paths：工具类，提供返回一个路径的辅助方法
* FileSystem：与文件系统交互的类
* FileSystems：工具类，提供各种方法。

Path不仅用于传统的文件系统，也能表示zip或jar这样的文件系统。

```java
//创建Path
Path listing = Paths.get("/user/bin/zip")；
//相当于
Path listing = FileSystems.getDefault().getPath("/user/bin/zip");

//获取Path信息：
listing.getFileName(): zip
listing.getNameCount(): 3
listing.subpath(0, 2): /user/bin
listing.getParent(): /user/bin
listing.getRoot(): /
```

如果Path是一个文件的路径，有时需要去除冗余信息。例如去除表示当前路径的`./`，或者该文件只是个符号链接，指向了另一个真正的位置，此时需要得到真实路径。

```java
//移除冗余
Path testPath = Paths.get("./test.java");
Path normalizedPath = testPath.normalize();

//获取绝对路径
Path absolutePath = testPath.toAbsolutePath();
//获取绝对路径并去除冗余信息，或者获取符号连接的真实路径
Path realPath = testPath.toRealPath();
```

合并路径与路径比较。

```java
//合并
Path prefix = Paths.get("/usr");
Path completePath = prefix.resolve("mxs");
//completePath: /usr/mxs

//比较
Path path1 = Paths.get("/Users/mxs/Documents/Blog/");
Path path2 = Paths.get("/Users/mxs");
path1.relativize(path2): ../..
path2.relativize(path1): Documents/Blog
```

新的API完全替换了java.io.File类，在处理遗留代码时，可能将其进行互换：

```java
File file = new File("../abcd.txt");
Path listing = file.toPath();
file = listing.toFile();
```

## 2. 处理目录与目录树
新的DirectoryStream<T>接口实现了目录相关的操作：

* 循环遍历目录中的子项
* 用glob表达式（如`*Foobar*`）进行目录子项的匹配和MIME内容检测（如text/xml文件）
* 用walkFileTree实现递归移动、复制和删除操作

**在目录中查找文件：**

```java
Path dir = Paths.get("/user/mxs/Documents");

try(DirectoryStream<Path> stream = Files.newDirectoryStream(dir, "*.properties")) {
	for(Path entry : stream){
		System.out.println(entry.getFileName());	
	}
} catch(IOException e) {
	//...
}
```

**遍历目录树。**Files.walkFileTree方法是遍历目录树的关键，该方法定义如下：

`Files.walkFileTree(Path startingDir, FileVisitor<? super Path> visitor);
`

其中Visitor是一个接口，包括5个方法，但一般使用Java的默认实现SimpleFileVisitor就可以了。

```java
public void walk() {
	Path dir = Paths.get("/code/src");
	Files.walkFileTree(dir, new FindJavaVisitor());
}

private static class FindJavaVisitor extends SimpleFileVisitor<Path> {
	@Override
	public FileVisitresult visitFile(Path file, BasicFileAttributes attrs) {
		if (file.toString().endsWith(".java")) {
			//...
		}
		
		return FileVisitResult.CONTINUE;
	}
}
```

需要注意的是，walkFileTree方法不会自动跟随符号链接（为了确保递归等操作的安全性）。因此如果你需要跟随符号链接，就需要检查相应属性并执行相应操作。

## 3. 文件系统I/O
在NIO.2中，Files和WatchService是两个重要的基础类。前者用于复制、移动、删除或处理文件，后者用于监视文件或目录，发出定制通知等。

### 3.1 创建和删除文件

```java
Path target = Paths.get("/Users/mxs/Document/mystuff.txt");
Path file = Files.createFile(target);
```

如果需要设置文件属性，如读、写和执行的权限，则需要设置FileAttribute，但文件属性与操作系统相关，因此要使用与操作系统相关的文件权限类。以下是POSIX文件系统的示例(其它文件系统参考java.nio.file.attribute.*FilePermission类)：

```java
Set<PosixFilePermission> perms = PosixFilePermissions.fromString("rw-rw-rw-");
FileAttribute<Set<PosixFilePermission>> attr = PosixFilePermissions.asFileAttribute(perms);
Files.createFile(target, attr);
```

删除文件只需要调用`Files.delete(target)`方法。

### 3.2 文件复制与移动
```java
Path source = Paths.get("c:\\My Documents\\stuff.txt");
Path target = Paths.get("D:\backup\stuff.txt");
Files.copy(source, target);

//复制时还可以设置CopyOptions选项（变参，可多个。ATOMIC_MOVE确保两边都成功，否则回滚）
import static java.nio.file.StandardCopyOption.*;
Files.copy(source, target, REPLACE_EXISTING, COPY_ATTRIBUTES, ATOMIC_MOVE); 

//移动
Files.move(source, target);
Files.move(source, target, CopyOptions);
```

### 3.3 文件属性
由于不同的文件系统属性不同，因此Java中的文件属性分为基本文件属性、特定文件属性。前者是各文件系统通用的文件属性。

```java
Path zip = Paths.get("/usr/bin/zip");
Files.getLastModifiedTime(zip);
Files.size(zip);
Files.isSymbolicLink(zip);
Files.isDirectory(zip);
Files.readAttributes(zip, "*"); //批量读取属性
```

特定文件属性独立于某个操作系统。以POSIX文件系统为例：

```java
//获取文件属性
PosixFileAttributes attrs = Files.readAttributes(zip, PosixFileAttributes.class);

//修改属性
Set<PosixFilePermission> permissions = attrs.permissions();
permissions.clear;
permissions.add(GROUP_READ);
//...
Files.setPosixFilePermissions(zip, permissions);
```

符号链接的处理：

```java
Path file = Paths.get("/opt/platform/java");
if (Files.isSymbolicLink(file)) {
	file = Files.readSymbolicLink(file);
}
//继续处理文件相关操作
Files.readAttributes(file, BasicFileAttributes.class);
```

### 3.4. 快速读写数据
Files工具类提供了更方便的方法来读写数据：

```java
Path logFile = Paths.get("/tmp/app.log");
try(BufferedReader reader = 
	Files.newBufferedReader(logFile, StandardCharsets.UTF_8)) {
	String line;
	while((line = reader.readLine()) != null) {
		//...
	}
}

//写入
try(BufferedWriter writer = 
	Files.newBufferedWrite(logFile, StandardCharsets.UTF_8, StandardOpenOption.WRITE)) //变参，可多个
{ 
	writer.write("Hello!");
}
```

Files工具类提供的方法还有`newInputStream()`, `newOutputStream()`等方法，用于配合现有IO类。还有更方便的方式：

```java
List<String> lines = Files.readAllLines(logFile, StandardCharsets.UTF_8);
byte[] bytes = Files.readAllBytes(logFile);
```

### 3.5. 文件修改通知
WatchService可用于监测文件或目录的变化，可监测的事件包括：ENTRY_CREATE, ENTRY_DELETE, OVERFLOW(事件已经丢弃或丢失)。

```java
import static java.nio.file.StandardWatchEventKinds.*;

try {
	WatchService watcher = FileSystems.getDefault().newWatchService();
	Path dir = FileSystems.getDefault().getPath("/usr/mxs");
	WatchKey key = dir.register(watcher, ENTRY_MODIFY);
	
	while(!shutdown ) { //一个标志，判断循环是否该结束
		key = watcher.take();
		for (WatchEvent<?> event: key.pollEvents()) {
			if (event.kind() == ENTRY_MODIFY) {
				//dir changed
			}
		}
		key.reset(); 
	}
} catch(IOException | InterruptedException e) {
	//...
}
```

### 3.6 SeekableByteChannel
这是Java 7引入的新接口，用于改变字节通道的位置和大小。例如用多个线程去分析一个大型日志文件的字节通道。FileChannel是这个接口的一种实现，下面的示例读取日志文件的最后1000个字符：

```java
Path logFile = Paths.get("c:\\temp.log");
ByteBuffer buffer = ByteBuffer.allocate(1024);
FileChannel channel = FileChannel.open(logFile, StandardOpenOption.READ);
channel.read(buffer, channel.size() - 1000);
```

## 4. 异步I/O操作
异步I/O操作主要有两种方式：Future和回调。Java 7提供了三个新的异步通道：

* AsynchronousFileChannel 用于文件I/O
* AsynchronousSocketChannel 用于Socket I/O, 支持超时
* AsynchronousServerSocketChannel 用于Socket接受异步连接

### 4.1 Future方式

```java
try {
	Path file = Paths.get("/usr/mxs/foobar.txt");
	AsynchronousFileChannel channel = AsynchronousFileChannel.open(file);
	
	//读取100 000字节
	ByteBuffer buffer = ByteBuffer.allocate(100_1000); 
	Future<Integer> result = channel.read(buffer, 0);//返回值为Integer
	
	//如果未结束
	while(! result.isDone()) {
		//...干点别的事。
	}
	
	//获取结果
	Integer byteRead = result.get();
} catch(IOException | ExecutionException | InterruptedException e) {
	//...
}
```

### 4.2 回调方式
CompletionHandler<V, A>是回调的接口。V表示结果类型，A是提供结果的附着对象。

```
try {
	Path file = Paths.get("/usr/mxs/foobar.txt");
	AsynchronousFileChannel channel = AsynchronousFileChannel.open(file);
	//读取100 000字节
	ByteBuffer buffer = ByteBuffer.allocate(100_1000); 
	
	channel.read(buffer, 0, buffer, new CompletionHandler<Integer, ByteBuffer>(){
		public void completed(Integer result, ByteBuffer attachment) {
			//完成时的回调方法
		}
		
		public void failed(Throwable exception, ByteBuffer attachment) {
			//失败时的回调方法
		}
	});
} catch(IOException e) {
	//...
}
```

## 5. Socket与Channel整合
NetworkChannel把Socket和Channel结合起来，更好地应对网络编程。而MulticastChannel则可以用于像BitTorrent这样的多播编程。





