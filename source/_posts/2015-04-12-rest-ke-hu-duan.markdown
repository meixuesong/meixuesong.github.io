---
layout: post
title: "REST 客户端"
date: 2015-04-12 17:02:39 +0800
comments: true
categories: 
- java
---

JAX-RS 2.0对客户端API进行了标准化。客户端API通过HTTP请求Web资源，同样符合统一接口和REST架构风格。与Apache HTTP Client和HttpURLConnection相比，客户端API具备对REST感知的高层API，可以和Providers集成，返回值直接对应高层的业务类实例。

<!--more-->

## 1. 客户端接口
REST客户端主要包括三个接口：javax.ws.rs.client.Client、javax.ws.rs.client.WebTarget和javax.ws.rs.client.Invocation。

### 1.1 Client接口
Client内部要管理客户端通信底层实现所需的各种对象，**它是一个重量级的对象，应该尽量少地构造Client实例**。**此外接口要求其实例要有关闭连接的保障，否则会造成内存泄露**。

Jersey对Client接口的实现类是JerseyClient。通常使用构造模式，使用ClientBuilder创建实例。示例如下：

```java
ClientConfig clientConfig = new ClientConfig();
//注册Provider
clientConfig.register(MyProvider.class);
//注册Feature
clientConfig.register(MyFeature.class);
//注册Filter
clientConfig.register(new AnotherClientFilter());
//创建Client
Client client = ClientBuilder.newClient(clientConfig);
//通过property设置相关属性
client.property("MyProperty", "MyValue");

//配置完毕后，可以通过getConfiguration()获取配置信息
Configuration configuration = client.getConfiguration();
Map<String, Object> properties = configuration.getProperties();
Iterator<Entry<String, Object>> it = properties.entrySet().iterator();
...
```

Client接口还提供了对客户端的安全连接和异步支持。

### 1.2 WebTarget接口
WebTarget接口为REST客户端实现资源定位，可以定义请求资源的地址、查询参数和媒体类型等信息。Jersey中的WebTarget接口实现类是JerseyWebTarget。

WebTarget对象接收配置参数的方法是通过方法链，采用不变模式完成。如果分开写每次都返回一个新的WebTarget对象，如果不将其覆值会造成信息丢失。

```java
WebTarget webTarget = client.target(BASE_URI);
webTarget.path("books").path("book").queryParam("bookId", "1");
```

### 1.3 Invocation接口
当WebTarget接口完成资源定位后，Invocation接口向REST服务端发起请求。请求包括同步和异步方式，由Invocation接口内部的Builder接口定义。Jersey中的Invocation接口实现类是JerseyInvocation。

```java
final Invocation.Builder invocationBuilder = webTarget.request();

//以多种方式请求数据
final Book book = invocationBuilder.get(Book.class);
Response response = invocationBuilder.post(userEntity);
invocationBuilder.put(userEntity);
```

JAX-RS 2.0的REST框架无需开发者编码实现对客户端实例的资源管理，Response实例的readEntity()在返回响应实体的同时，就完成了对客户端资源的释放。


## 2. Connector
Connector接口是REST客户端底层连接器接口，Jersey提供了4个实现：

* HttpUrlConnector REST客户端的默认连接器
* ApacheConnector
* GrizzlyConnector
* InMemoryConnector 不是真实的HTTP连接器，而是使用JVM调用来模拟HTTP请求访问。

### 2.1 默认连接器
默认情况下，Jersey的Client初始化时会构造一个HttpUrlConnector实例作为连接器。

### 2.2 Apache连接器
ApacheConnector是基于Apache HTTP Client的连接器实现，比默认连接器功能更完整。可以实现代理服务器设置、超时设置。示例如下：

```java
final ClientConfig clientConfig = new ClientConfig();

//代理服务器配置
clientConfig.property(ApacheClientProperties.PROXY_URI, "http://192.168.0.100");
clientConfig.property(ApacheClientProperties.PROXY_USERNAME, "user");
clientConfig.property(ApacheClientProperties.PROXY_PASSWORD , "pwd");
//连接超时配置
clientConfig.property(ClientProperties.CONNECT_TIMEOUT, 1000);
//读取超时配置，指连接和资源定位成功后，客户端接收服务响应的最长时间
clientConfig.property(ClientProperties.READ_TIMEOUT, 2000);

clientConfig.connectorProvider(new ApacheConnectorProvider());
client = ClientBuilder.newClient(clientConfig);
```        

### 2.3 Grizzly连接器
GrizzlyConnector是Grizzly提供的连接器实现，内部使用异步处理客户端com.ning.http.client.AsyncHttpClient类作为底层的连接。

```java
final ClientConfig clientConfig = new ClientConfig();
clientConfig.property("TestKey", "TestValue");

clientConfig.connectorProvider(new GrizzlyConnectorProvider());
Client client = ClientBuilder.newClient(clientConfig);
```

### 2.4 HTTP连接池
既然Client是一个重型组件，因此频繁地创建Client实例会影响总体性能。一种常见的解决方案是使用HTTP连接池来管理连接。下例使用ApacheConnector来实现HTTP连接池：

```java
final ClientConfig clientConfig = new ClientConfig();
final PoolingHttpClientConnectionManager cm = new PoolingHttpClientConnectionManager();
//设置最大连接数
cm.setMaxTotal(20000);
//设置每条路由的默认最大连接数
cm.setDefaultMaxPerRoute(10000);
clientConfig.property(ApacheClientProperties.CONNECTION_MANAGER, cm);

clientConfig.connectorProvider(new ApacheConnectorProvider());
client = ClientBuilder.newClient(clientConfig);
```        

## 后记
通常REST式的Web服务会按模块分别提供独立的Web服务，而模块之间的调用通过Web服务的REST API来实现。也就是说每个模块对其他模块的调用就是客户端请求。为了避免每次请求时重复编写构造客户端实例的代码，可以封装Client到公共模块，减少代码冗余。

参考：《Java RESTful Web Service实战》