---
layout: post
title: "MongoDB学习"
date: 2015-05-19 22:09:05 +0800
comments: true
toc: true
toc: true
categories: 
- DB
---

MongoDB是一款强大、灵活的通用型面向文档的数据库。它被设计成具有非常好的水平扩展能力，很容易在多台服务器之间进行数据分隔。它能自动处理跨集群的数据和负载，自动重新分配文档，以及将用户请求路由到正确的机器上。本篇学习MongoDB的基础知识。

<!--more-->

## 1. MongoDB Intall and launch

```
$ brew install mongodb
==> Downloading https://homebrew.bintray.com/bottles/mongodb-3.0.2.yosemite.bott
######################################################################## 100.0%
==> Pouring mongodb-3.0.2.yosemite.bottle.2.tar.gz
==> Caveats
To have launchd start mongodb at login:
    ln -sfv /usr/local/opt/mongodb/*.plist ~/Library/LaunchAgents
Then to load mongodb now:
    launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mongodb.plist
Or, if you don't want/need launchctl, you can just run:
    mongod --config /usr/local/etc/mongod.conf
```    

## 2. MongoDB基础知识
#### 文档
`{“name”: “Jason”, “gender”: “male”}`就是一个文档，文档由键值对组成，相当于RDB的一行。键有以下约束：

* 不能含有`\0`（空字符串），它用于表示键结尾
* `.`和`$`有特殊意义，也不要使用

#### 集合
相当于RDB的表，但集合中的每个文档的键和值类型都可以不一样。集合的命名有以下约束：

* 必须是UTF-8字符串
* 集合名不能是空字符串、不能包含`\0`、不能以system.开头，不能包含`$`

可以使用子集合来分隔不同命名空间。例如：blog.posts，blog.authors。

#### 数据库
多个集合组成数据库。一个MongoDB实例可以有多个数据库。数据库名就是相应的文件名，因此文件名的约束也适用于数据库名。同时不能使用以下数据库名：admin, local和config。

#### MongoDB shell
MongoDB自带JavaScript shell。在命令行运行: `mongo`。shell内置了帮助文档，使用help命令查看。

使用shell执行脚本：`mongo script1.js script2.js`, 或者：`> load("script1.js")`

shell辅助函数：`use DBNAME`, `show dbs`, `show collections`

如果希望某些脚本在shell启动时自动运行，可以放到~/.mongorc.js中。

#### 数据类型

* null 
* boolean
* 数值，默认使用64位浮点型。对于整数可以使用NumberInt(4byte)和NumberLong(8字节) `{"x": NumberInt("3")}`
* 字符串
* 日期，`{"x": new Date()}` 注意一定要使用`new Date()`而非`Date(...)`。前者是日期类型，而后者是日期的字符串。
* 正则表达式，`{"x": /foobar/i}`
* 数组
* 内嵌文档
* 对象id, 12字节ID，是文档的唯一标识.
* 二进制数据，不能直接在shell中使用
* 代码，`{"x": function(){/*...*/}}`

MongoDB的文档必须有`_id`键，如果没有的话系统会自动创建一个。它可以是任何类型，默认为ObjectId对象。ObjectId为12字节，格式如下：

![image](/myresource/images/image-blog-2015-05-23-10.09.09.png)

## 3. 插入

```
> db.foo.insert({"bar": "baz"})
批量插入
> db.foo.batchInsert([{"a": "a"}, {"b": "b"}])
```

如果需要从MySQL导入原始数据，可以使用命令mongoimport。

## 4. 删除

```
> db.foo.remove({"price": 0})
删除所有foo集合的所有文档!
> db.foo.remove() 
整个集合被干掉
> db.foo.drop() 
```

## 5. 更新
### 5.1 文档替换

```
> var joe = db.people.findOne({"name":"joe"})
> joe.name = "joe2"
> db.people.update({"_id": joe._id}, joe)
```

### 5.2 使用修改器
#### 5.2.1 `$inc`

```
> db.people.update({"name": "someone"}, 
    {"$inc": {"salary": 1000}})
```

#### 5.2.2 `$set` 修改指定字段，如果不存在就创建

```
> db.blog.update({"_id": joe._id},
    {"$set": {"favorite book": "War and Peace"}})
```

#### 5.2.3 `$unset` 删除键

```
> db.blog.update({"_id": joe._id}, {"$unset": {"favorite book": 1}})
```

### 5.3 数组修改
#### 5.3.1 `$push`向数组添加元素

```
//在comments数组末尾加入一元素，如果数组不存在则自动创建
> db.blog.update({"_id": joe._id}, 
    {"$push": 
        {"favorite books": {"title":"Book A"} }
    })
//一次添加多个元素, 使用$each
> db.blog.update({"_id": joe._id}, 
    {"$push": 
        {"favorite books": 
            {"$each": [{"title": "Book B"}, {"title": "Book C"}]} 
        }
    }) 
//添加元素时，限制数组最大10个元素
> db.blog.update({"_id": joe._id}, 
    {"$push": 
        {"favorite books": 
            {"$each": [{"title": "Book D"}, {"title": "Book E"}],
             "$slice": -10
            } 
        }
    })  
//添加元素时，限制数组最大6个元素，并且先进行排序
>db.blog.update({"_id": joe._id}, 
    {"$push": 
        {"favorite books": 
            {"$each": [{"title": "Book J"}, {"title": "Book K"}],
			 "$slice": -6,
			 "$sort" : {"title": 1}  //1表示按title升充，-1表示降序
            } 
        }
    })        
```

#### 5.3.2 `$addToSet` 将数组当集合用，避免重复元素

可将上例中的`$push`换成`$addToSet`。

#### 5.3.3 删除数组元素的方法：

* 把数组当成队列或栈，从任一端删除元素：{"$pop": {"key": 1}} 从数组key的末尾删除，如果把1改成-1则从头部删除。
* 删除特定元素：{"$pull": {"todo": "laundry"}}, 将删除所有匹配的元素。

### 5.4 Upsert修改
相当于Oracle的merge语句，存在则修改，不存在则创建。update的第3个参数设置为true表示这是个upsert:

```
> db.analytics.update({"url": "/blog"}, {"$inc", {"pageviews":1}}, true)
```

save是一个shell函数，只有一个参数。如果文档含有“_id”键，则save调用upsert，否则调用insert。

### 5.5 更新多个文档
默认update方法只更新匹配的第一个文档，将update的第4个参数设置为true则更新所有匹配文档。

### 5.6 返回被更新的文档
如果有一个队列，需要进行原子性的取值和赋值，使用findAndModify就非常方便。它能够在一个操作中返回匹配的结果并且进行更新。

## 6. 查询
### 6.1 find
find方法用于查询，第1个参数是条件，为空时表示查询所有文档。

```
> db.blog.find()
> db.blog.find({"title": "My bolg", "author": "joe"})
```

与RDB的select语句一样，find方法的第2个参数可以设置返回哪些键值对（字段值）。默认情况下“_id”键总是被返回。下例中“1”表示返回，“0”表示不返回：

```
> db.users.find({}, {“username”: 1, "email": 1})
> db.users.find({}, {“username”: 1, "_id": 0})
```

### 6.2 查询条件
可以使用"$lt"、"$lte"、"$gt"、"$gte"和"$ne" 作为比较符，分别对应 `<, <=, >, >=, <>`:

```
> db.users.find({"age": {"$gt": 18, "$lte": 30}})
> db.users.find({"username": {"$ne": "joe"}})
```

也可以使用"$in"、"$or"、"$and"和"$mod"等操作符：

```
> db.raffle.find({"ticket_no": {"$in": [725, 511, 339]}})
> db.raffle.find({"$or", [{"ticket_no": 725}, {"winner": true]})
> db.raffle.find({"$or", [{"ticket_no": {"$in": [725, 511, 339]}}, 
    {"winner": true]})
//$mod表示取模，用id_num / 5 ，余数是否为1    
> db.users.find({"id_num": {"$not": {"$mod": [5,1]}}})
```

### 6.3 特定类型的查询
#### 6.3.1 null
与RDB一样，null作为条件时不能使用=。应该使用：

```
> db.c.find({"z": null})
```

但上面的例子不仅匹配了z为null的文档，还包括键“z”不存在的文档。因此还可以使用'$exists'进行判断：

```
> db.c.find({"z": {"$in": [null], "$exists": true}})
```

#### 6.3.2 正则表达式
MongoDB使用Perl兼容的正则表达式库。如要查找所有名为Joe，且不区分大小写：

```
> db.users.find({"name": /joe/i})
```

#### 6.3.3 查询数组
假设我们有这样一个数组：{"fruit": ["apple", "banana", "peach"]}，下表演示了各种数组查询：

匹配 | 查询语句 | 说明 
---|---|---
Y | db.food.find({"fruit", "banana"}) | 匹配1个元素
Y | db.food.find({"fruit": {"$all":["apple", "peach"]}}) | $all用于多个元素匹配
Y | db.food.find({"fruit": ["apple", "banana", "peach"]}) | 完全匹配
N | db.food.find({"fruit": ["apple", "banana", "peach2"]}) | 
N | db.food.find({"fruit": ["peach", "apple", "banana"]}) | 
Y | db.food.find({"fruit.2": "peach"}) | 使用key.index指定下标
Y | db.food.find({"fruit": {"$size": 3}}) | 数组长度匹配，注$size不能与$gt组合使用，这种情况可能需要增加一个键来表示size

**$slice操作符**

前面提到find的第二个参数是可选的，用于指定要返回的键。$slice操作符可以用来返回数组的一个子集，也是放到find的第二个参数中。

```
//返回数组的前面2个
> db.food.find({}, {"fruit": {"$slice": 2}})
{ "_id" : ObjectId("55618ad3a13452c2fde037bd"), "fruit" : [ "apple", "banana" ] }
//返回数组的后面2个
> db.food.find({}, {"fruit": {"$slice": -2}})
{ "_id" : ObjectId("55618ad3a13452c2fde037bd"), "fruit" : [ "banana", "peach" ] }
//跳过前5个元素，返回第6-15个元素
> db.food.find({}, {"fruit": {"$slice": [5, 10]}})
```

除非特别声明，否则使用$slice时将返回文档中的所有键。

#### 6.3.4 查询内嵌文档
以下演示内嵌文档的查询，假设有如下文档：

```
{
	"name": {
		"first": "Joe",
		"last": "Schmoe"
	},
	"age": 45
}

查询方法：
> db.people.find({"name.first": "Joe", "name.last": "Schmoe"})
```

### 6.4 $where查询
要严格限制或消除$where查询，禁止终端用户使用任意的$where语句。因为它的效率非常低，其过程是将BSON转换成JavaScript对象，然后执行$where的JavaScript方法，所以性能非常差。示例如下：

```
> db.foo.find({"$where": function() {
    for(var current in this) {
    	if (...) {
    		return true;
    	}
    }
 }});
```

### 6.5 服务端脚本
要特别注意服务器上执行JavaScript的安全性，它同样存在注入的风险。确保不直接将用户输入的内容传递给mongod。例如：

```
//危险代码！如果name是用户定义的变量，就可能被替换成危险操作
> func = "function(){ print('Hello, "+name+"!');}"
//Python的解决办法：
> func = pymongo.code.Code("function() { print('Hello, '+username+'!'); }", {"username": name})
```

### 6.6 游标

```
> var cursor = db.blog.find();
> while (cursor.hasNext()) {
    obj = cursor.next();
    //...
  }

or
> var cursor = db.blog.find();
> cursor.forEach(function(x) {
    print(x.name);
  }); 
  
其它功能：
> db.c.find().limit(3)
> db.c.find().skip(3)
//排序：1为升序，-1为倒序
> db.c.find().sort({username: 1, age: -1})   
> db.stock.find({"desc": "mp3"}).limit(50).sort({"price", -1})
```

注意，尽量不要使用skip来进行分页，当数据比较多时，速度会变得很慢。

