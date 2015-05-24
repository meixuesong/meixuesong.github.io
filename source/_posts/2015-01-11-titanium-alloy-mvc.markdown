---
layout: post
title: "Titanium Alloy MVC"
date: 2015-01-11 19:25:14 +0800
comments: true
toc: true
categories: 
- 移动开发
---
这是一篇学习笔记，主要内容是Alloy的Controller, Model, Collection, View以及Widget.

<!--more-->

## 1. Alloy Controllers

创建Controller和获得View: Alloy.createController and Controller.getView.

可以继承：exports.baseController = 'baseControllerName'，子类继承父类export的方法，并可以重写。

可以在Controller中判断当前平台：OS_ANDROID, OS_BLACKBERRY, OS_IOS, OS_MOBILEWEB, ENV_DEV, ENV_TEST, ENV_PRODUCTION, DIST_ADHOC, DIST_STORE:

`if (OS_IOS) {...}`


传参：

```javascript
//index.js
var arg = {
        title: source[i].postTitle,
        url: source[i].postLink
    };
    data.push(Alloy.createController('row', arg).getView());

//row.js
var args = arguments[0] || {};
$.rowView.title = args.title || '';
$.rowView.url = args.url || '';

```

使用Alloy.Globals命名空间可以保存全局变量：`Alloy.Globals.xxx = ...`

alloy.js运行于应用的生命周期之前，会在index.js加载之前调用，也就是任何UI加载之前。

lib文件夹用于类库，也可以建立平台子文件夹（如ios）。但require时，不需要指定平台名。

当前，Controller已经默认加载了Alloy, Underscore.js和Backbone.js，但以后可能需要自己加载：

```javascript
var Alloy = require('alloy'), _ = require("alloy/underscore")._, Backbone = require("alloy/backbone");
```

## 2. Alloy Models
### 2.1 Alloy Collection and Model Objexts
#### 2.1.1 Models
In Alloy, models inherit from the [Backbone.Model](http://docs.appcelerator.com/backbone/0.9.2/#Model) class.

```javascript
exports.definition = {
    config : {
 // table schema and adapter information
    },
    extendModel: function(Model) {		
        _.extend(Model.prototype, {
 // Extend, override or implement Backbone.Model 
        });
 
 return Model;
    },
    extendCollection: function(Collection) {		
        _.extend(Collection.prototype, {
 // Extend, override or implement Backbone.Collection 
        });
 
 return Collection;
    }
}
```

在Controller中访问Model:

```javascript
var book = Alloy.createModel('book', {title:'Green Eggs and Ham', author:'Dr. Seuss'}); 
var title = book.get('title');
var author = book.get('author');
// Label object in the view with id = 'label'
$.label.text = title + ' by ' + author;
```

全局Model单例：

```javascript
// This will create a singleton if it has not been previously created,
// or retrieves the singleton if it already exists.
var book = Alloy.Models.instance('book');
```

##### 2.1.1.1 定义表结构
config对象有三部分：columns, defaults和adapter. 

columns定义表结构。对应SQLite，支持以下类型：string, varchar, int, tinyint, smallint, bigint, double, float, decimal, number, date, datetime and boolean，其它未知类型将视为TEXT。

defaults对象用于设置默认值。

adapter对象定义存储接口。

```
exports.definition = {
    config: {
 "columns": {
 "title": "String",
 "author": "String",
 "book_id": "INTEGER PRIMARY KEY AUTOINCREMENT" //自增长
        },
 "defaults": { //默认值
 "title": "-",
 "author": "-"
        },
 "adapter": { 
 "type": "sql", //存储类型SQLite
 "collection_name": "books", //表名
  "idAttribute": "book_id" //主键
        }
    }
}
```

##### 2.1.1.2 Extending the Backbone.Model Class
在extendModel中扩展方法，例如validate方法.

#### 2.1.2 Collections

在Controller中创建Collection，作用域为本Controller:

```
var library = Alloy.createCollection('book'); 
library.fetch(); // Grab data from persistent storage 
```

创建全局单例Collection:

```
// This will create a singleton if it has not been previously created,
// or retrieves the singleton if it already exists.
var library = Alloy.Collections.instance('book');
```

在extendCollection中定义扩展Backbone的方法，例如：

```
// Implement the comparator method.
comparator : function(book) {
	return book.get('title');
}
```            

Backbone.Collection继承了underscore的一些集合操作方法，例如迭代：

```
var data = [];
library.map(function(book) {
 // The book argument is an individual model object in the collection
    var title = book.get('title');
    var row = Ti.UI.createTableViewRow({"title":title});
    data.push(row);
});
// TableView object in the view with id = 'table'
$.table.setData(data);
```

事件处理：use the Backbone.Events on, off and trigger methods

```
var library = Alloy.createCollection('book');
function event_callback (context) {
	var output = context || 'change is bad.';
    Ti.API.info(output);
};
// Bind the callback to the change event of the collection.
library.on('change', event_callback);
// Trigger the change event and pass context to the handler.
library.trigger('change', 'change is good.');
// Passing no parameters to the off method unbinds all event callbacks to the object.
library.off();
// This trigger does not have a response.
library.trigger('change');
```

注意：如果事件名称不要使用空格。因为Backbone使用了空格来处理多事件。

### 2.2 Alloy Data Binding
当Collection或Model变化时，View也跟随变化，这就是绑定.

**注意：如果使用绑定，必须在controller关闭时，调用`$.destroy()`方法，以避免内存泄露:**

```
$.win.addEventListener("close", function(){
    $.destroy();
} 
```

#### 2.2.1 Collection-View Binding
以下View对象支持Collection绑定：

View Object | Add data binding attributes to... | Repeater Object
---|---|
ButtonBar | `<Labels>` | `<Label/>`
CoverFlowView | `<Images>` | `<Image/>`
ListView | `<ListSection>` | `<ListItem/>`
Map Module | `<Module module="ti.map" method="createView">`  | `<Annotation/>`
Picker | `<PickerColumn>` or `<Column>` | `<PickerRow/>` or `<Row/>`
ScrollableView | `<ScrollableView>` | `<View/>`
TableView | `<TableView>` | `<TableViewRow/>`
TabbedBar | `<Labels>` | `<Label/>`
Toolbar | `<Items>` | `<Item/>`
View | `<View>` | 除了Window和TabGroup之外的View对象

在XML中定义以下元素，其中只有dataCollection是必须的：

* dataCollection: 指定一个Collection
* dataTransform: 回调方法，传入model，返回修改的JSON对象
* dataFilter: 过滤collection, 传入collection, 返回model数组
* dataFunction: 指定一个方法名，controller使用这个方法来更新view。这个方法不是controller中声明的方法。该属性创建一个别名访问内在的绑定方法。（[没搞懂](http://docs.appcelerator.com/titanium/latest/#!/guide/Alloy_Data_Binding-section-36739592_AlloyDataBinding-BackboneBinding)）

对于Collection中的model，xml中可以使用`{}`来获取model的值，例如：`<Label text="{title} by {author}" />`。

在repeater对象的controller中，可以使用`$model`来引用当前model。如`$model.title`

Collection绑定示例：

```
app/views/index.xml
<Alloy>
    <Collection src="book"/>
    <Window backgroundColor="white" onClose="cleanup">
        <ScrollableView dataCollection="book">
            <View layout="vertical">
                <ImageView image="{cover}" />
                <Label text="{title} by {artist}" />
            </View>
        </ScrollableView>	
    </Window>
</Alloy>

app/controllers/index.js
$.index.open();
Alloy.Collections.album.fetch();
 
function cleanup() {
    $.destroy();
}

```

#### 2.2.2 Model-View Binding

```
<Alloy>
    <Model src="settings"/>
    <Window backgroundColor="white" onClose="cleanup">
        <View layout="vertical">
            <Label text="Text Size" />
            <Slider value="{settings.textsize}" max="5" min="1"/>
            <Label text="Bold"/>
            <Switch value="{settings.bold}" />
            <Label text="Italics"/>
            <Switch value="{settings.italics}" />
        </View>
    </Window>
</Alloy>
```

上例中，获取值使用的格式为：`{modelName.attrName}`

#### 2.2.3 Collection方法示例

```
app/views/index.xml
<Alloy>
    <Collection src="book" />
    <Window class="container">
        <TableView dataCollection="book"
                   dataTransform="transformFunction"
                   dataFilter="filterFunction"
                   dataFunction="updateUI"
                   onDragEnd="refreshTable">
            <!-- Also can use Require -->
            <TableViewRow title="{title}" />
        </TableView>
    </Window>
</Alloy>

app/controllers/index.js
$.index.open();
 
// Encase the title attribute in square brackets
function transformFunction(model) {
 // Need to convert the model to a JSON object
    var transform = model.toJSON();
    transform.title = '[' + transform.title + ']';
 // Example of creating a custom attribute, reference in the view using {custom}
    transform.custom = transform.title + " by " + transform.author;
 return transform;
}
// Show only book models by Mark Twain
function filterFunction(collection) {
 return collection.where({author:'Mark Twain'});
}
 
function refreshTable(){
 // Trigger the binding function identified by the dataFunction attribute
    updateUI();
}
// Trigger the synchronization
var library = Alloy.Collections.book;
library.fetch();
 
// Free model-view data binding resources when this view-controller closes
$.index.addEventListener('close', function() {
    $.destroy();
});
```

当数据变化时，上面的例子中的界面会跟着变化。如果想避免发生变化，可以在调用Backbone方法修改model数据时指定参数：`{silent:true}`.

### 2.3 Alloy数据持久化与升级
Model数据可以同步到本地或远程服务器。这项功能使用的是Backbone sync方法。

#### 2.3.1 Backbone同步方式

Backbone sync时，默认会执行RESTful JSON请求到Model.urlRoot或者Collection.url。读操作使用GET方法，写操作使用POST方法。不论Model是否定义了自己的主键，Backbone都会创建Client ID(cid)。在未保存前，可以使用Model.cid或者Collection.getByCid方法来存取数据。Backbone同步示例：

```
// Since the urlRoot attribute is defined, all HTTP commands are to /library
var Book = Backbone.Model.extend({urlRoot:'/library'})
var book = new Book();
 
// Performs a POST on /library with the arguments as a payload and the server returns the id as 1
book.save({title:'Bossypants',author:'Tina Fey',checkout:false}) 
 
// Performs a GET on /library/1
book.fetch({id:1}); 
 
// Performs a PUT on /library/1 with the entire modified object as a payload.
book.save({checkout:true});
 
// Performs a DELETE on /library/1
book.destroy();
```

#### 2.3.2Alloy的同步方式

Alloy支持SQLite或者properties来保存数据。Alloy查询SQLite时，可以使用简单查询或者prepared statement:

```javascript
var library = Alloy.createCollection('book');
// The table name is the same as the collection_name value from the 'config.adapter' object. This may be different from the model name.
var table = library.config.adapter.collection_name;
// use a simple query
library.fetch({query:'SELECT * from ' + table + ' where author="' + searchAuthor + '"'});
// or a prepared statement
library.fetch({query: { statement: 'SELECT * from ' + table + ' where author = ?', params: [searchAuthor] }});

//查询1条记录：
myModel.fetch({id: 123});
// is equivalent to
myModel.fetch({query: 'select * from ... where id = ' + 123 });
```

#### 2.3.3 数据库迁移（升级或降级）
Alloy采用migration对象来迁移数据库。首先，要将相应的JavaScript文件放在app/migrations文件夹下。文件名采用以下格式：`YYYYMMDDHHmmss_MODELNAME.js`，例如20150120160155_book.js。Alloy将升序执行js文件以完成数据库迁移。

JavaScript文件中要实现两个方法：migration.up(migrator) 和 migration.down(migrator)。migrator对象的值如下：

Key | Description
---|---
db | Ti.Database实例，可以调用db.execute方法执行SQL。**注意不要关闭或打开另一个实例。**
dbname | 数据库名
table | table名，也就是Model的config.adapter.collection_name值
idAttribute | 主键字段名
createTable | 创建表的方法，参数为Model config.columns
dropTable | 删除表
insertRow | 插入行, 参数为待插入的数据对象
deleteRow | 删除行，参数为待删除的数据对象

下面的示例先创建表将初始数据，之后进行了升级:

```
app/migrations/20120610049877_book.js
var preload_data = [
	{title: 'To Kill a Mockingbird', author:'Harper Lee'}
];
 
migration.up = function(migrator)
{
    migrator.createTable({
 "columns":
        {
 "book": "TEXT",
 "author": "TEXT"
        }
    });
 for (var i = 0; i < preload_data.length; i++) { 
	    migrator.insertRow(preload_data[i]);
    }
};
 
migration.down = function(migrator)
{
    migrator.dropTable();
};

//升级app/migrations/20130118069778_book.js
migration.up = function(migrator) {
    migrator.db.execute('ALTER TABLE ' + migrator.table + ' ADD COLUMN isbn INT;');
};
migration.down = function(migrator) {
    var db = migrator.db;
    var table = migrator.table;
    db.execute('CREATE TEMPORARY TABLE book_backup(title,author,alloy_id);')
    db.execute('INSERT INTO book_backup SELECT title,author,alloy_id FROM ' + table + ';');
    migrator.dropTable();
    migrator.createTable({
        columns: {
            title:"TEXT",
            author:"TEXT",
        },
    });
    db.execute('INSERT INTO ' + table + ' SELECT title,author,alloy_id FROM book_backup;');
    db.execute('DROP TABLE book_backup;');
};
```

## 3. Alloy Widgets
在Alloy XML Markup中已经介绍了如何使用Widgets，这里主要介绍如何创建Widgets。

Widgets应放在app/Widgets文件夹下，与app文件夹一相，每个Widget也有自己的views, controllers, models, styles and assets等。在Widget中不能访问除了i18n之外的文件。其它主要区别如下：

* 使用WPATH()来自动处理assets和libs的路径总是。例如要在Widget中require `app/widgets/foo/lib/helper.js`，可以`require(WPATH('helper'))`。对于`app/widgets/foo/assets/images/foo.png`使用`WPATH('images/foo.png')`。
* Widgets使用自己的配置文件widget.json
* Widgets的主controller是widget.js，而不是index.js。创建widget内的另一个controller需要使用Widget.createController方法。
* 所有Widget控制器中的方法均为私有方法，除非使用$，例如`$.init=function(){...}`，然后就可以在项目中调用：`$.fooWidget.init()`.
* Widget中也可以创建Model和Collection, 但要使用Widget.createModel和Widget.createCollection方法。
* 样式文件为widget.tss
* Widget同样可以有Theme, 相关样式和资源要放到：`app/themes/<THEME_NAME>/<WIDGET_NAME>`。
* Widget的主View是widget.xml而不是index.xml。当Widget中的某个view指定了id(eg. buttonId)时，在项目中可以这样引用：`$.fooWidget.buttonId.xxx`
* Widget可以包含其它Widget。需要在widget.json中定义依赖。在controller中可以调用：`Widget.createWidget(widget_name, [controller_name])`
