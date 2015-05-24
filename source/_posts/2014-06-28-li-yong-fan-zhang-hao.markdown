---
layout: post
title: "利用反射和代理创建简单的安全账号"
date: 2014-06-28 11:42:34 +0800
comments: true
toc: true
categories: 
- Java

---

在实际业务中，总是会遇到权限管理和安全方面的需求。以一个帐户类（Account）为例，它实现了帐户的基本信息和余额管理。新的需求是余额修改相关的方法只能由授权用户调用。那么是不是直接修改Account类，在相关方法中加入权限验证代码呢？这样势必会让原来的代码变得混乱，破坏单一职责原则。应该怎么办呢？

<!--more-->

开闭原则告诉我们对扩展开放、对修改关闭。我们可以通过代理类实现这个业务需求。这是一个简单的示例，用于演示反射和代理的使用，并不能直接用于生产环境，仅仅提供一种思路供参考。

首先看看这个示例的整体结构图：

![image](/myresource/images/IMG_blog_20140628.jpg)


Accountable接口:

```java
public interface Accountable {
    public BigDecimal getBalance() ;
    public String getBankAba() ;
    public void setBankAba(String bankAba) ;
    public String getBankAccountNumber() ;
    public void setBankAccountNumber(String bankAccountNumber) ;
    public BankAccountType getBankAccountType() ;
    public void setBankAccountType(BankAccountType bankAccountType) ;

    public void credit(BigDecimal amount);
    public void transferFromBank(BigDecimal amount);
}
```

静态工厂方法封装具体的接口实现，客户端并不关心实现类是Account还是SecureProxy类。代码如下：

```java
public class AccountFactory {
    private AccountFactory() {
        throw new AssertionError("作为静态工厂，不允许实例化！");
    }

    public static Accountable create(Permission permission) {
        //如果有修改权限则返回Account，否则返回有权限限制的代理。
        switch (permission) {
            case UPDATE:
                return new Account();
            case READ_ONLY:
                return createSecuredAccount();
        }

        return null;
    }

    private static Accountable createSecuredAccount() {
        SecureProxy secureAccount = new SecureProxy(new Account(),
                //传入不允许调用的方法名
                "credit",
                "setBankAba",
                "setBankAccountNumber",
                "setBankAccountType",
                "transferFromBank");

        //这句是关键
        return (Accountable) Proxy.newProxyInstance(
                Accountable.class.getClassLoader(),
                new Class[] {Accountable.class},
                secureAccount
        );
    }
}
```

最后的return语句是动态建立代理的关键，第一个参数是接口的类加载器；第二个参数是接口类型的数组（这就是创建数组的语法），表示你希望代理类实现哪些接口；第三个是具体的代理对象。详细请参考[JavaDoc](http://docs.oracle.com/javase/7/docs/api/java/lang/reflect/Proxy.html)。

SecureProxy的实现：

```java
public class SecureProxy implements InvocationHandler {
    //需要授权的方法
    private List<String> secureMethods;
    //被代理对象
    private Object target;

    public SecureProxy(Object target, String... secureMethods) {
        this.target = target;
        this.secureMethods = Arrays.asList(secureMethods);
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        try {
        		//权限验证
            if (isSecure(method)) {
                throw new PermissionException();
            }

            //调用真正的方法
            return method.invoke(target, args);
        } catch (InvocationTargetException e) {
            //如果调用真正的方法时有异常，getTargetException就是真正的异常原因。
            throw e.getTargetException();
        }

    }

    private boolean isSecure(Method method) {
        return secureMethods.contains(method.getName());
    }
}
```

注意SecureProxy类并不需要显式实现Accountable接口，因为在静态工厂方法中动态为其指定了将实现的接口。SecureProxy类必须实现InvocationHandler，该接口的一个重要方法就是invoke，客户端调用Accountable接口中的某个方法时，会触发代理的invoke方法，然后在其中调用真正的目标方法。通过isSecure方法来判断是否有权限调用某方法。

总结一下，Account类是真正的业务实现类，SecureProxy作为代理，在Account的基础上增加了安全功能。关键方法包括Proxy.newProxyInstance和InvocationHandler接口。虽然示例太过简单无法用于实际业务，但它演示了**两个重要原则：单一职责和开闭原则！**

注：Proxy.newProxyInstance方法内部会调用sun.misc.ProxyGenerator.generateProxyClass()方法来生成字节码。
