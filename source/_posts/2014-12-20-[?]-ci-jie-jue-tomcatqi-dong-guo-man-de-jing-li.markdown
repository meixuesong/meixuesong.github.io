---
layout: post
title: "解决SecureRandom导致Tomcat启动过慢的问题"
date: 2014-12-20 12:08:33 +0800
comments: true
categories: 
- java
---

昨天晚上在Tomcat上部署一个小应用时，Tomcat启动非常慢，有时甚至需要10分钟。查看日志，发现一直停在Deploying阶段：

<!--more-->

```
INFO: Starting service Catalina
Dec 19, 2014 9:56:33 AM org.apache.catalina.core.StandardEngine startInternal
INFO: Starting Servlet Engine: Apache Tomcat/7.0.52 (Ubuntu)
Dec 19, 2014 9:56:33 AM org.apache.catalina.startup.HostConfig deployWAR
INFO: Deploying web application archive /usr/mxs/kindleinstance/webapps/kindlegen.war
```

难道是war文件有问题？检查了md5校验码，尝试了解压缩，完全没问题啊！到底是什么原因呢？等了十分钟后，发现Tomcat已经启动完成，可以使用了。再次查看日志：

```
INFO: Deploying web application archive /usr/mxs/kindleinstance/webapps/kindlegen.war
Dec 19, 2014 10:11:25 AM org.apache.catalina.util.SessionIdGenerator createSecureRandom
INFO: Creation of SecureRandom instance for session ID generation using [SHA1PRNG] took [888,934] milliseconds.
Dec 19, 2014 10:11:25 AM org.apache.coyote.AbstractProtocol start
INFO: Starting ProtocolHandler ["http-bio-9090"]
Dec 19, 2014 10:11:25 AM org.apache.catalina.startup.Catalina start
INFO: Server startup in 892334 ms
```

原来是“Creation of SecureRandom instance for session ID”消耗了888秒，这个SecureRandom实例是什么呢？在[How do I make Tomcat startup faster?](http://wiki.apache.org/tomcat/HowTo/FasterStartUp)中，有这样的描述：

>Tomcat 7+ heavily relies on SecureRandom class to provide random values for its session ids and in other places. Depending on your JRE it can cause delays during startup if entropy source that is used to initialize SecureRandom is short of entropy. 

也就是说，Tomcat 7之后严重依赖SecureRandom类来提供随机数用于Session ID。当Tomcat启动时，取决于你使用的JRE，如果用来初始化SecureRandom的熵值（Entropy）资源是一个短熵时，将可能导致延时。

再看看JDK中关于[SecureRandom类](http://docs.oracle.com/javase/7/docs/api/java/security/SecureRandom.html):

>This class provides a cryptographically strong random number generator (RNG). A cryptographically strong random number minimally complies with the statistical random number generator tests specified in FIPS 140-2, Security Requirements for Cryptographic Modules, section 4.9.1. Additionally, SecureRandom must produce non-deterministic output. Therefore any seed material passed to a SecureRandom object must be unpredictable, and all SecureRandom output sequences must be cryptographically strong, as described in RFC 1750: Randomness Recommendations for Security.

该类提供保密性强的随机数生成器（RNG）。一个保密性强的随机数应最低限度遵循FIPS 140-2指定的统计随机数发生器测试和4.9.1节的加密模块安全要求。并且SecureRandom必须产出非确定性的输出。因此，正如RFC 1750中描述的，传递给SecureRandom对象的任何材料必须是不可预测的，并且所有SecureRandom输出序列必须是保密性强的的。

在[ISSUES TO BE AWARE OF WHEN USING JAVA’S SECURERANDOM](http://www.cigital.com/justice-league-blog/2014/01/06/issues-when-using-java-securerandom/)中，提到了使用SecureRandom可能存在的问题，主要包括三个方面：调用顺序、阻塞和内部Seeding机制。其中说明了阻塞是如何产生的：

>Some SecureRandom implementations in the Oracle JRE for *nix use /dev/random to get entropy at certain times. Since /dev/random can block if sufficient entropy is not available, your code will stop executing if you call certain SecureRandom methods at times when /dev/random does not have sufficient entropy available.

这样看来，我的Ubuntu 14中的OpenJDK(OpenJDK Runtime Environment (IcedTea 2.5.3) (7u71-2.5.3-0ubuntu0.14.04.1))正是使用了操作系统的`/dev/random`作为信息源，而它又没有提供足够的熵，所以导致阻塞。

按照前文[How do I make Tomcat startup faster?](http://wiki.apache.org/tomcat/HowTo/FasterStartUp)中给出的次安全的解决办法，改为使用`-Djava.security.egd=file:/dev/./urandom`，即在setenv.sh中加入一行：

```
#!/bin/sh
export CATALINA_OPTS="-Djava.security.egd=file:/dev/./urandom"
```

然后再重启Tomcat，这次非常快了，整个启动只用了3秒多：

```
INFO: Starting service Catalina
Dec 19, 2014 10:51:55 PM org.apache.catalina.core.StandardEngine startInternal
INFO: Starting Servlet Engine: Apache Tomcat/7.0.52 (Ubuntu)
Dec 19, 2014 10:51:55 PM org.apache.catalina.startup.HostConfig deployWAR
INFO: Deploying web application archive /usr/mxs/kindleinstance/webapps/kindlegen.war
Dec 19, 2014 10:51:58 PM org.apache.coyote.AbstractProtocol start
INFO: Starting ProtocolHandler ["http-bio-9090"]
Dec 19, 2014 10:51:58 PM org.apache.catalina.startup.Catalina start
INFO: Server startup in 3418 ms
```

修改后的`/dev/urandom`没有默认的`dev/random`安全吗？似乎也不一定，博文[Myths about /dev/urandom](http://www.2uo.de/myths-about-urandom/)对两者进行了全面的分析，值得一看。最后作者认为用`/dev/urandom`就可以了。































