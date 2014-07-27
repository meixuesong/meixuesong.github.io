---
layout: post
title: "Titanium VS Worklight"
date: 2014-07-27 13:52:25 +0800
comments: true
categories: 
- 移动开发

---

因工作需要，对两个跨平台移动开发工具（Titanium，Worklight）进行比较的。本文主要从跨平台特性、性能、社区等进行比较。实际上，本文同样适用于Titanium VS Phonegap。

<!--more-->

##Workligt简介
Worklight是IBM公司的产品，支持HTML5，Hybrid、Native开发方式，涵盖完整的移动应用生命周期，包括开发、运行、安全和管理。

Worklight以Cordova为核心。因此它与Phonegap是非常类似的产品，基于HTML5、CSS3和JavaScript，通过Adapter集成后台REST、SOA等服务。在其PPT中说提供了以下移动开发模式：

![image](/myresource/images/image_blog_2014-07-27_15.16.22.png)

**但找遍其资料也未找到Worklight如何使用第4种开发模式。**

几乎支持所有移动设备：iOS, Android, BlackBerry, Windows Phone。基于Dojo的可视化UI构造。充分利用现有Javascript框架，如jQuery, dojo, Sencha等。

通过Worklight Server提供对企业数据和系统的安全访问：
![image](/myresource/images/image_blog_2014-07-27_15.10.37.png)

### Worklight的工作方式

开发人员采用HTML、CSS和JavaScript在本地开发，就像开发静态Web网站一样。每种移动应用平台都提供了一个嵌入式的Web浏览器，Worklight应用就运行在这样一个浏览器中，因此，Worklight实质上是拥有原生外壳的Html Web应用。

Worklight基于Cordova提供设备的接口，相当于在JavaScript与移动设备的传感器、摄像头间建立了一连接层，使得JavaScript可以访问这些原生接口。

### Worklight的优势
由于其本质是Web应用，因此只要原生平台有Web view，就可以移植到该平台。因此Worklight几乎支持所有移动平台。

采用Html、CSS和JavaScript的技术门槛比较低，同时也有现成的框架可用，如jQuery, dojo, Sencha等。

### Worklight的劣势
Worklight应用的UI性能取决于系统的浏览器性能。iOS平台的基于Webkit引擎的浏览器性能更好，而Android平台则有一些限制。对于其它平台，可能跟OS版本有关系。

同时，与Web开发相似，存在一些跨平台的问题要处理。即使是基于Webkit的环境，[也存在一些明显的区别](http://westcoastlogic.com/slides/debug-mobile/#/17)。在IBM Worklight介绍的PPT中，一个应用示例在移植到Android时仍然使用了4周的时间，见下图：

![image](/myresource/images/image_blog_2014-07-27_18.46.36.png)

现代浏览器已经越来越强大，但即使如此，要在浏览器中达到原生的UI性能，几乎是不可能的。

Cordova提供的原生API非常有限，主要集中在摄像头、加速传感器、定位传感器等，因此平台集成是很有限的。当然有一些插件来填补这一空白，但是它们的质量和可维护性并不稳定。

移动端不支持Sqlite数据库，保存本地数据比较困难。

## Titanium简介
Titanium是Appcelerator推出的跨平台移动应用开发工具，支持Android、Blackberry、iOS和Tizen。

Titanium同样采用JavaScript作为主要开发语言，支持Web应用、混合型应用和原生应用开发。

Titanium也同样提供了相应的云服务，包括推送、同步、企业安全认证和数据安全等。

当开发者开发Titanium应用时，可以用JavaScript编写原生应用，而不只是Web应用。但是，为了充分使用原生API的性能，Titanium并不是“一次编写、到处运行”的平台。Titanium可以让开发者充分利用那些平台特定的特性，它对移动开发的支持包括两部分：

* 移动开发核心部分API，是支持跨平台的，因此这部分代码可以复用。
* 平台特定的API、UI和特性，存在于特定平台中。

例如，你可以在Titanium的iOS应用中，使用某个iOS平台特有的组件，而在Android平台，采用其它方案。

### Titanium的工作方式
Titanium开发的应用在运行时，包括三大组件：

* JavaScript代码
* Titanium的系统原生API
* JavaScript解析器（Android: V8或Rhino；iOS：JavaScriptCore）

当我们用JavaScript创建一个窗口时，会发生什么呢，见下图：

![image](/myresource/images/images_download_attachments_35621751_create_proxy.png)

可以看到，JavaScript代码会调用原生API，创建的是原生的Window，而不是浏览器中的Web对象！因此所有UI与Java或Objective-c开发的原生应用没有区别，它们就是Native UI。

这就是为什么说Titanium是用JavaScript开发原生应用。它不需要浏览器来执行JavaScript代码，JavaScript代码也不会被编译成Java或者Objective-C。JavaScript是在运行时执行，并且在需要时调用原生的UI组件和方法。

开发者可以以原生的方式，自由地扩展Titanium，包括UI和其它不可见的特性。

###Titanium的优势
Titanium提供了广泛的原生特性和功能，包括原生UI组件、网络接口、数据库和系统通知等等。因此Titnaium应用的UI是真正的原生组件，具有与原生应用相同的性能。

Titanium具有广泛的原生应用API。提供了90%以上常用的原生平台API，而剩余不常用的10%可以由用户自己实现。

Titanium应用具有更好的外观，它不需要CSS等来模拟原生界面，因为它自己就是原生界面。例如当你创建了NavigationGroup，在iOS上会创建UINavigationController，它的行为和动画效果都是原生的，更符合用户的预期。

具有非常好的扩展性。开发者能够针对指定平台，实现任何原生的UI，并集成到Titanium应用中。例如，你可以实现一个TableView，滚动时以每秒60帧显示。也可以无缝集成一个OpenGL绘图的游戏，并在JavaScript中执行循环。你可以将这些扩展的UI直接集成到应用中。

原生支持Sqlite数据库。

Titanium基于Apache 2.0开源协议，具有广泛的社区支持。

###Titanium的劣势
Titanium的API范围，使得它在增加一种新的原生平台时，比较困难。这也是为什么现在Titanium只支持iOS、Android、BlackBerry、Tizen和Web的原因。[Titanium对Windows Phone的支持预计在2014年第4季度实现。](http://www.appcelerator.com/blog/2014/01/windows-8-support-whats-going-on/)

## 谁比谁更好？
从1万米高空看，两者没有太大区别，它们都提供了跨平台的移动应用开发能力。而两者间其实不存在谁比谁更好的问题，只看谁比谁更合适！

对于企业移动应用来说，谁更合适？我们先看看企业移动应用有哪些特点：

* 界面以稳健风格为主
* 应用稳定可靠
* 安全性要求高
* 数据量一般比较大
* 性能要求高

对于前面三点，两者没有太多区别，而关于后面两点，Titanium的性能更占优势，而SQLite数据库的支持也有利于部分企业数据（如通讯录）的本地缓存，提升用户体验。下表总结了两者的一些对比：

![image](/myresource/images/image_blog_2014-07-27_18.41.36.png)


### 参考：
[Comparing titanium and phonegap](http://www.appcelerator.com/blog/2012/05/comparing-titanium-and-phonegap/)
