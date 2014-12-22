---
layout: post
title: "基于Jekyll(Octopress)将博客生成EPUB和Mobi电子书"
date: 2014-10-05 21:03:50 +0800
comments: true
categories: 
- others
---
采用Octopress，基于Jekyll，[在GitHub上写博客](/blog/2014/06/25/zai-githubshang-xie-bo-ke/)已经快一年了。随着博客的增多，有了一个想法，如果能将这些博客整理成册，变成电子书放入Kindle，有空时温习一下，那该多好。今天进行了尝试，效果还不错。

<!--more-->

Kindle默认支持的电子书格式是Mobi，但开源软件很少支持这种格式。电子书格式最普及的还是EPUB，而Amazon提供了从EPUB转为Mobi的支持。因此我们的第一步是将博客转换成EPUB格式的电子书。

## 1. 准备工作
在Github上找到了一个项目[Jekyll E-book](https://github.com/lmullen/jekyll-ebook)，支持将Jekyll博客转换成EPUB电子书。按照其说明，以管理员身份安装：

```bash
gem install jekyll-ebook
```

然后安装Pandoc，打开[下载页面](https://github.com/jgm/pandoc/releases)，下载相应系统的安装包，安装完成后，确保命令能够识别：

```bash
pandoc --version
```

现在就可以开始准备生成EPUB电子书了。需要先定义这本书的标题等信息，以及书中包括哪些博客。这些信息都保存在manifest.yml中，这是一个YAML格式的文件。分两部分说明这个文件的内容，我们先看第一部分：文件的定义。

```
title: meixuesong blog
author: Jason Mei
date: October 2014
epub-filename: /Users/mxs/Documents/jasonblog.epub
epub-cover-image: myresource/epub/cover.jpg
epub-stylesheet: myresource/epub/stylesheet.css
epub-metadata: myresource/epub/metadata.xml
epub-dir: /Users/mxs/Documents/blog/
header-items:
- title: meixuesong blog
- author: meixuesong
- author-note: na
- citation: na
```

其中要注意的是路径，`epub-dir`是博客资源的根路径，其中文件夹如`epub-cover-image`, `epub-stylesheet`和`epub-metadata`都是相对根路径的相对路径。`metadata.xml`是EPUB文件所需的文件，可以是个空文件。为了美观，我们稍微修改了stylesheet.css：

```css
/*stylesheet.css*/
body { margin: 5%; text-align: justify; font-size: medium; }
code { font-family: monospace; font-size:0.75em;}
h1 { text-align: center; margin:0px; padding:0px;font-size:1.5em; border-bottom: black solid 1px;}
h2 { text-align: left; margin:0px; padding:0px;font-size:1.2em;}
h3 { text-align: left; margin:0px; padding:0px;font-size:1.1em;}
h4 { text-align: left; margin:0px; padding:0px; font-size:1em;}
h5 { text-align: left; }
h6 { text-align: left; }
h1.title { }
h2.author { }
h3.date { }
ol.toc { padding: 0; margin-left: 1em; }
ol.toc li { list-style-type: none; margin: 0; padding: 0; }
```

开始定义第二部分，章节定义。这部分比较简单，就是定义书中包含哪几章，名字是什么，每章包括哪些博客。示例如下：

```
content-dir: _posts/   #博客所在的相对路径
contents: 
  - section-title: Articles   #章节名称
    files:                    #该章以下包括哪些内容
    - article1.markdown
    - article2.markdown
  - section-title: Reviews
    files:
    - review.markdown
```

## 2. 生成EPUB电子书

完成`manifest.yml`的定义之后，就可以开始生成电子书了：

```bash
jekyll-ebook manifest.yml
```

EPUB电子书就这样生成了，字体完美，甚至还有代码高亮显示功能，电子书的目录默认显示到第三级，在Kindle上看显得多了，需要改为只显示第1级，即目录只显示文章标题，而不用详细到每章的`h3`级内容。另外图片显示不正常，应该是路径不正确。

先来解决第一个问题，将目录级别改为只显示第1级标题。可以修改文件`ebook.rb`，在Mac OSX下，这个文件位于：

```ruby
#文件路径：
/Library/Ruby/Gems/2.0.0/gems/jekyll-ebook-0.0.2/lib/jekyll-ebook/ebook.rb

# 修改代码，加上：'toc-depth' => 1,
PandocRuby.new( self.generate_content ,
                   {:f => :markdown, :to => :epub},
                   'smart', 'o' => self.manifest['epub-filename'],
                   'toc-depth' => 1,

```

再来解决图片不显示的问题。该问题主要是因为写博客时，图片的地址为`/myresource/images/`，因此在生成电子书无法找到这个绝对路径。解决办法使用`ln`命令在根文件夹下建立一个符号连接myresource，Windows下好像是`mklink`命令。重新生成电子书，问题解决。

现在，我们的EPUB电子书通过Kindle多看系统阅读已经非常完美了。接下来我们尝试一下Mobi格式的电子书。

## 3. 生成Mobi电子书
Amazon提供了一个工具包[KindleGen](http://www.amazon.com/gp/feature.html?docId=1000765211)。该工具可以将html、EPUB等转换成Mobi格式。下载解压缩后，就可以执行命令转换了：

```bash
./kindlegen -locale zh aaa.epub
```
分别在原生Kindle和多看系统下查看这个mobi电子书，整体效果还是不错的，但是相比EPUB来说，还是差了那么一点点。例如h1到h3的标题下方空白的内容太多，也就是CSS中的margin-bottom值太大，但不论怎么修改，Mobi格式的显示效果好像都没有变化。最后还是选择继续使用多看系统，阅读EPUB格式的电子书。

【Update,2014-12-21】现在使用[RSS2EPUB](http://rss2epub.appspot.com/)已经可以直接生成Epub或Kindle电子书了。
