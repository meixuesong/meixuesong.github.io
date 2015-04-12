---
layout: post
title: "JAX-RS 2.0 REST 请求处理"
date: 2015-04-12 09:57:39 +0800
comments: true
categories: 
- java
---

本章学习REST请求的完整处理过程，其中涉及JAX-RS 2.0定义的Provider及其两个特殊类型：过滤器和拦截器。

<!--more-->

REST风格的框架都从容器级别支持AOP式开发，Jersey内置AOP支持，可以不依赖于Spring等AOP框架。Jersey的AOP功能来自GlassFish的HK2项目（轻量级DI架构，jersey-common依赖HK2），它包括hk2-api和hk2-locator。hk2-locator致力于AOP方向。

Jersey提供的REST过滤器和拦截器为开发者提供了方便的扩展点，开发者无须像在Spring中为了某个类的方法进行AOP扩展而写配置文件。Jersey中只要实现相应扩展点的接口，即可实现REST请求流程中特定事件的拦截、扩展。

## 1. Providers详解
javax.ws.rs.ext.Providers是JAX-RS 2.0定义的一个辅助接口，其实现类用于完成过滤和读写拦截功能。@Provider标注的实现类，可以在运行时自动探测、加载。Provider实例可以通过@Context注解被依赖注入到其他实例中。Providers接口定义了4个方法，分别用来获取MessageBodyReader、MessageBodyWriter、ExceptionMapper和ContextResolver实例。

### 1.1 实体Providers
Jersey之所以可以支持多种响应实体的传输格式，是因为其底层实体Providers具备对不同格式的处理能力。它内部提供了丰富的MessageBodyReader和MessageBodyWriter接口实现类，用于处理不同的格式。

#### 1.1.1 MessageBodyReader
`MessageBodyReader<T>`用于将传输流转换成Java类型的对象。泛型类型即是该实现类所支持的转换类型。业务系统启用该实现类有两种方式：一是使用@Provider定义实现类，启动时自动加载；二是通过编码注册到Application类或子类中。

`MessageBodyReader<T>`接口定义了两个方法：

* isReadable() 判断实现类是否支持将当前请求的数据类型反序列化。
* readFrom() 反序列化处理，将流转换为Java类型对象。

#### 1.1.2 MessageBodyWriter
`MessageBodyWriter<T>`接口用于将Java类型对象转换成流，完成序列化过程。与MessageBodyReader类似，它也有两个对应的方法：isWriteable()和writeTo()。

#### 1.1.3 MessageBodyWorkers
MessageBodyReader和MessageBodyWriter的实现类非常多，选择哪个实现类处理当前请求的算法非常繁重，MessageBodyWorkers就是用于抽象这一遴选工作。它的实现类可以通过@Context依赖注入到使用MessageBodyWorkers的类中。MessageBodyFactory是MessageBodyWorkers接口的实现类。

### 1.2 上下文Providers
`ContextResolver<T>`接口是用于提供资源类和其他Provider上下文信息的接口，它定义了getContext()方法，参数为表述对象的类型(响应实体的传输格式)，输出是上下文泛型。

## 2. REST请求流程
一个请求始于请求的发送，止于调用Response类的readEntity()方法，获取响应实体。整个流程如下图所示：

![image](/myresource/images/image_blog_-2015-04-12_jerseyrest.jpg)

1. 客户端接收请求，进入扩展点ClientRequestFilter实现类的filter()方法。
2. 第二个扩展点：客户端写拦截器WriterInterceptor实现类的aroundWriteTo()方法，实现对客户端序列化操作的拦截。
3. 客户端消息体写处理器MessageBodyWriter执行序列化，过渡到服务端。
4. 进入第三个扩展点：服务器前置请求过滤器ContainerRequestFilter实现类的filter()方法。
5. 过滤处理完毕后，找到匹配资源方法。
6. 进入第四个扩展点：服务器后置请求过滤器ContainerRequestFilter实现类的filter()方法。
7. 服务器消息体读处理器MessageBodyReader完成数据流的反序列化。
8. 执行资源方法。
9. 进入第六个扩展点：服务器响应过滤器ContainerResponseFilter实现类的filter()方法。
10. 进入第七个扩展点：服务器写拦截器WriterInterceptor实现类的aroundWriteTo()方法，实现对服务端序列化到客户端这个操作的拦截。
11. 服务器消息体写处理器MessageBodyWriter执行序列化。流程返回客户端。
12. 客户端接收响应，进入第八个扩展点：客户端响应过滤器ClientResponseFilter实现类的filter方法。
13. 客户端响应实例response返回到用户侧，用户执行response.readEntity()，进入第九个扩展点：客户端读拦截器ReaderInterceptor实现类的aroundReadFrom()方法，对客户端反序列化进行拦截。
14. 客户端消息体读处理器MessageBodyReader执行反序列化，将Java类型的对象最终作为readEntity()方法的返回值。

## 3. REST过滤器
在上面的流程中，JAX-RS 2.0定义了4种过滤器扩展点接口，供开发者实现业务逻辑，先后为：

* ClientRequestFilter
* ContainerRequestFilter
* ContainerResponseFilter
* ClientResponseFilter

### 3.1 ClientRequestFilter
通常可以通过filter()方法的参数ClientRequestContext获取请求方法(getMethod)、获取请求资源地址(getUri)和获取请求头信息（getHeaders）等。利用这些信息覆写该方法以实现过滤功能。示例如下：

```java
@Override
public filter(ClientRequestContext rc) throws IOException {
	if (!rc.getHeaders().containsKey(HttpHeaders.AUTHORIZATION)) {
	  rc.getHeaders().add(HttpHeaders.AUTHORIZATION, authentication);
	}
}
```

### 3.2 ContainerRequestFilter
该接口的实现类可以定义为前置处理和后置处理。分别对应服务器处理接收到的请求之前和之后执行过滤。如果希望实现前置处理，要在类名上定义注解@PreMatching。该接口的filter(ContainerRequestContext tx)与Client类似。

### 3.3 ContainerResponseFilter
该接口定义的过滤方法：void filter(ContainerRequestContext request, ContainerResponseContext response)。

### 3.4 ClientResponseFilter
该接口定义的过滤方法：void filter(ClientRequestContext requestContext, ClientResponseContext responseContext).

### 3.5 过滤器示例
下面的示例用于实现访问日志功能。

```java
//pugm4wh阶段的filter
@PreMatching
public class AirLogFilter implements ContainerRequestFilter, 
		ClientRequestFilter, ContainerResponseFilter, 
		ClientResponseFilter {
    private static final Logger LOGGER = Logger.getLogger(AirLogFilter.class);
    private static final String NOTIFICATION_PREFIX = "* ";
    private static final String SERVER_REQUEST = "> ";
    private static final String SERVER_RESPONSE = "< ";
    private static final String CLIENT_REQUEST = "/ ";
    private static final String CLIENT_RESPONSE = "\\ ";
    private static final AtomicLong logSequence = new AtomicLong(0);

    @Override
    public void filter(ClientRequestContext context) throws IOException {
        long id = logSequence.incrementAndGet();
        StringBuilder b = new StringBuilder();
		//获取请求方法和地址
        printRequestLine(CLIENT_REQUEST, b, id, 
			context.getMethod(), context.getUri());
		//获取请求头信息
        printPrefixedHeaders(CLIENT_REQUEST, b, id, 
			/*HeadersFactory*/HeaderUtils.asStringHeaders(context.getHeaders()));
        LOGGER.info(b.toString());
    }

    @Override
    public void filter(ClientRequestContext requestContext, 
		ClientResponseContext responseContext) throws IOException {
        long id = logSequence.incrementAndGet();
        StringBuilder b = new StringBuilder();
        printResponseLine(CLIENT_RESPONSE, b, id, responseContext.getStatus());
        printPrefixedHeaders(CLIENT_RESPONSE, b, id, responseContext.getHeaders());
        LOGGER.info(b.toString());
    }

    @Override
    public void filter(ContainerRequestContext context) throws IOException {
        long id = logSequence.incrementAndGet();
        StringBuilder b = new StringBuilder();
        printRequestLine(SERVER_REQUEST, b, id,
			 context.getMethod(), context.getUriInfo().getRequestUri());
        printPrefixedHeaders(SERVER_REQUEST, b, id, context.getHeaders());
        LOGGER.info(b.toString());
    }

    @Override
    public void filter(ContainerRequestContext requestContext, 
		ContainerResponseContext responseContext) throws IOException {
        long id = logSequence.incrementAndGet();
        StringBuilder b = new StringBuilder();
		//获取容器响应状态
        printResponseLine(SERVER_RESPONSE, b, id, responseContext.getStatus());
        printPrefixedHeaders(SERVER_RESPONSE, b, id, 
			/*HeadersFactory*/HeaderUtils.asStringHeaders(responseContext.getHeaders()));
        LOGGER.info(b.toString());
    }

    private StringBuilder prefixId(StringBuilder b, long id) {
        b.append(Long.toString(id)).append(" ");
        return b;
    }

    private void printRequestLine(final String prefix, 
			StringBuilder b, long id, String method, URI uri) {
        prefixId(b, id).append(NOTIFICATION_PREFIX)
			.append("AirLog - Request received on thread ")
			.append(Thread.currentThread().getName()).append("\n");
        prefixId(b, id).append(prefix).append(method)
			.append(" ").append(uri.toASCIIString()).append("\n");
    }

    private void printResponseLine(final String prefix, 
		StringBuilder b, long id, int status) {
        prefixId(b, id).append(NOTIFICATION_PREFIX)
			.append("AirLog - Response received on thread ")
			.append(Thread.currentThread().getName()).append("\n");
        prefixId(b, id).append(prefix)
			.append(Integer.toString(status)).append("\n");
    }

    private void printPrefixedHeaders(final String prefix, 
		StringBuilder b, long id, MultivaluedMap<String, String> headers) {
        for (Map.Entry<String, List<String>> e : headers.entrySet()) {
            List<?> val = e.getValue();
            String header = e.getKey();

            if (val.size() == 1) {
                prefixId(b, id).append(prefix).append(header)
					.append(": ").append(val.get(0)).append("\n");
            } else {
                StringBuilder sb = new StringBuilder();
                boolean add = false;
                for (Object s : val) {
                    if (add) {
                        sb.append(',');
                    }
                    add = true;
                    sb.append(s);
                }
                prefixId(b, id).append(prefix).append(header)
					.append(": ").append(sb.toString()).append("\n");
            }
        }
    }
}


//测试类
public class TIResourceJtfTest extends JerseyTest {
    private static final Logger LOGGER = Logger.getLogger(TIResourceJtfTest.class);
    private static final String BASEURI = "books/";

    @Override
    protected Application configure() {
        ResourceConfig config = new ResourceConfig(BookResource.class);
        return config.register(com.example.filter.log.AirLogFilter.class);
    }

    @Override
    protected void configureClient(ClientConfig config) {
        config.register(new AirLogFilter());
    }
    
    @Test
    public void testPathGetJSON() {
        TIResourceJtfTest.LOGGER.debug(">>Test Path Get");
        final WebTarget pathTarget = target(TIResourceJtfTest.BASEURI + "1");
        final Invocation.Builder invocationBuilder = pathTarget.request(MediaType.APPLICATION_JSON_TYPE);
        final Book result = invocationBuilder.get(Book.class);
        TIResourceJtfTest.LOGGER.debug(result);
        Assert.assertNotNull(result.getBookId());
        TIResourceJtfTest.LOGGER.debug("<<Test Path Get");
    }
}
```

注意在测试类中，需要在服务端和客户端分别注册服务日志类AirLogFilter。

## 4. REST拦截器
拦截器与过滤器都是一种在请求-响应模型中用做切面处理的Provider。但两种除了功能不一样外，形式也不同。拦截器通常读写成对，而且没有服务端和客户端的区分。例如GZiPEncoder同时实现了读/写拦截器。

读拦截器接口ReaderInterceptor定义的拦截方法是：

```java
Object aroundReadFrom(ReaderInterceptorContext context)
	throws IOException, javax.ws.rs.WebApplicationException;
```

写拦截器接口WriterInterceptor定义的拦截方法是：

```java
void aroundWriteTo(WriterInterceptorContext context)
	throws IOException, javax.ws.rs.WebApplicationException;
```

## 5. Providers绑定机制
通过下面的方式定义的过滤器或拦截器是全局有效的：

* 通过手动注册到Application或者Configuration。
* 注解为@Provider，被自动探测。

除了全局Provider，还可以进行名称绑定和动态绑定。

### 5.1 名称绑定
过滤器和拦截器可以通过名称绑定来指定其作用范围。@NameBinding注解可以定义一个运行时的自定义注解，该注解用于定义类级别的名称和类的方法名：

```java
@NameBinding
@Target({ ElementType.TYPE, ElementType.METHOD })
@Retention(value = RetentionPolicy.RUNTIME)
public @interface AirLog {
}
```

然后将该注解绑定Provider，下例中的AirNameBindingFilter就实现了名称绑定：

```java
@AirLog
@Priority(Priorities.USER)
public class AirNameBindingFilter implements ContainerRequestFilter, ContainerResponseFilter {
    private static final Logger LOGGER = 
    	Logger.getLogger(AirNameBindingFilter.class);

    public AirNameBindingFilter() {
        LOGGER.info("Air-NameBinding-Filter initialized");
    }

    @Override
    public void filter(final ContainerRequestContext containerRequest) 
    throws IOException {
        LOGGER.debug("Air-ContainerRequestFilter invoked:" + 
        	containerRequest.getMethod());        	
        LOGGER.debug(containerRequest
        	.getUriInfo().getRequestUri());
    }
```

完成了Provider的名称绑定后，就可以在资源类的指定方法上使用自定义注解@AirLog，从而实现在该方法上启用Provider对应的过滤器。示例如下 ：

```java
@AirLog
@GET
@Produces({ MediaType.APPLICATION_JSON, MediaType.APPLICATION_XML })
public Books getBooks() {
	...
}
```

### 5.2 动态绑定
动态绑定无须新增注解，而是使用编码的方式实现接口javax.ws.rs.container.DynamicFeature，定义扩展点方法的名称、请求方法类型等匹配信息。在运行期，一旦Provider匹配当前处理类或方法，面向切面的Provider方法即被触发。

#### 5.2.1 定义绑定Provider

```java
public class AirDynamicFeature implements DynamicFeature {
    @Override
    public void configure(final ResourceInfo resourceInfo, 
			final FeatureContext context) {
        boolean classMatched = BookResource.class
			.isAssignableFrom(resourceInfo.getResourceClass());
        boolean methodNameMatched = resourceInfo
			.getResourceMethod().getName().contains("getBookBy");
        boolean methodTypeMatched = resourceInfo
			.getResourceMethod().isAnnotationPresent(POST.class);
			
        //匹配成功才注册
        if (classMatched && (methodNameMatched || methodTypeMatched)) {
            context.register(AirDynamicBindingFilter.class);
        }
    }
}
```

上面的示例代码启用了如下匹配规则：

* 类匹配：对BookResource类及其子类匹配。
* 方法名称匹配：方法名包含getBookBy。
* 请求方法类型匹配：匹配POST方法。

当匹配成功后，会触发下面的Provider:

```java
public class AirDynamicBindingFilter implements ContainerRequestFilter {
    private static final Logger LOGGER = Logger.getLogger(AirDynamicBindingFilter.class);

    public AirDynamicBindingFilter() {
        LOGGER.info("Air-Dynamic-Binding-Filter initialized");
    }

    @Override
    public void filter(final ContainerRequestContext requestContext) throws IOException {
        LOGGER.debug("Air-Dynamic-Binding-Filter invoked");
    }
}
```

## 6. 优先级
对于同一个扩展点，如果有多个Provider，其执行先后顺序是靠优先级排序的。优先级使用@Priority，一个整型值，常量定义在javax.ws.rs.Priorities中。

```
@Priority(Priorities.USER)
public class AirNameBindingFilter ...

@Priority(Priorities.USER + 1)
public class AirNameBindingFilter2 ...
```

对于ContainerRequest、PreMatchContainerRequest、ClientRequest和读写拦截器，数值越小，优先级越高。对于ContainerResponse和ClientResponse，数值越大，优先级越高。











参考：《Java RESTful Web Service实战》

