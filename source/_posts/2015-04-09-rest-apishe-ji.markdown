---
layout: post
title: "JAX-RS REST API设计"
date: 2015-04-09 19:54:14 +0800
comments: true
categories: 
- java
---

REST式的Web服务和RPC式的Web服务在接口定义上的区别是，前者使用HTTP的方法作为统一接口的标准词汇，而后者所提供的方法信息在SOAP/HTTP信封里，每个RPC式的Web服务都会公布一套自己的方法词汇。

<!--more-->

## 1. REST统一接口
每一种HTTP请求方法都可以从安全性和幂等性两方面考虑，这对设计统一接口具有决定性意义。

* 安全性：指对该接口的访问，不会使服务端资源的状态发生改变。
* 幂等性（Idempotence）：指对同一REST接口的多次访问，得到的资源状态是相同的。

### 1.1 GET方法
HTTP GET方法用于读取资源。GET方法应该是安全的、幂等的。如果这样一种场景，虽然是读取资源，但服务端可能需要从其它系统同步资源，即意味着服务端资源状态可能发生改变，此时应该使用POST方法，而不是GET方法。

通常GET方法会以资源名称命名，根据不同情况使用单数或复数。

JAS-RS 2.0使用`@GET`注解来定义资源方法，注解可以定义在接口和POJO中，放在接口中更具抽象和通用性。示例如下：

```java
@Path("book")
public interface BookResource {
    @GET
    public String getWeight();
}

public class EBookResourceImpl implements BookResource {    
    //实现类无须加注解
    @Override
    public String getWeight() {
        return "150M";
    }
}

public class GetTest extends JerseyTest {
    @Override
    protected Application configure() {
        return new ResourceConfig(EBookResourceImpl.class);
    }

    @Test
    public void testGet() {
        final Response response = target("book").request().get();
        Assert.assertEquals("150M", response.readEntity(String.class));
    }
}
```    

### 1.2 HEAD和OPTIONS方法
这两个方法与GET相似，但HEAD方法的返回值不包括HTTP实体，因此也应该是安全和幂等的。使用`@HEAD`注解来定义。而OPTIONS方法用于读取资源所支持（Allow）的所有HTTP请求方法，也是安全和幂等的。使用`@OPTIONS`注解进行定义。

### 1.3 PUT方法
PUT方法用于更新或添加资源，所以肯定不是安全的。PUT方法应该是幂等的。多次插入或者更新同一份数据，在服务端对资源状态所产生的改变应该是相同的。通常更新资源使用PUT方法没有问题，但添加资源时，需要考虑使用PUT方法还是POST方法。一般来说，如果同一份数据，总是可以提供唯一的主键，具有幂等性，使用PUT方法，否则使用POST方法。

JAX-RS 2.0定义了`@PUT`注解来定义PUT方法。示例如下：

```java
@Path("book")
public interface BookResource {
    @PUT
    @Produces(MediaType.TEXT_PLAIN)
    @Consumes(MediaType.APPLICATION_XML)
    public String newBook(Book book);
}

public class EBookResourceImpl implements BookResource {
    @Override
    public String newBook(Book book) {
        SimpleDateFormat f = new SimpleDateFormat("d MMM yyyy HH:mm:ss");
        Date lastUpdate = Calendar.getInstance().getTime();
        //...
        LOGGER.debug(book.getBookId());
        return f.format(lastUpdate);
    }    
}

public class PutTest extends JerseyTest {
    private final static Logger LOGGER = Logger.getLogger(PutTest.class);
    public static AtomicLong clientBookSequence = new AtomicLong();

    @Override
    protected Application configure() {
        enable(TestProperties.LOG_TRAFFIC);
        enable(TestProperties.DUMP_ENTITY);
        return new ResourceConfig(EBookResourceImpl.class);
    }

    @Test
    public void testNew() {
        final Book newBook = new Book(clientBookSequence.incrementAndGet(), "book-" + System.nanoTime());
        MediaType contentTypeMediaType = MediaType.APPLICATION_XML_TYPE;
        MediaType acceptMediaType = MediaType.TEXT_PLAIN_TYPE;
        final Entity<Book> bookEntity = Entity.entity(newBook, contentTypeMediaType);
        final String lastUpdate = target("book").request(acceptMediaType).put(bookEntity, String.class);
        Assert.assertNotNull(lastUpdate);
        LOGGER.debug(lastUpdate);
    }
}
```    

PUT方法需要考虑请求实体的媒体类型（HTTP头的Content Type，上例中的@Consumes）和响应实体的媒体类型(HTTP头的Accept定义, 上例中的@Produces)。

### 1.4 DELETE方法
DELETE方法是幂等的、不安全的。使用`@DELETE`注解来定义资源方法。示例如下：

```java
@Path("book")
public interface BookResource {
    @DELETE
    public void delete(@QueryParam("bookId") final long bookId);
}

public class EBookResourceImpl implements BookResource {
    @Override
    public void delete(long bookId) {
        LOGGER.debug(bookId);
    }
}  

public class DeleteTest extends JerseyTest {
    private final static Logger LOGGER = Logger.getLogger(DeleteTest.class);
    @Test
    public void testGet() {
        final Response response = target("book").queryParam("bookId", "9527").request().delete();
        int status = response.getStatus();
        LOGGER.debug(status);
        Assert.assertEquals(Response.Status.NO_CONTENT.getStatusCode(), status);
    }
}  
```    

上例中，delete方法没有返回值，将HTTP状态码设置为204. 在测试代码中，测试断言不是针对删除资源的实体，而是响应的HTTP状态码。

### 1.5 POST方法
POST方法用于写数据，既不幂等也不安全。REST只使用POST方法添加资源。使用`@POST`注解，示例如下：

```java
@Path("book")
public interface BookResource {
    @POST
    @Produces(MediaType.APPLICATION_XML)
    @Consumes(MediaType.APPLICATION_XML)
    public Book createBook(Book book);
}

public class EBookResourceImpl implements BookResource {
    @Override
    public Book createBook(Book book) {
        book.setBookId(serverBookSequence.incrementAndGet());
        return book;
    }    
}

public class PostTest extends JerseyTest {
    private final static Logger LOGGER = Logger.getLogger(PostTest.class);
    public static AtomicLong clientBookSequence = new AtomicLong();

    @Override
    protected Application configure() {
        enable(TestProperties.LOG_TRAFFIC);
        enable(TestProperties.DUMP_ENTITY);
        return new ResourceConfig(EBookResourceImpl.class);
    }

    @Test
    public void testCreate() {
        final Book newBook = new Book("book-" + System.nanoTime());
        MediaType contentTypeMediaType = MediaType.APPLICATION_XML_TYPE;
        MediaType acceptMediaType = MediaType.APPLICATION_XML_TYPE;
        final Entity<Book> bookEntity = Entity.entity(newBook, contentTypeMediaType);
        final Book book = target("book").request(acceptMediaType).post(bookEntity, Book.class);
        Assert.assertNotNull(book.getBookId());
        LOGGER.debug("Server Id=" + book.getBookId());
    }
}    
```

## 2. REST资源定位
在设计REST式的Web服务过程中，资源地址的设计是非常严谨的。地址应该是面向资源的，资源名称应是准确描述该资源的名词，资源地址应具有直观的描述性。

### 2.1 资源地址设计
一个典型的请求URL如下：`http://localhost:8080/myproject/webapi/books/book?id=1`，它包括以下部分：

* requestURI: `myproject/webapi/books/book?id=1`
* ContextPath: `myproject`，与部署服务器的配置或web.xml有关
* ServletPath: `webapi`，与`@ApplicationPath`注解或web.xml配置有关
* PathInfo: `books/book`，与`@Path`注解有关
* QueryString: `id=1`

资源地址是否可以唯一定位一个资源？答案是否定的。因为资源地址相同，但HTTP方法不同时，对应的是不同的REST接口。

在路径变量中可以使用标点符号来辅助增强逻辑清晰性：

* `?`号，用来分隔资源地址和查询字符串，`&`号用于分隔参数。如: `GET /books?start=0&size=10`
* `,`逗号用来分隔有次序的作用域信息。也可以使用`-`,`_`来做逻辑上的辅助分隔。如：`GET /books/01,2002-12,2014`
* `;`分号用来分隔无次序的作用域信息。这些信息在逻辑上通常是并列存在的，如并列查询条件。示例：`GET /books/restful;program=java;type=web`

### 2.2 @QueryParam注解
@QueryParam注解用来定义查询参数，例如：

```java
public Yijings getByPaging(
	@QueryParam("start")final int start, 
	@DefaultValue("100") @QueryParam("limit")final int limit, 
	@QueryParam("sort")final String sortName) {
	//...
}
```

### 2.3 @PathParam注解
@PathParam注解用于定义路径参数，每个参数对应一个子资源。

#### @Path注解
格式为：{参数名称：正则表达式}，例如：

```java
@GET
@Path("{from:\\d+}-{to:\\d+}")
public String getByCondition(
	@PathParam("from")final Integer from, 
	@PathParam("to")final Integer to){
	...
}
//eg. /path-resource/199-1999
```

正则表达式的内容可以参考[这篇博客](/blog/2015/04/06/xue-xi-zheng-ze-biao-da-shi/)。

#### 路径区间(PathSegment)
路径区间可以支持更广泛的资源地址请求。示例如下：

```
/*
匹配以下资源(都有固定子资源shenyang)：
/path-res/Asia/China/northeast/liaoning/shenyang/huanggu
/path-res/China/northeast/liaoning/shenyang/tiexi
/path-res/China/shenyang/huanggu
*/

@GET
@Path("{region:.+}/shenyang/{district:\\w+}")
public String getByAddress(
	@PathParam("region") final List<PathSegment> region, 
	@PathParam("district") final String district) {
	final StringBuilder result = new StringBuilder();
	for(final PathSegment pathSegment : region) {
		result.append(pathSegment.getPath()).append("-");
	}
	...
}
```

对于查询参数动态给定的场景（经测，需要用分号分隔），可以定义PathSegment参数类型，示例如下：

```java
@GET
@Path("q/{condition}")
public String getByCondition(@PathParam("condition") final PathSegment condition) {
    final MultivaluedMap<String, String> matrixParameters = condition.getMatrixParameters();
    final Iterator<Map.Entry<String, List<String>>> iterator = matrixParameters.entrySet().iterator();

    StringBuilder result = new StringBuilder(condition.getPath()+":");
    while (iterator.hasNext()) {
        final Map.Entry<String, List<String>> entry = iterator.next();
        result.append(entry.getKey()).append("=");
        result.append(entry.getValue()).append(" ");
    }
    return result.toString();
}

//http://localhost:8080/webapi/books/q/restful;program=java;type=web
//输出：restful:program=[java] type=[web]    
```

上述示例也可以通过`@MatrixParam`注解来实现，示例如下：

```java
@GET
@Path("q/{condition}")
public String getByCondition(
	@PathParam("condition") final PathSegment condition, 
	@MatrixParam("program") final String program, 
	@MatrixParam("type") final String type) {
	return condition.getPath() + ": program=[" + program + "] type=[" + type + "]";
}
```

`@MatrixParam`注解可以清晰地表达可接收的参数名称和类型，但缺乏灵活性。

### 2.4 @FormParam注解
@FormParam注解用来定义表单参数，相应的REST方法用于处理请求实体媒体类型为Content-Type:application/x-www-form-urlencoded的请求。示例如下：

```java
@Path("form-resource")
@POST
public String newPassword(
    //注意可以使用@DefaultValue
    @DefaultValue("meixuesong") @FormParam("user") final String user,
    //注意@Encoded表示禁用自动解码，参数不会被解码，如果直接返回，客户端的值是处于编码状态的字符串。下面的测试代码可看到区别
    @Encoded @FormParam("password") final String password,
    @Encoded @FormParam("newPassword") final String newPassword,
    @FormParam("verification") final String verification
) {
    return user + ":" + password + ":" + newPassword + ":" + verification;
}

/** 测试代码*/
public class FormTest extends JerseyTest {
    private static final Logger LOGGER = Logger.getLogger(FormTest.class);

    @Override
    protected Application configure() {
        enable(TestProperties.LOG_TRAFFIC);
        enable(TestProperties.DUMP_ENTITY);
        return new ResourceConfig(BookResource.class);
    }

    @Test
    public void testPost2() {
        final Form form = new Form();
        form.param("password", "北京");
        form.param("newPassword", "上海");
        form.param("verification", "上海");
        final String result = target("books/form-resource").request().post(Entity.entity(form, MediaType.APPLICATION_FORM_URLENCODED_TYPE), String.class);
        FormTest.LOGGER.debug(result);
        Assert.assertEquals("encoded should let it to disable decoding", "meixuesong:%E5%8C%97%E4%BA%AC:%E4%B8%8A%E6%B5%B7:上海", result);
    }
}
```

### 2.5 @BeanParam注解
@BeanParam注解用于自定义参数组合，使REST方法的参数更加简洁。示例如下：

```java
@Path("bean-resource")
public class BeanParamResource {

    @GET
    @Path("{region:.+}/shenyang/{district:\\w+}")
    @Produces(MediaType.TEXT_PLAIN)
    public String getByAddress(@BeanParam Jaxrs2GuideParam param) {
        System.out.println("acceptParam: " + param.getAcceptParam());
        //acceptParam: text/html, image/gif, image/jpeg, *; q=.2, */*; q=.2
        return param.getRegionParam() + ":" + param.getDistrictParam() + ":" + param.getStationParam() + ":" + param.getVehicleParam();
    }
}

public class Jaxrs2GuideParam {
    @HeaderParam("accept")
    private String acceptParam;
    @PathParam("region")
    private String regionParam;
    @PathParam("district")
    private String districtParam;
    @QueryParam("station")
    private String stationParam;
    @QueryParam("vehicle")
    private String vehicleParam;
    //getter setter
}    

//测试
public class BeanParamTest extends JerseyTest {
    private static final Logger LOGGER = Logger.getLogger(BeanParamTest.class);

    @Override
    protected Application configure() {
        enable(TestProperties.LOG_TRAFFIC);
        enable(TestProperties.DUMP_ENTITY);
        return new ResourceConfig(BeanParamResource.class);
    }

    @Test
    public void testBeanParam() {
        final String path = "bean-resource";
        String result;

        /*http://localhost:9998/bean-resource/China/northeast/shenyang/tiexi?station=Workers+Village&vehicle=bus*/
        final WebTarget queryTarget = target(path).path("China").path("northeast").path("shenyang").path("tiexi").queryParam("station", "Workers Village")
                .queryParam("vehicle", "bus");
        result = queryTarget.request().get().readEntity(String.class);
        LOGGER.debug(result);
        Assert.assertEquals("China/northeast:tiexi:Workers Village:bus", result);
    }
}
```

### 2.6 @CookieParam注解
@CookieParam注解用于匹配Cookie中的键值对信息。示例如下：

```java
@Path("kuky-resource")
public class CookieResource {
    @GET
    public String getHeaderParams(@CookieParam("longitude") final String longitude,
                                  @CookieParam("latitude") final String latitude,
                                  @CookieParam("population") final double population,
                                  @CookieParam("area") final int area) {
        return longitude + "," + latitude + " population=" + population + ",area=" + area;
    }
}

//测试
public class CookieTest extends JerseyTest {
    private static final Logger LOGGER = Logger.getLogger(CookieTest.class);

    @Override
    protected Application configure() {
        enable(TestProperties.LOG_TRAFFIC);
        enable(TestProperties.DUMP_ENTITY);
        return new ResourceConfig(CookieResource.class);
    }

    @Test
    public void testContexts() {
        final String path = "kuky-resource";
        String result;

        /*http://localhost:9998/kuky-resource*/
        final Builder request = target(path).request();
        request.cookie("longitude", "123.38");
        request.cookie("latitude", "41.8");
        request.cookie("population", "822.8");
        request.cookie("area", "12948");
        result = request.get().readEntity(String.class);
        CookieTest.LOGGER.debug(result);
        Assert.assertEquals("123.38,41.8 population=822.8,area=12948", result);
    }
}
```

### 2.7 @Context注解
@Context注解用于解析上下文参数。下面的示例代码定义了Application、Request、Providers、UriInfo和HttpHeaders等5种类型的上下文实例，从而可以获取请求过程中的重要参数信息。代码如下：

```java
@Path("ctx-resource")
public class ContextResource {
    @GET
    @Path("{region:.+}/shenyang/{district:\\w+}")
    @Produces(MediaType.TEXT_PLAIN)
    public String getByAddress(
            @Context final Application application,
            @Context final Request request,
            @Context final javax.ws.rs.ext.Providers provider,
            @Context final UriInfo uriInfo,
            @Context final HttpHeaders headers) {
        final StringBuilder buf = new StringBuilder();
        final String path = uriInfo.getPath();
        buf.append("PATH=").append(path).append("\n");

        final MultivaluedMap<String, String> pathMap = uriInfo.getPathParameters();
        buf.append("PATH_PARAMETERS:\n");
        iterating(buf, pathMap);

        final MultivaluedMap<String, String> queryMap = uriInfo.getQueryParameters();
        buf.append("QUERY_PARAMETERS:\n");
        iterating(buf, queryMap);

        final List<PathSegment> segmentList = uriInfo.getPathSegments();
        buf.append("PATH_SEGMENTS:\n");
        for (final PathSegment pathSegment : segmentList) {
            final MultivaluedMap<String, String> matrix = pathSegment.getMatrixParameters();
            final String segmentPath = pathSegment.getPath();
            buf.append(matrix);
            buf.append(segmentPath);
        }
        buf.append("\nHEAD:\n");
        final MultivaluedMap<String, String> headerMap = headers.getRequestHeaders();
        iterating(buf, headerMap);
        buf.append("COOKIE:\n");
        final Map<String, Cookie> kukyMap = headers.getCookies();
        final Iterator<Entry<String, Cookie>> i = kukyMap.entrySet().iterator();
        while (i.hasNext()) {
            final Entry<String, Cookie> e = i.next();
            final String k = e.getKey();
            buf.append("key=").append(k).append(",value=");
            final Cookie cookie = e.getValue();
            buf.append(cookie.getValue()).append(" ");
            buf.append("\n");
        }
        return buf.toString();
    }

    private void iterating(final StringBuilder buf, final MultivaluedMap<String, String> pathMap) {
        final Iterator<Entry<String, List<String>>> i = pathMap.entrySet().iterator();
        while (i.hasNext()) {
            final Entry<String, List<String>> e = i.next();
            final String k = e.getKey();
            buf.append("key=").append(k).append(",value=");
            final List<String> vList = e.getValue();
            for (final String v : vList) {
                buf.append(v).append(" ");
            }
            buf.append("\n");
        }
    }
}

//测试代码
public class ContextTest extends JerseyTest {
    private static final Logger LOGGER = Logger.getLogger(ContextTest.class);

    @Override
    protected Application configure() {
        enable(TestProperties.LOG_TRAFFIC);
        enable(TestProperties.DUMP_ENTITY);
        return new ResourceConfig(ContextResource.class);
    }

    @Test
    public void testContexts() {
        final String path = "ctx-resource";
        String result;

        /*http://localhost:9998/ctx-resource/Asia/China/northeast/liaoning/shenyang/huangu*/
        final WebTarget pathTarget = target(path).path("Asia").path("China").path("northeast").path("liaoning").path("shenyang").path("huangu");
        result = pathTarget.request().get().readEntity(String.class);
        ContextTest.LOGGER.debug(result);

        /*http://localhost:9998/ctx-resource/China/shenyang/tiexi?station=Workers+Village&vehicle=bus*/
        final WebTarget queryTarget = target(path).path("China").path("shenyang").path("tiexi").queryParam("station", "Workers Village")
                .queryParam("vehicle", "bus");
        result = queryTarget.request().get().readEntity(String.class);
        ContextTest.LOGGER.debug(result);
    }
}
```

## 3. REST传输格式
采用什么样的数据格式进行传输也是API设计的一个重要内容。通常REST接口以XML和JSON作为主要的传输格式。

### 3.1 基本类型、输入流及Reader
Java的基本类型主要包括4种整型（byte，short, int, long）、两种浮点类型（float, double）、Unicode编码的字符(char)和布尔类型(boolean)。

Jersey开发REST接口时，除了支持基本类型外，还支持文件类型（File）、字节流（InputStream）、字符流类型以及Reader类型。示例代码及测试类如下：

```java
@Path("in-resource")
public class InResource {
    private static final Logger LOGGER = Logger.getLogger(InResource.class);

    @POST
    @Path("b")
    public String postBytes(final byte[] bs) {
        for (final byte b : bs) {
            LOGGER.debug(b);
        }
        return "byte[]:" + new String(bs);
    }

    @POST
    @Path("c")
    public Response postString(final String s) {
        LOGGER.debug(s);
        //Response.noContent().build();
        return Response.ok().entity("char[]:" + s).build();
    }

    @DELETE
    @Path("{s}")
    public void delete(@PathParam("s") final String s) {
        LOGGER.debug(s);
    }

    @POST
    @Path("f")
    public File postFile(final File f) throws IOException {
        try (BufferedReader br = new BufferedReader(new FileReader(f))) {
            String s;
            do {
                s = br.readLine();
                LOGGER.debug(s);
            } while (s != null);
            return f;
        }
    }

    @POST
    @Path("bio")
    public String postStream(final InputStream is) throws IOException {
        try (BufferedReader br = new BufferedReader(new InputStreamReader(is))) {
            StringBuilder result = new StringBuilder();
            String s = br.readLine();
            while (s != null) {
                result.append(s).append("\n");
                LOGGER.debug(s);
                s = br.readLine();
            }
            return result.toString();
        }
    }

    @POST
    @Path("cio")
    public Response postChars(final Reader r) throws IOException {
        try (BufferedReader br = new BufferedReader(r)) {
            StringBuilder result = new StringBuilder();
            String s = br.readLine();
            if (s == null) {
                throw new RuntimeException("NOT FOUND FROM READER");
            }
            while (s != null) {
                result.append(s).append("\n");
                LOGGER.debug(s);
                s = br.readLine();
            }
            return Response.ok().entity(result.toString()).build();
        }
    }
}

/*测试*/
public class InputTest extends JerseyTest {
    private static final Logger LOGGER = Logger.getLogger(InputTest.class);
    final String path = "in-resource";
    String result;

    @Override
    protected Application configure() {
        enable(TestProperties.LOG_TRAFFIC);
        enable(TestProperties.DUMP_ENTITY);
        return new ResourceConfig(InResource.class);
    }

    @Test
    public void testBytes() {
        final String message = "TEST STRING";
        final Builder request = target(path).path("b").request();
        //final Response response = request.post(Entity.entity(message, MediaType.TEXT_PLAIN_TYPE), Response.class);
        final Response response = request.post(Entity.entity(message, MediaType.TEXT_HTML_TYPE), Response.class);
        result = response.readEntity(String.class);
        LOGGER.debug(result);
        Assert.assertEquals("byte[]:" + message, result);
    }

    @Test
    public void testResponse() {
        final String message = "TEST STRING";
        final Builder request = target(path).path("c").request();
        final Response response = request.post(Entity.entity(message, MediaType.TEXT_HTML_TYPE), Response.class);
        result = response.readEntity(String.class);
        LOGGER.debug(result);
        Assert.assertEquals("char[]:" + message, result);
    }

    @Test
    public void testVoid() {
        final String message = "TEST STRING";
        final Builder request = target(path).path(message).request();
        final Response response = request.delete();
        int status = response.getStatus();
        LOGGER.debug(status);
        Assert.assertEquals(Response.Status.NO_CONTENT.getStatusCode(), status);
    }

    @Test
    public void testFile() throws IOException {
        final URL resource = getClass().getClassLoader().getResource("gua.txt");
        assert resource != null;
        final String file = resource.getFile();
        final File f = new File(file);
        final Builder request = target(path).path("f").request();
        Entity<File> e = Entity.entity(f, MediaType.TEXT_PLAIN_TYPE);
        final Response response = request.post(e, Response.class);
        File result = response.readEntity(File.class);
        try (BufferedReader br = new BufferedReader(new FileReader(result))) {
            String s;
            do {
                s = br.readLine();
                LOGGER.debug(s);
            } while (s != null);
        }
    }

    @Test
    public void testStream() {
        final InputStream resource = getClass().getClassLoader().getResourceAsStream("gua.txt");
        final Builder request = target(path).path("bio").request();
        Entity<InputStream> e = Entity.entity(resource, MediaType.TEXT_PLAIN_TYPE);
        final Response response = request.post(e, Response.class);
        result = response.readEntity(String.class);
        LOGGER.debug(result);
    }

    @Test
    public void testReader() {
        ClassLoader classLoader = getClass().getClassLoader();
        final Reader resource = new InputStreamReader(classLoader.getResourceAsStream("gua.txt"));
        final Builder request = target(path).path("cio").request();
        Entity<Reader> e = Entity.entity(resource, MediaType.TEXT_PLAIN_TYPE);
        final Response response = request.post(e, Response.class);
        result = response.readEntity(String.class);
        LOGGER.debug(result);
    }
}
```

### 3.2 XML类型
Java处理XML有两大标准：JAXP(Java API for XML Processing)和JAXB(Java Architecture for XML Binding)。

#### JAXP
JAXP包含了DOM、SAX和StAX三种解析XML的技术标准。

* DOM 面向文档解析的技术，要求将XML全部加载到内存，映射为树和结点。
* SAX 事件驱动的流解析技术，通过监听注册事件，触发回调方法以实现解析。
* StAX 拉式流解析技术，读取过程可以主动推进当前XML位置指针，而不是被动获得解析中的XML数据。

相应地，JAXP定义了三种标准类型的输入接口Source(DOMSource、SAXSource和StreamSource)和输出接口Result(DomResult、SAXResult和StreamResult)。示例代码：[代码](https://github.com/feuyeux/jax-rs2-guide/blob/master/sample/3/simple-service-3/src/main/java/com/example/media/xml/XMLResource.java)、[测试代码](https://github.com/feuyeux/jax-rs2-guide/blob/master/sample/3/simple-service-3/src/test/java/com/example/media/xml/XMLTest.java)。

#### JAXB
JAXP的缺点是需要编码解析XML，增加了开发工作量。JAXB只需要在POJO中定义相关的注解，无须对XML进行程序式解析，推荐使用JAXB作为XML解析技术。

Jersey支持使用JAXBElement作为REST方法参数，也支持直接使用POJO作为REST方法参数，示例如下：

```
@XmlRootElement
public class Book implements Serializable {
    private Long bookId;
    private String bookName;
    private String publisher;

    @XmlAttribute(name = "bookId")
    public Long getBookId() {
        return bookId;
    }

    @XmlAttribute(name = "bookName")
    public String getBookName() {
        return bookName;
    }
    ...
}

@POST
@Path("jaxb")
@Produces(MediaType.APPLICATION_XML)
@Consumes(MediaType.APPLICATION_XML)
public Book getEntity(JAXBElement<Book> bookElement) {
	Book book = bookElement.getValue();
	...
}

/*以POJO作为参数*/
@POST
@Produces(MediaType.APPLICATION_XML)
@Consumes(MediaType.APPLICATION_XML)
public Book saveBook(final Book book) {
    return bookService.saveBook(book);
}   
```

### 3.3 JSON类型
JSON类型已经成为Ajax数据传输的实际标准，Jersey提供了4种处理JSON数据的媒体包。它们支持的处理方式如下表：

解析方式 | MOXy | JSON-P | Jackson | Jettison
--|--|--|--|---
POJO-based JSON Binding | yes | no | yes | no
JAXB-based JSON Binding | yes | no | yes | yes
Low-level JSON parsing & processing  | no | yes | no | yes

请注意，JSON-P是指Java API for JSON Processing，而不是JSON with Padding(JSONP)。前者是Java处理JSON格式数据的API，而后者是用于异步请求中传递脚本的回调函数来解决跨域问题。

#### 使用Jackson处理JSON
**(1)定义依赖**，在pom中增加依赖：

```xml
<dependency>
    <groupId>org.glassfish.jersey.media</groupId>
    <artifactId>jersey-media-json-jackson</artifactId>
    <version>${jersey.version}</version>
</dependency>
```

**(2)定义Application**，需要在application中注册JacksonFeature，如有必要根据不同的实体类做详细解析，则可以注册ContextResolver的实现类。示例：

```java
@ApplicationPath("/api/*")
public class JsonResourceConfig extends ResourceConfig {
    public JsonResourceConfig() {
        register(JacksonFeature.class);
        register(BookResource.class);
        
        //注册ContextResolver的实现类
        register(JsonContextProvider.class);
    }
}
```

**(3)定义POJO**，可以定义三种不同方式的POJO：

```java
//第一种：仅用JAXB注解的普通POJO
@XmlRootElement
@XmlType(propOrder = {"bookId", "bookName", "chapters"})
public class JsonBook {
    private String[] chapters;
    private String bookId;
    private String bookName;

    public String getBookId() {
        return bookId;
    }
    
    ...
}    

//第二种：混和使用JAXB注解和Jackson注解的POJO
@XmlRootElement
public class JsonHybridBook {
    @SuppressWarnings("unused")
    @JsonProperty("bookId")
    private String bookId;

    @SuppressWarnings("unused")
    @JsonProperty("bookName")
    private String bookName;
    
    ...
}    

//第三种：不使用任何注解的POJO

public class JsonNoJaxbBook {
    private String bookId;
    private String bookName;

    public String getBookId() {
        return bookId;
    }
    ...
}    
```

**(4) 定义资源类**

```java
@Path("books")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class BookResource {
    @Path("/emptybook")
    @GET
    public JsonBook getEmptyArrayBook() {
        return new JsonBook();
    }

    @Path("/hybirdbook")
    @GET
    public JsonHybridBook getHybirdBook() {
        return new JsonHybridBook();
    }

    @Path("/nojaxbbook")
    @GET
    public JsonNoJaxbBook getNoJaxbBook() {
        return new JsonNoJaxbBook();
    }
}
```   

**(5)上下文解析实现类** 可以根据上下文提供的POJO类型，分别提供解析方式。[示例代码](https://github.com/feuyeux/jax-rs2-guide/blob/master/sample/3/2simple-service-jackson/src/main/java/com/example/resource/JsonContextProvider.java)

**(6)单元测试** [代码](https://github.com/feuyeux/jax-rs2-guide/blob/master/sample/3/2simple-service-jackson/src/test/java/com/example/resource/BookResourceTest.java)

## 4. REST连通性
在Restful Web Service中，Representation应该是超媒体（HyperMedia），也就是说表示中不仅包含数据，还包含指向其它资源的连接。这种具有“连接”的特性，称为连通性。连通性使服务器通过超媒体告诉客户端当前状态有哪些后续状态可以进入。例如在http://www.google.com/search?hl=en&q=apple&aq=f资源里的“下一页”连接起的就是这种推进作用——它指引你如何从当前状态进入下一个可能的状态。在Restful Web服务的文档中只要包含URI就可以指向本应用的其他状态，因为Restful WebService是可寻址且无状态的应用。

### 4.1 过渡型链接
Web Link通过使用HTTP头信息来传递操作链接。在Jersey中使用javax.ws.rs.core.Link类来支持Web Link的资源类。示例如下：

```java
@Path("weblink-resource")
public class WebLinkResource {
    @Context
    UriInfo uriInfo;

    @Path("{bookId:[0-9]*}")
    @GET
    @Produces({MediaType.APPLICATION_JSON, MediaType.APPLICATION_XML})
    public Book getOne(@PathParam("bookId") final Long bookId) {
        final Book result = LinkCache.map.get(bookId);
        if (result == null) {
            throw new RuntimeException("Not found for bookId=" + bookId);
        }
        return result;
    }

    @POST
    @Produces(MediaType.APPLICATION_XML)
    @Consumes({MediaType.APPLICATION_JSON, MediaType.APPLICATION_XML, MediaType.TEXT_XML})
    public Response saveBook(final Book book) {
        final long newId = System.nanoTime();
        book.setBookId(newId);
        LinkCache.map.put(newId, book);
        //方式1：通过uriInfo实例获取资源路径，然后添加资源ID信息
        final UriBuilder ub = uriInfo.getAbsolutePathBuilder();
        final URI location = ub.path("" + newId).build();
        //方式2：通过模板获取资源路径，
        final String uriTemplate = "http://{host}:{port}/{path}/{param}";
        final URI location2 = UriBuilder.fromUri(uriTemplate)
                .resolveTemplate("host", "localhost")
                .resolveTemplate("port", "9998")
                .resolveTemplate("path", "weblink-resource")
                .resolveTemplate("param", newId).build();
        //方式3：通过模板方法获取资源路径
        final UriBuilder ub3 = uriInfo.getAbsolutePathBuilder();
        final URI location3 = ub3.scheme("http")
                .host("localhost")
                .port(9998)
                .path("weblink-resource")
                .path("" + newId).build();

        //这三个与Link相关的URI实例由Response构建，作为返回值响应给客户端
        return Response.created(location)
                .link(location2, "view1")
                .link(location3, "view2")
                .entity(book).build();
    }
}

//测试
public class WebLinkTest extends JerseyTest {
    private static final Logger LOGGER = Logger.getLogger(WebLinkTest.class);

    @Override
    protected Application configure() {
        enable(TestProperties.LOG_TRAFFIC);
        enable(TestProperties.DUMP_ENTITY);
        return new ResourceConfig(WebLinkResource.class);
    }

    @Test
    public void testPostAndGet() {
        final Entity<Book> entity = Entity.entity(new Book("WEBLINK"), MediaType.APPLICATION_XML_TYPE);
        final Response response = target("weblink-resource").request().post(entity, Response.class);
        final URI location = response.getLocation();
        WebLinkTest.LOGGER.debug(location.toString());
        final Set<Link> links = response.getLinks();
        for (final Link link : links) {
            WebLinkTest.LOGGER.debug(link);
        }
        final Book book = response.readEntity(Book.class);
        WebLinkTest.LOGGER.debug("POSTED::" + book);
        Assert.assertEquals("WEBLINK", book.getBookName());

        final Client client = ClientBuilder.newClient();
        final WebTarget target = client.target(location);
        final Response response2 = target.request().get();
        final Book book2 = response2.readEntity(Book.class);
        WebLinkTest.LOGGER.debug("GET::" + book2);
        Assert.assertEquals("WEBLINK", book2.getBookName());
    }
}
``` 

### 4.2 结构型链接
HATEOAS用以代替聚集数据并避免描述膨胀，通常使用Atom格式在实体字段中提供链接信息。[示例代码](https://github.com/feuyeux/jax-rs2-guide/blob/master/sample/3/simple-service-3/src/main/java/com/example/link/HATEOASResource.java)

## 5. REST响应处理 
REST的响应处理结果应包括HTTP状态码、响应实体的媒体参数类型、返回值类型以及异常情况处理。

### 5.1 返回类型
JAX-RS 2.0支持4种返回值类型的响应。

**（1）void** 在返回值类型为void的响应中，其响应实体为空，HTTP状态码为204.

**（2）Response** 响应实体为Response类的entity()方法定义的实体类实例。如果该内容为空，则HTTP状态码为204，否则为200 OK. 参见3.1的代码。

**（3）GenericEntity** 不常用。其形式是构造一个统一的实体实例并将其返回。实体实例作为第一个参数，实体类型作为第二个参数。

**（4）自定义类型** 即返回自定义的POJO类型，前述代码中已经有很多例子。

### 5.2 处理异常
处理异常包括异常的定义和错误状态码的正确返回。

#### 5.2.1 处理状态码
JAX-RS 2.0规定的REST式WEB服务的基本异常类型为运行时异常WebApplicationException类，该类包括3个主要子类：

* RedirectionException HTTP状态码3xx的重定向类
* ClientErrorException HTTP状态码4xx的请求错误类
* ServerErrorException HTTP状态码5xx的服务器错误类

除了上面的标准异常，也可以定义业务相关的异常类。示例：

```java
public class Jaxrs2GuideNotFoundException extends WebApplicationException {
    private static final long serialVersionUID = 1L;

    public Jaxrs2GuideNotFoundException() {
        super(javax.ws.rs.core.Response.Status.NOT_FOUND);
    }

    public Jaxrs2GuideNotFoundException(String message) {
        super(message);
    }
}
```

#### 5.2.2 ExceptionMapper
Jersey提供了更通用的异常处理方式。通过实现ExceptionMapper接口并使用@Provider注解将其定义为一个Provider，可以实现通用的异常的面向切面处理。示例：

```java
@Provider
public class EntityNotFoundMapper implements ExceptionMapper<Jaxrs2GuideNotFoundException> {
    @Override
    public Response toResponse(final Jaxrs2GuideNotFoundException ex) {
        return Response.status(404).entity(ex.getMessage()).type("text/plain").build();
    }
}
```

在上面的代码中，当响应中发生了Jaxrs2GuideNotFoundException异常时，响应流程就会被拦截并补充HTTP状态码和异常消息，以文本作为媒体格式返回给客户端。

## 6. REST内容协商
一个资源可以有不同格式的表述，即响应实体。内容协商是指在服务提供的多种表述中，为特定的请求选择最好的一种表述的处理过程。客户端/浏览器通过使用HTTP Accept、Accept-Charset、Accept-Language和Accept-Encoding头来定义接收头的信息，将其所期待的格式或MIME类型告知服务器，服务器根据协商算法返回客户端可接收的数据信息。

### 6.1 @Produces注解
JAX-RS 2.0对内容协商的支持，是通过@Produces实现的。该注解可以为每种类型定义质量因素（0～1的小数值）。如果不定义则默认为1. 例如：

```java
@GET
@Produces({"application/json; qs=.9", "application/xml; qs=.5"})
@Path("book/{id}")
public Book getBook(@PathParam("id") final Long bookId) {
    return new Book(bookId);
}
```    

客户端也可以指定每种类型的质量因素。内容协商过程通常如下：

* 如果客户端指定了一种类型，且服务端支持，则返回该类型。
* 如果客户端指定了服务端支持的两种类型，则返回服务端质量因素高的那种类型。
* 如果客户端指定了服务端支持的两种类型，同时客户端指定了类型的质量因素，则返回客户端质量因素高的那种类型。

### 6.2 @Consumes注解
@Consumes注解用于定义方法的请求实体的数据类型，它只用于匹配请求处理的方法，不做内容协商使用。如果匹配不到，则服务器返回HTTP状态码415（Unsupported Media Type）。


参考：《Java RESTful Web Service实战》





