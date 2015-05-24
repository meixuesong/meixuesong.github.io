---
layout: post
title: "设计模式在序列生成器的应用"
date: 2014-07-28 22:21:23 +0800
comments: true
toc: true
categories: 
- 设计模式
---

序列生成器是常见的一个应用组件。Oracle数据库有Sequence，但不是所有数据库都有序列。本文尝试将单例模式、多例模式应用于序列生成器。采用了以下方式实现：

1. 没有数据库的单例实现
2. 有数据库的单例实现
3. 有缓存的单例实现
4. 有缓存的多序列实现
5. 多序列的多例实现。

<!--more-->

## 1. 没有数据库的单例实现
当没有数据库时，使用单例实现序列生成器非常简单，示例代码如下，注意`synchronized`关键字：

```java
/**
 * 没有数据库的序列键生成器
 * @author mxs
 *
 */
public class KeyGenerator {	
	private long key = 0;
	private static KeyGenerator instance = new KeyGenerator();
	
	private KeyGenerator() {}
	
	public static KeyGenerator getInstance() {
		return instance;
	}
	
	public synchronized long getNextKey() {
		return key++;
	}
}
```

单元测试代码：

```java
public class KeyGeneratorTest extends TestCase {
	public void testKey() {
		KeyGenerator keyGenerator = KeyGenerator.getInstance();
		
		for(int i = 0; i < 100; i++) {
			Assert.assertEquals(i, keyGenerator.getNextKey());
		}
	}
}
```

这种实现没有持久化，一旦重启，序列又从0开始。因此我们需要一个有数据库持久化的方案。

## 2. 有数据库的单例实现
当有数据库时，每次获取序列都从数据库读取。

```java
/**
 * 有数据库的序列键生成器
 * @author mxs
 *
 */
public class KeyGenerator {	
	private static KeyGenerator instance = new KeyGenerator();
	
	private KeyGenerator() {}
	
	public static KeyGenerator getInstance() {
		return instance;
	}
	
	public synchronized long getNextKey() {
		return getNextKeyFromDB();
	}
	
	private long getNextKeyFromDB() {
		//update t_sequence set seq_value = seq_value + 1
		//select seq_value from t_sequence
		//返回结果
		return 1000;
	}
}

```

## 3. 有缓存的单例实现
第2种方法每次都要访问数据库，影响了性能，可以一次多取一些序列放到缓存中，只有缓存都取完时，才访问数据库。

```java
/**
 * 有数据库、带缓存的序列键生成器
 * @author mxs
 *
 */
public class KeyGenerator {	
	private static KeyGenerator instance = new KeyGenerator();
	private static final int cacheSize = 20;
	private KeyInfo keyInfo;
	
	private KeyGenerator() {
		keyInfo = new KeyInfo(cacheSize);
	}
	
	public static KeyGenerator getInstance() {
		return instance;
	}
	
	public synchronized long getNextKey() {
		return keyInfo.getNext();
	}
}


public class KeyInfo {
	private long max;
	private long min;
	private long nextKey;
	private int poolSize;

	public KeyInfo(int poolSize) {
		this.poolSize = poolSize;
		retrieveFromDB();
	}

	public long getNext() {
		if (nextKey >= max) {
			retrieveFromDB();
		}

		return nextKey++;
	}

	private void retrieveFromDB() {
		// update t_sequence set seq_value = seq_value + poolSize
		// select seq_value from t_sequence
		//以下为模拟数据库操作
		long value = dbvalue[dbIndex ++];
		min = value - poolSize;
		max = value;
		nextKey = min;
	}
	
	private int[] dbvalue = {20, 40, 60, 80, 100};
	private int dbIndex = 0;
}

```

## 4. 有缓存的多序列实现
要实现多序列，只需要用HashMap改造第3种方法，保持KeyInfo不变，KeyGenerator修改为：

```java
/**
 * 有数据库、带缓存的多序列键生成器
 * @author mxs
 *
 */
public class KeyGenerator {	
	private static KeyGenerator instance = new KeyGenerator();
	private static final int cacheSize = 20;
	
	private Map<String, KeyInfo> map;
	
	private KeyGenerator() {
		map = new HashMap<String, KeyInfo>();
	}
	
	public static KeyGenerator getInstance() {
		return instance;
	}
	
	public synchronized long getNextKey(String key) {
		KeyInfo keyInfo;
		if (map.containsKey(key)) {
			keyInfo = map.get(key);
		} else {
			keyInfo = new KeyInfo(cacheSize);
			map.put(key, keyInfo);
		}
				
		return keyInfo.getNext();
	}
}
```

## 5. 多序列的多例实现
前面所有实现方案都是基于单例模式，其实还可以使用多例模式。多例模式允许一个类有多个实例，这些实例有自己的状态。保持KeyInfo不变，KeyGenerator修改为：

```java
/**
 * 有数据库、带缓存的多序列键生成器，采用多例模式
 * @author mxs
 *
 */
public class KeyGenerator {	
	private static final int cacheSize = 20;
	private KeyInfo keyInfo;
	private static Map<String, KeyGenerator> instances = new HashMap<String, KeyGenerator>(10);
	
	private KeyGenerator() {
		keyInfo = new KeyInfo(cacheSize);
	}
	
	public static synchronized KeyGenerator getInstance(String key) {
		if (! instances.containsKey(key)) {
			KeyGenerator generator = new KeyGenerator();
			instances.put(key, generator);
		}
		
		return instances.get(key);
	}
	
	public synchronized long getNextKey() {
		return keyInfo.getNext();
	}
}

//测试代码：
public class KeyGeneratorTest extends TestCase {
	public void testKey() {
		for(int j = 0; j < 10; j ++) {
			String key = "" + j;
			KeyGenerator keyGenerator = KeyGenerator.getInstance(key);
			for(int i = 0; i < 90; i++) {
				long ii = keyGenerator.getNextKey();
				Assert.assertEquals(i, ii);
			}
		}		
	}
}

```


参考：
Java与模式
