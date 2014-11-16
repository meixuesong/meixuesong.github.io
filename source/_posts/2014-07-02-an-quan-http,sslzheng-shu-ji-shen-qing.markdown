---
layout: post
title: "安全HTTP，SSL证书及申请"
date: 2014-07-02 08:34:08 +0800
comments: true
categories: 
- java

---

由于iOS 7.1无法安装企业应用的原因是url必须是https，因此需要将原Tomcat服务器增加SSL支持。总结一下基础知识和配置过程。

<!--more-->

HTTPS是位于安全层之上的HTTP，如下图所示：

![image](/myresource/images/img_blog_20140702_1.jpg)

##1.基础知识

数字加密的一些概念：

* 密码
* 密钥：改变密码行为的数字化参数。例如，加密算法是循环移位N个字符，那么密钥控制N的值。
* 对称密钥加密系统：加密和解密都使用相同的密钥。
* 不对称密钥加密系统：加密和解密都使用不同的密钥。
* 公开密钥加密系统：一种能够使数百万计算机便捷发送机密报文的系统。
* 数字签名：用加密系统对报文进行签名，说明是谁编写的报文，同时证明报文未被篡改。
* 数字证书：由受信任组织提供的身份证明。

###1.1对称密钥加密技术

常见的对称密钥加密算法包括：DES、Triple-DES、RC2和RC4。

它们的编、解码算法都是公开的，因此密钥是唯一保密的东西。可用密钥值的数量取决于位数。位数越长则破解难度越大。下表是书中列举的，以1995年的技术进行破解的成本：

![image](/myresource/images/img_blog_20140702_3.jpg)

对称密钥加密技术的缺点之一是发送和接收者在对话之前，一定要有一个共享的保密密钥。如果在Internet上，Web服务器要与每个用户的浏览器进行安全对话，采用这种加密技术将是一个噩梦。

###1.2公开密钥加密技术

公开密钥加密技术使用两个非对称密钥：一个用来编码，另一个用来解码。编码密钥是公开的，而解码密钥只有主机自己知道。因此所有用户都可以拥有某个主机的编码密钥，当他向主机发送报文时，使用该主机的公钥进行编码，主机使用自己的解码密钥进行解码。

公开密钥架构（Public-Key Infrastructure, PKI）标准，用于标准化公开密钥技术包。

RSA算法是一个公开密钥加密算法。由麻省理工学院发明，RSA公司将其商业化。

###1.3数字签名

签名就是为了说明谁编写的报名，并证明其未被篡改过。它是加了密的校验和。下图展示了从节点A向节点B发送一条报文的过程：

![image](/myresource/images/img_blog_20140702_3.jpg)

节点A对报文提取为定长摘要，将对摘要使用“签名”函数，这个函数接收用户的私有密钥作为参数。计算出签名后，将其附加在报文的末尾，一同发给B。

节点B如何确定报文确实是A写的，而且没被篡改过？B使用公开密钥的反函数，确认拆包后的摘要与自己的摘要版本一致。

[百度百科](http://baike.baidu.com/view/7626.htm?fr=aladdin)关于签名过程的描述：

> 发送报文时，发送方用一个哈希函数从报文文本中生成报文摘要,然后用自己的私人密钥对这个摘要进行加密，这个加密后的摘要将作为报文的数字签名和报文一起发送给接收方，接收方首先用与发送方一样的哈希函数从接收到的原始报文中计算出报文摘要，接着再用发送方的公用密钥来对报文附加的数字签名进行解密，如果这两个摘要相同、那么接收方就能确认该数字签名是发送方的。

###1.4数字证书

数字证书就是互联网通讯中标志通讯各方身份信息的一串数字，提供了一种在Internet上验证通信实体身份的方式，其作用类似于司机的驾驶执照或日常生活中的身份证。它是由一个由权威机构——CA机构，又称为证书授权（Certificate Authority）中心发行的，人们可以在网上用它来识别对方的身份。数字证书是一个经证书授权中心数字签名的包含公开密钥拥有者信息以及公开密钥的文件。最简单的证书包含一个公开密钥、名称以及证书授权中心的数字签名。

证书的主要内容包括：对象的名称（人、服务器、组织等）、过期时间、证书发布者和来自证书发布者的数字签名。

证书的格式没有全球标准，但大多数以X.509 v3作为标准格式。

#### 服务器证书（SSL证书）

在服务器上安装服务器证书后，客户端浏览器可以与服务器证书建立SSL连接，在SSL连接上传输的任何数据都会被加密。同时，浏览器会自动验证服务器证书是否有效，验证所访问的站点是否是假冒站点，服务器证书保护的站点多被用来进行密码登录、订单处理、网上银行交易等。全球知名的服务器证书品牌有Globlesign，Verisign，Thawte，Geotrust等。

SSL支持双向认证。将服务器证书承载回客户端，再将客户端的证书回送给服务器。但目前，大部分用户都没有自己的客户端证书，所以服务器很少会要求客户端证书。

##2.为Tomcat安装SSL证书

###2.1申请SSL证书

建议使用[StartSSL](https://www.startssl.com/)申请一个SSL证书，可以使用一年期免费的证书。必须使用域名！过程主要包括：

* 在StartSSL上注册（Sign-up）。所填资料应是真实的，或者至少看起来是真的。
* 注册成功后会下载个证书，要导入到浏览器中。
* 然后就可以进入StartSSL的控制面板了。
* 验证完Email地址和域名所有权后，申请证书。
* 按照StartSSL的向导，申请完证书后，本地应该有这么几个文件：

![image](/myresource/images/img_blog_20140702_5.png)

###2.2Tomcat安装SSL证书

首先要创建pkcs12文件，使用StartSSL ToolBox中的Create PKCS#12 (PFX) File。其中Private Key就是ssl.key的内容，而Certificate则是ssl.crt的内容。创建完后将其保存为out.p12

第二步是生成Keystore文件。利用java的keytool工具：

```
//XXXXXX为密码
keytool -importkeystore -deststorepass  XXXXXX -destkeystore mykeystore.jks -srckeystore out.p12 -srcstoretype PKCS12 -srcstorepass XXXXXX
```

第三步，导入CA证书：

```
keytool -import -alias startsslca -file a.class1.server.ca.pem -keystore mykeystore.jks
```

最后一步，配置Tomcat，修改server.xml，将8443端口取消注释：

```xml
<Connector port="8443" protocol="HTTP/1.1" 
	SSLEnabled="true" maxThreads="150" 
	scheme="https" secure="true" 
	clientAuth="false" sslProtocol="TLS" 
	keystoreFile="/Users/mxs/mykeystore.jks" 
	keystorePass="XXXXXX"/> <!--XXXXXX是密码-->
```

如果启动时报apr错误，可修改server.xml，加上注释：

```xml
<!--<Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />-->
```

##文件类型说明

PKCS#12是“个人信息交换语法”，常用的后缀有.P12 .PFX。它可以用来将x.509的证书和证书对应的私钥打包，进行交换。比如你在windows下，可以将IE里的证书连带私钥导出，并设置一个口令保护。这个pfx格式的文件，就是按照pkcs#12的格式打包的。当然pkcs#12不仅仅只是作以上用途的。它可以用来打包交换任何信息。你可以和张三李四用PKCS#12来交换私人数据，包括x.509证书和私钥。

.CRT  扩展名CRT用于证书。证书可以是二进制的DER编码，也可以是文本的PEM编码。扩展名CER和CRT几乎是同义词。这种情况在各种unix/linux系统中很常见。

.CER  CRT证书的微软型式。可以用微软的工具把CRT文件转换为CER文件（CRT和CER必须是相同编码的，DER或者PEM）。扩展名为CER的文件可以被IE识别并作为命令调用微软的cryptoAPI（具体点就是rudll32.exe cryptext.dll, CyrptExtOpenCER），进而弹出一个对话框来导入并/或查看证书内容。

.KEY  扩展名KEY用于PCSK#8的公钥和私钥。这些公钥和私钥可以是DER编码或者PEM编码。本文中的ssl.key，以文本方式打开可以看到第一行是：-----BEGIN RSA PRIVATE KEY-----表示私钥。在StartSSL的向导中，先生成的是加密的key，然后使用命令：openssl rsa -in ssl.key -out ssl.key 将其解密。

##参考：

《HTTP权威指南》
[百度百科](http://baike.baidu.com/view/7626.htm?fr=aladdin)
[博客1](http://fengfan.blog.163.com/blog/static/13478622013713114942896/)
[博客2](http://blog.csdn.net/googling/article/details/6698255)