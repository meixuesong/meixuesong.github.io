---
layout: post
title: "Java随机存取文件"
date: 2014-06-26 21:56:12 +0800
comments: true
toc: true
categories: 
- Java
---

RandomAccessFile提供了随机存取文件的支持，但是如何将对象持久化到文件中，并随机存取呢？

<!--more-->

###1.简介

使用RandomAccessFile随机存取文件。它提供了4种模式：

* r 只读；
* rw 读写，如果不存在将创建新文件；
* rws 同步更新，确保文件内容和元数据（如最近修改时间）持久化；
* rwd 同步更新，确保文件内容持久化。

常用方法：

* seek快速移动文件指针；
* getFilePointer返回当前指针位置；
* length文件总字节数；
* 一堆read和write方法。

###2.写入对象

RandomAccessFile并不支持保存对象，需要将它们转换成字节数组。

```java
    private byte[] getBytes(Object object) throws IOException {
        ByteArrayOutputStream byteStream = new ByteArrayOutputStream();
        //写入ObjectOutputStream的对象，被管接到ByteArrayOutputStream
        ObjectOutputStream outputStream = new ObjectOutputStream(byteStream);
        outputStream.writeObject(object);
        outputStream.flush();
        
        return byteStream.toByteArray();
    }
```

写入代码：

```java
    RandomAccessFile db = new RandomAccessFile(new File(fileName), "rw");

    //在文件最后写入对象
    db.seek(db.length());
    byte[] bytes = getBytes(someObject);
    db.write(bytes, 0, bytes.length);
        
    db.close();

```

###3.读取对象

读取对象与写入对象正好相反。以适当的长度创建字节数组，然后调用readFully从RandomAccessFile读取并填充，再包装到ObjectInputStream。

下面的示例代码读取指定长度（通常需要记录对象的长度，此处略去）的字节并转换成对象：

```java

    private Object read(RandomAccessFile db, int length) throws IOException {
        byte[] bytes = new byte[length];
        db.readFully(bytes);
        
        return readObject(bytes);
    }
    
    private Object readObject(byte[] bytes) throws IOException {
        ObjectInputStream input = new ObjectInputStream(new ByteArrayInputStream(bytes));
        try {
            try {
                return input.readObject();
            } catch (ClassNotFoundException unlikely) {
                return null;
            }
        } finally {
            input.close();
        }
    }

```

[参考Java Doc](http://docs.oracle.com/javase/7/docs/api/java/io/RandomAccessFile.html)



