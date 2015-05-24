---
layout: post
title: "JAX-RS 2.0 异步通信"
date: 2015-04-12 21:54:22 +0800
comments: true
toc: true
categories: 
- java
---

JAX-RS 2.0的异步处理是通过两个线程实现的。其中一个线程用于处理客户端请求，另一个线程为此次请求新生成，用于处理业务。在后一个线程处理开始前，前一个线程可以响应客户端请求正在执行，然后进入挂起状态，保持连接。当后一个线程完毕后，唤醒前一个线程。线程的管理由容器实现。

<!--more-->

## 1. 服务端实现
服务端实现异步通信主要包括两个技术点，一是资源方法中对AsyncResponse的使用，另一个是对异步通信的CompletionCallback和TimeoutHandler接口的实现。

### 1.1 异步资源类实现
下面的示例代码模拟指保存大量数据：

```java
@Path("books")
public class AsyncResource {
    public static final long TIMEOUT = 120;        
    @Autowired private BookService bookService;

    public AsyncResource() {
    }

    @POST
    @Consumes({MediaType.APPLICATION_XML, MediaType.TEXT_XML})
    public void asyncBatchSave(
            //异步资源方法需要@Suspended注解和AsyncResponse参数
            @Suspended final AsyncResponse asyncResponse,
            final Books books) {
        //设置超时和回调
        configResponse(asyncResponse);
        //处理业务
        final BatchRunner batchTask = new BatchRunner(books.getBookList());
        Future<String> bookIdsFuture =
                Executors.newSingleThreadExecutor().submit(batchTask);
        String ids;
        try {
            //获取结果
            ids = bookIdsFuture.get();
            //唤醒请求线程，将resume方法的参数作为返回值响应给客户端
            asyncResponse.resume(ids);
        } catch (InterruptedException | ExecutionException e) {
            LOGGER.error(e.getMessage());
        }
    }
}        
```

任务执行的代码如下所示：

```java
class BatchRunner implements Callable<String> {
    private List<Book> bookList;
    public BatchRunner(List<Book> bookList) {
        this.bookList = bookList;
    }

    @Override
    public String call() {
        String ids = null;
        try {
            ids = batchSave();
            LOGGER.info(">>>>>>>>>> " + ids);
        } catch (InterruptedException e) {
            LOGGER.error(e);
        }
        return ids;
    }

    private String batchSave() throws InterruptedException {
        if (!CollectionUtils.isEmpty(bookList)) {
            ...
            return ...
        } else {
            return "";
        }
    }
}
```

### 1.2 超时和回调实现
分别通过CompletionCallback、ConnectionCallback和TimeoutHandler接口实现处理完成的回调、请求-响应模型的连接断开时的回调和处理超时的回调。默认情况下AsyncResource永不超时。

```java
private void configResponse(final AsyncResponse asyncResponse) {
    //处理完成的回调
    asyncResponse.register(new CompletionCallback() {
        @Override
        public void onComplete(Throwable throwable) {
            if (throwable == null) {
                LOGGER.info("CompletionCallback-onComplete: OK");
            } else {
                LOGGER.info("CompletionCallback-onComplete: ERROR: " 
                        + throwable.getMessage());
            }
        }
    });
    
    //连接断开的回调
    asyncResponse.register(new ConnectionCallback() {
        @Override
        public void onDisconnect(AsyncResponse disconnected) {
            //Status.GONE=410
            LOGGER.info("ConnectionCallback-onDisconnect");
            disconnected.resume(Response.status(Response.Status.GONE)
                    .entity("disconnect!").build());
        }
    });

    //超时的回调，当超时时，主动唤醒AsyncResource实例并设置HTTP状态码
    asyncResponse.setTimeoutHandler(new TimeoutHandler() {
        @Override
        public void handleTimeout(AsyncResponse asyncResponse) {
            //Status.SERVICE_UNAVAILABLE=503
            LOGGER.info("TIMEOUT");
            asyncResponse.resume(Response.status(
                    Response.Status.SERVICE_UNAVAILABLE)
                    .entity("Operation time out.").build());
        }
    });
    asyncResponse.setTimeout(TIMEOUT, TimeUnit.SECONDS);
}
```

## 2. 客户端实现与测试
### 2.1 异步测试类
不需要额外的配置，继承JerseyTest就可以进行异步测试，示例如下：

```java
public class TIAsyncJFTTest extends JerseyTest {
    private final static Logger LOGGER = Logger.getLogger(TIAsyncJFTTest.class);
    private static final int COUNT = 2;

    @Override
    protected Application configure() {
        enable(TestProperties.LOG_TRAFFIC);
        enable(TestProperties.DUMP_ENTITY);
        return new ResourceConfig(AsyncResource.class);
    }

    @Test
    public void testAsyncBatchSave() throws InterruptedException, ExecutionException {
        List<Book> bookList = new ArrayList<>(COUNT);
        try {
            //...初始化bookList
            Books books = new Books(bookList);
            final Entity<Books> booksEntity = Entity.entity(books, MediaType.APPLICATION_XML_TYPE);
            final Builder request = target("books").request();
			//请求方法的调用使用AsyncInvoker实例
            final AsyncInvoker async = request.async();
			//使用post()方法提交异步请求
            final Future<String> responseFuture = async.post(booksEntity, String.class);
			//第一次响应返回
            TIAsyncJFTTest.LOGGER.debug("First response @" + System.currentTimeMillis());
            String result = null;
            try {
				//...可以以非阻塞方式处理其他业务
				//异步获取服务器的最终响应
                result = responseFuture.get(AsyncResource.TIMEOUT + 1, TimeUnit.SECONDS);
            } catch (TimeoutException e) {
                //...
            } finally {
				//...
            }
        } finally {
            TIAsyncJFTTest.LOGGER.debug("<-**Test Batch Save");
        }
    }
}
```

### 2.2 异步回调
在AsyncInvoker接口的post()方法中，定义一个InvocationCallback接口的实例，实现REST调用的回调，示例如下：

```java
Books books = new Books(bookList);
final Entity<Books> booksEntity = 
        Entity.entity(books, MediaType.APPLICATION_XML_TYPE);
final AsyncInvoker async = target("books").request().async();
final Future<String> responseFuture = 
        async.post(booksEntity, new InvocationCallback<String>() {
    @Override
    public void completed(String result) {
        LOGGER.debug("On Completed: " + result);
    }

    @Override
    public void failed(Throwable throwable) {
        LOGGER.debug("On Failed: " + throwable.getMessage());
        throwable.printStackTrace();
    }
});
LOGGER.debug("First response @" + System.currentTimeMillis());
String result = null;
try {
    result = responseFuture.get(TIMEOUT + 1, TimeUnit.SECONDS);
} catch (TimeoutException e) {
    LOGGER.debug("%%%% " + e.getMessage());
} finally {
    LOGGER.debug("Second response @" + System.currentTimeMillis());
    LOGGER.debug("<<<<<<<<<<< book id array: " + result);
}
```

