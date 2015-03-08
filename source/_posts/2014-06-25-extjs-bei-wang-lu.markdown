---
layout: post
title: "Extjs 备忘录"
date: 2014-06-25 12:13:29 +0800
comments: true
categories: 
- Web相关
---

今天改点老程序，用到了Extjs，记录一下遇到的问题和解决办法。

<!--more-->

##JavaScript字符串替换

根据Ext文档，有多种替换方式。我想要不区分大小写的替换，而目前Extjs文档中提供的方法无效。

```javascript
//Extjs文档：
var str = "Apples are round, and apples are juicy.";
var newstr = str.replace("apples", "oranges", "gi");
print(newstr);
//！文档说结果为： "oranges are round, and oranges are juicy."， 
```

但上面的代码并没有产生预期的效果，第一个Apples并没有被替换。改用以下方法实现：

```javascript
replaceIgnoreCase : function(str, searchStr, replaceStr) {
        var regEx = new RegExp(searchStr, "ig");
        var str = str.replace(regEx, replaceStr);

        return str;
}

var result = this._replaceIgnoreCase('This iS IIS', 'is', 'as'); 

//result为：Thas as Ias
```

设置Extjs Grid Panel的行高

```css
//gridPanel的定义中：

viewConfig: {                               
  getRowClass: function (record, rowIndex, rp, store) {
    return "grid-row-height";
  }
},

//CSS定义：
.grid-row-height {
    height: 35px;
}
```

##设置Extjs Grid 单元格中的文字自动换行

Extjs gridPanel单元格的内容如果超出，默认是显示三个点，要想让它换行，其实很简单：

```
//gridPanel的定义，注意tdCls
columns: [
            {
                header: 'Sentence',
                dataIndex: 'sentence',
                flex: 2,
                renderer: this.sentenceRenderer,
                tdCls:'wrap-text'
            },    


//CSS定义
td.wrap-text div {
    white-space: normal;
}
```

##设置Extjs Grid 单元格中的文字换行后的行高

Extjs gridPanel单元格的内容自动换行号，默认行高太小，只需将上面的CSS修改为：

```css
//CSS定义
td.wrap-text div {
    white-space: normal;
    line-height: 130%;
}

//130%表示1.3倍行高。
```
