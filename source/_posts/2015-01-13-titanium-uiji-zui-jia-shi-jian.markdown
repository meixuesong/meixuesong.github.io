---
layout: post
title: "Titanium UI及最佳实践"
date: 2015-01-13 21:05:37 +0800
comments: true
toc: true
categories: 
- 移动开发
---

学习Titanium的UI，以及Titanium相关的最佳实践。

<!--more-->

## 1. User Interface
### 1.1 基础
布局属性：

* width
* height
* left
* right
* top
* bottom
* center: 其属性x和y，表示view中心相对父容器的left, top
* layout: "vertical", "horizontal" or "composite"，默认为composite，值absolute也是composite
* size: 只读，当自己与下级渲染完后才有值。
* rect: 只读
* zIndex: 整数，值大的位于上层

Titanium.UI.FILL and Titanium.UI.SIZE

Name | Notes
---|---
width | If width is defined, it takes precedence and the positioning pins are not used to determine the view's width. If width is not defined, and at least two horizontal positioning pins are defined, the width is calculated implicitly from the pins. For example, left and right or left and center.x. If all three horizontal pins are defined, the width is determined by the left and center.x pins. If width cannot be implicitly calculated it follows the view's default sizing behavior.
left | If left is defined, it always takes precedence for positioning the view horizontally.
center.x | Used to position the view horizontally if left is not set. If left is set, this property is not used to position the view, although it may be used to determine its width.
right | Used to position the view horizontally when neither left or center.x is set. If either left or center.x is set, this property is not used to position the view, although it may be used to determine its width.
height | If height is defined, it takes precedence and the positioning pins are not used to determine the view's height. If height is not defined, and at least two vertical positioning pins are defined, the height is determined implicitly from the pins. If all three vertical pins are defined, the height is determined by the top and center.y pins. If height cannot be implicitly calculated it follows the view's default sizing behavior.
top | If specified, always takes precedence for positioning the view horizontally.
center.y | Used to position the view vertically if top is not set. If top is defined, this property is not used to position the view, although it may be used to determine its height.
bottom | Used to position the view vertically if neither top or center.y is set. If either top or center.y is set, this property is ignored. this property is not used to position the view, although it may be used to determine its height.

为了防止重新布局影响性能，可以使用批量操作：

```javascript
myView.applyProperties({
  top: 50,
  left: 50,
  width: 200
});
```

使用rect属性可以获取控件的位置、大小。由于布局是异步发生，因此可能需要在postlayout事件之后去获取rect。示例如下：

```javascript
var postLayoutCallback  = function(e){
  Ti.API.info(String.format("Layout done, left: %f, width: %f", myView.rect.x, myView.rect.width));
  myView.removeEventListener('postlayout', postLayoutCallback);
}
myView.addEventListener('postlayout', postLayoutCallback);
myView.updateLayout({
  left: '25%',
  width: '25%'
});
```

注意！如果在postlayout事件中修改view的大小，会导致死循环！此外，为了性能，只监听特定view的postlayout事件，而不是整个窗口。一些非布局的参数变化也可能导致触发此事件，例如设置label的text。

**尺寸单位**

Unit | Abbreviation | Note
---|---|---
pixels | px |
density-independent pixels | dip or dp | Equivalent to Apple "points."
inches  | in |
millimeters | mm| Android, iOS only
centimeters | cm | Android, iOS only
points | pt| 1/72 of an inch. Android only. Not to be confused with Apple "points."

On Android, a density-independent pixel (DIP) corresponds to one pixel on a 160DPI display.

On iOS, a DIP corresponds to one pixel on a non-Retina display, which is 163DPI for iPhone/iPod touch and 132DPI for the iPad. A DIP corresponds to 2 pixels of width or height on a Retina display.

如果未指定，系统默认为：Android(pixels), iOS(DIP), WEB(DIP)

**Horizontal and Vertical Layouts**

对于垂直布局，child.width = FILL时，充满父容器的width; child.height = FILL时，充满父容器剩余的高度，后续加入的child将超出父容器高度，因此不可见。

对于水平布局，child一个一个往右排。如果horizontalWrap=true, 排不下时会换行，否则只会排成一行。

这两种情况，left和right都用于水平padding, top和bottom用于垂直位置。

**冲突时的解决办法：**

* 当控件使用SIZE，而计算出来的尺寸超过父容器，则以父容器边界为准。
* 当控件使用FILL，父容器使用SIZE，则父容器按控件FILL走，不停扩大，直到遇到边界限制（例如祖父有限制）。
* 当控件使用百分比，而父容器使用SIZE，结果不确定。

查看[布局示例](http://docs.appcelerator.com/titanium/latest/#!/guide/Transitioning_to_the_New_UI_Layout_System-section-30088148_TransitioningtotheNewUILayoutSystem-BehaviorChangesinRelease2.0)。

### 1.2 事件处理
常用事件：click、swipe、scroll、dblclick、doubletap、touchstart, touchmove, touchend等等。一些模块还有自己的事件。

```
element.addEventListener('event_type', function(e) {
 // code here is run when the event is fired
 // properties of the event object 'e' describe the event and object that received it
	Ti.API.info('The '+e.type+' event happened');
});
```

回调方法的e通常包含以下信息：

* x和y，事件（如touch）发生时，在view内的坐标。
* globalPoint: （仅iOS）事件发生时，在屏幕中的坐标。
* type: 事件类型名
* source: 事件主体

事件可以从当前View往parent View bubbling。Titanium.Event有两个参数控制bubbling: bubbles(boolean)表示事件是否能buggle，只读；cancelBubble(boolean)，如果设置为true则停止bubble。此外，所有View类组件还有一个属性bubbleParent，是可改的。用于表示事件是否bubble给上级。需要注意的是，当手指拿起时，可能触发了touchup, click, tap事件，在touchup事件中设置cancelBubble=true并不会阻止tap或click事件触发和bubble. 在代码中也可以触发事件：

```
someButton.fireEvent('click');
//或者传参
someButton.fireEvent('click', {kitchen: 'sink'});
//注意获取kitchen的代码
someButton.addEventListener('click', function(e){
	Ti.APP.info('The value of kitchen is '+e.kitchen);
});
```

**自定义事件**：

```
deleteButton.addEventListener('click', function(e){
 // when something happens in your app
	database.doDelete(e.whichRecord);
 // fire an event so components can react
	theTable.fireEvent('db_updated');
});
// ... elsewhere in your code
theTable.addEventListener('db_updated', function(e){
	theTable.setData(database.getCurrentRecords());
});
```

**全局事件**，使用Ti.APP。**注意尽量避免使用全局事件**，因为很容易导致内存无法正确释放。

```
deleteButton.addEventListener('click', function(e){
 // when something happens in your app
	database.doDelete(e.whichRecord);
 // fire a global event so components can react
	Ti.App.fireEvent('db_updated');
});
// ... elsewhere in your code
Ti.App.addEventListener('db_updated', function(e){
	theTable.setData(database.getCurrentRecords());
	someOtherComponent.doSomethingElse();
});
```

**移除事件监听：**

```
function doSomething(e) {
 // do something
}
deleteButton.addEventListener('click', doSomething);
// ... elsewhere in your code ...
deleteButton.removeEventListener('click', doSomething);
});
```

**特殊事件：**

Event | Fired when ...
---|---
androidback | The back button is released
androidhome | The home button is released
androidsearch | The search button is released
androidcamera | The camera button is released
androidfocus | Fired when the camera button is pressed halfway and then released.
androidvolup | The volume-up rocker button is released
androidvoldown | The volume-down rocker button is released

所有涉及Ti.的事件都需要在JavaScript与Native之间进行转换，因此尽量使用Underscore的事件处理。另外，将事件监听尽可能地延后，有助于提高系统响应速度。所有全局事件监听一直是活着的，因此监听中引用的局域变量也一直活着，这将可能导致内存泄露。

## 2. Titanium最佳实践
### 2.1 JavaScript建议
避免使用全局变量，Objects are placed in the global scope when:

* You declare a variable outside of a function or CommonJS module. Using a modular pattern will alleviate this problem.
* You omit the var keyword when declaring a variable (within or outside of a function). So always use var when declaring variables.

避免在全局事件监听中引用局部对象，下面的代码是个坏例子：

```
var someFunction = function() {
    var table = Ti.UI.createTableView(),
        label = Ti.UI.createLabel(),
        view = Ti.UI.createView();
    Ti.App.addEventListener('bad:move', function(e) {
        table.setData(e.data);
    });
    view.add(table);
    view.add(label);
 return view;
};
```

所有Ti命名空间都与Native相关，因此应避免通过prototype扩展，同时使用缓存来避免多次调用Native方法。如下例：

```
var isAndroid = (Ti.Platform.osname=='android') ? true : false;
if(isAndroid) {
 // do Android specific stuff
} else {
 // do iOS stuff
}
```

多个Controller以及CommonJS Module之间，可以使用trigger， on等方法实现事件触发和监听。不要使用Ti相关fireEvent，因为只要涉及Ti都会产生Native与Javascript之间的接口。

变量、属性和方法等不要使双下划线，这是Alloy内部使用的。不要使用JavaScript保留关键字。

Wrap self-calling functions in parenthesis， 这种模式有利于包装局部变量。

```
var myValue = function() {
 //do stuff
 return someValue;
}();

//这样写更容易明白返回的是值，而不是一个方法。
var myValue = (function() {
 //do stuff
 return someValue;
})();
```

**提高遍历的效率**，通过保存数组的length:

```
var names = ['Jeff','Nolan','Marshall','Don'];
for(var i=0;i<names.length;i++){
	process(names[i]);
}

// I can check the array length only once
var names = ['Jeff','Nolan','Marshall','Don'];
for(var i=0,j=names.length;i<j;i++){
    process(names[i]);
}
```

### 2.2 CommonJS Module
主要有两种方式来创建CommonJS Module。方式一采用exports方法：

```
exports.sayHello = function(name) {
    Ti.API.info('Hello '+name+'!');
};
exports.version = 1.4;
exports.author = 'Don Thorp';
```

另一种方式公开的方法主要以对象构造器的方式：

```
function Person(firstName,lastName) {
 this.firstName = firstName;
 this.lastName = lastName;
}
Person.prototype.fullName = function() {
 return this.firstName+' '+this.lastName;
};
//注意是module.exports
module.exports = Person;
```

前者使用`exports.xxx`，后者使用`module.exports`，这两种方式不要在同一个module中混合使用！

每个module都有自己的scope，只有export的方法才是公开的。注意如果exports属性，该值可能不会改变：

```
//statefulModule.js
var _stepVal = 5; // default
exports.setPointStep = function(value) {
  _stepVal = value;
};
exports.getPointStep = function() {
 return _stepVal;
};
exports.stepVal = _stepVal;

//app.js
var stateful = require('statefulModule');
stateful.setPointStep(10);
stateful.getPointStep(); //10
stateful.stepVal //值永远是初始值5.
```

### 2.3 数据库
**每次操作都打开并关闭数据库和resultset**

```
cityWeatherRS.close(); // close the resultset when you're done reading from it
db.close(); // and close the database connection
```

**批量操作时，使用事务**

```
var db = Ti.Database.open('myDatabase');
db.execute('BEGIN'); // begin the transaction
for(var i=0, var j=playlist.length; i < j; i++) {
	var item = playlist[i];
	db.execute('INSERT INTO albums (disc, artist, rating) VALUES (?, ?, ?)', item.disc, item.artist, item.comment);
}
db.execute('COMMIT');
db.close();
```

### 2.4 图片
>* PNG – PNG images are in a lossless-compressed format that can support high-color images. This format is best suited to line-art, text, and icons. It is a better choice than GIF in almost all cases.
* JPG – JPG (or JPEG) is lossy-compressed file format best suited for photographs. It is not well-suited for text, line drawings, or icons because of visual artifacts created during the compression process that will reduce quality and readability.
* 因此：
* Photos? Use JPG
* Text, line drawings, icons, button graphics? Use PNG
* Flip-book style animations (for which animated GIFs would be the traditional choice)? Use the ImageView's images property and pass to it an array of PNG or optimized JPG files.


注意：显示JPG图片时，会在内存中解压缩，因此不要一次创建太多的JPG ImageView，否则将耗尽内存。将imageView从view中移除并不会回收内存，还要将imageView设置为null.

为了减少ipa/apk的大小，需要对图片进行优化。见[Titanium文档](http://docs.appcelerator.com/titanium/latest/#!/guide/Image_Best_Practices)。

ImageView已经能够显示本地和远程的图片。显示远程图片时，可以先设置defaultImage，下载成功后会自动显示远程图片。这些图片会缓存，对于Android会缓存到应用退出。要自己控制缓存到本地目录，参考[文档](http://docs.appcelerator.com/titanium/latest/#!/guide/Image_Best_Practices)。

### 2.5 管理内存

除了把View移除外，还需要将它设置为null.

```
var button = Ti.UI.createButton({
 // parameters go here...
});
var view = Ti.UI.createView({
 // some parameters here...
});
view.add(button);
// ... later
win.remove(view);  // view & button still exist
view = null; // deletes the view and its proxy, but not the button!
// compare that to:
var view = Ti.UI.createView({
 // some parameters here...
});
view.add(Ti.UI.createButton({
 // parameters go here...
}));
// ... later
win.remove(view);
view = null; // deletes the view, button, and their proxies
```


