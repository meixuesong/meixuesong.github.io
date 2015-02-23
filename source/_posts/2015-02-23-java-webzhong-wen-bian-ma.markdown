---
layout: post
title: "Java Web中文编码"
date: 2015-02-23 15:57:18 +0800
comments: true
categories: 
- java
---

介绍常见的编码格式，以及Java Web和JavaScript相关的字符集编码。

<!--more-->

## 1. 常见的编码格式

编码 | 说明
---|---
ASCII | 共128个，用1个字节表示。0～31为控制字符，如换行、回车等。32～126为打印字符。
ISO-8859-1 | 扩展ASCII编码，仍然是单字节，共256个字符。
GB2312 | 双字节编码，A1~A9是符号区，共682个符号；B0~F7是汉字区，共6763个汉字
GBK | 为Win95所制定的汉字内码规范，扩展GB2312，与GB2312兼容，能表示21003个汉字。
GB18030 | 可能是单字节、双字节或者四字节编码，与GB2312兼容。虽然是国家标准，但未广泛使用。
UTF-16 | 定义了Unicode字符在计算机中的存取方法。Unicode是ISO试图创建一个全新的超语言字典，世界上所有语言都可以通过这个字典相互翻译。Unicode是Java和XML的基础。UTF-16用两个字节来表示Unicode的转化格式，采用定长的表示方法。
UTF-8 | 避免UTF-16的空间浪费，采用变长技术，每个编码区域有不同的字码长度。不同类型的字符可以由1～6个字节组成。

UTF-8的编码规则：

* 如果是1个字节，最高位（第8位）为0，表示1个ASCII字符。
* 如果是1个字节，以11开着，则连续的1的个数表示这个字符的字节数。例如110xxxxx表示它是双字节UTF-8字符的首字节。
* 如果1个字节，以10开始，表示它不是首字节，需要向前查找才能得到当前字符的首字节。

## 2. Java中的编码场景
### 2.1 在I/O中编码
在磁盘和网络I/O中，都涉及字节与字符的转换。Reader类是Java的I/O中读字符的父类，而InputStream类是读字节的父类。两者之间的转换由StreamDecoder和StreamEncoder完成。在编、解码过程中必须指定Charset，否则使用本地环境默认字符集，如中文环境使用GBK。

在实际开发过程中，只要保持编码的一致就不会造成乱码：

```java
String charset = "UTF-8";
String file = "c:/stream.txt";

FileOutputStream fos = new FieOutputStream(file);
OutputStreamWriter writer = new OutputStreamWriter(fos, charset);

...
InputStreamReader reader = new InputStreamReader(inputStream, charset);
```

### 2.2 在内存中编码
String类提供了字符和字节的转换方法：

```java
String s= "这是一段中文";
byte[] b = s.getBytes("UTF-8");
String n = new String(b, "UTF-8");
```		

另一种方法是使用Charset类：

```java
Charset charset = Charset.forName("UTF-8");
ByteBuffer byteBuffer = charset.encode("abcd");
CharBuffer charBuffer = charset.decode(byteBuffer);
```	

## 3. Java Web中的编解码
用户从浏览器发起一个HTTP请求，需要编码的地方包括URL、Cookie和Parameter。

### 3.1 URL的编解码
URL `http://localhost:8080/examples/servlets/servlet/books?author=jason` 可分解为：

* URI: `/examples/servlets/servlet/books`
* schema: http
* domain: localhost
* port: 8080
* contextPath: examples
* servletPath: servlets/servlet
* PathInfo: books
* QueryString: author=jason

对于Tomcat，对URL的URI部分进行解码的字符集是在Connector中定义的。如果没有定义，那么默认为ISO-8859-1。QueryString的解码字符集要么是Header中ContentType定义的Charset，要么是默认的ISO-8859-1。要使用ContentType定义的编码，需要设置Connector。因此Tomcat一般会设置：

`<Connector URIEncoding="UTF-8" useBodyEncodingForURI="true" />`

### 3.2 HTTP Header的编解码
除了URL外，还可能在Header中传递其它参数，如Cookie、redirectPath等。不要在Header中传递非ASCII字符，如果一定要传递，可以先用URLEncoder编码，再添加到Header中。

### 3.3 其它编解码
POST表单也是通过ContentType的Charset编码。用JDBC来存取数据时要和数据的内置编码保持一致，可以通过设置JDBC URL来指定，如MySQL: url="jdbc:mysql://localhost:3306/DB?useUnicode=true&characterEncoding=GBK"。

## 4. Javascript中的编码问题
如果Javascript文件的编码格式与当前页面不一致，需要指定字符集，否则可能出现乱码：`<script src="abc.js" charset="gbk"/>`。在Javascript中处理URL可以使用`encodeURI()`和`encodeURIComponent()`。后者编码得更彻底，除了`!`、`'`、`(`、`)`、`*`、`-`、`.`、`_`、`~`、`0-9`、`a-z`和`A-Z`之外，对其他所有字符都编码，因此通常用于将一个URL当作一个参数放在另一个URL中。





