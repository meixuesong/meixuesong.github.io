---
layout: post
title: "在GitHub上写博客"
date: 2014-06-25 22:54:07 +0800
comments: true
categories: 
- others
---

一直想找个能支持Markdown的博客平台。在尝试了包括CSDN、Loft、点点等博客平台之后，均觉不太满意。CSDN太业余，一个IT业最大的社区网站，竟然不支持Markdown。Loft偏文艺，不适合技术。点点还不错，支持Markdown，本来准备最终选择它了，但不爽有二：<!--more-->一是主题没合适的，界面布局、代码高亮显示、字体大小和摘要显示等总有一点让你觉得勉强；二是使用独立域名，要求太不清晰。输入相关信息后总是提示我的博客太少，不让使用自己的域名。但你好歹说一下标准是啥啊？多少篇博客才能满足你这条件啊？这种体验太差了。最后放弃。



一番折腾后，发现可以直接使用[GitHub](http://github.com)写博客，而且几年前就有这个功能了。看来真是有点Out了！

安装的过程完全参照[Octopress](http://octopress.org/)网站和唐巧的两篇博客：

* [象写程序一样写博客：搭建基于github的博客](http://blog.devtang.com/blog/2012/02/10/setup-blog-based-on-github/)
* [将博客从GitHub迁移到GitCafe](http://blog.devtang.com/blog/2014/06/02/use-gitcafe-to-host-blog/)

安装过程就不再重复了，说说有哪些不同。

Octopress的默认主题背景是黑色，有点太压抑了。代码高亮显示的颜色也不爽，所以改了点颜色：

```css
//sass/custom/_colors.scss
$page-bg:		#F4F3DE;
$header-bg:		#5B4947;
$base03:          #eee; //darkest blue
$base02:          #ddd; //dark blue
$solar-blue:      navy;
```

另外对配置文件_config.yml，除了常规修改外，还修改了：

```
#修改日期格式
date_format: "%Y-%m-%d"

#增加评论功能
disqus_short_name: 你的disqus short name
disqus_show_comment_count: true
```

唐巧使用的是国内的一个评论系统，实际上Octopress内置的插件包含了评论功能。在[Disqus](http://disqus.com)注册帐号并设置shortname后，修改_config.yml即可。

在GitHub上建立博客，最担心的是访问速度。GitHub已经使用全球CDN来服务GitHub Pages，参见：[Faster, More Awesome GitHub Pages](https://github.com/blog/1715-faster-more-awesome-github-pages)。实际测试下来速度很快，用Chrome监视，打开页面基本就是2－3秒时间。

但是在手机上打开博客时，却非常慢。最后发现原因是使用了googleapis.com托管的jQuery.min.js，在天朝这样的网站是很没保障的。解决办法是修改source/_includes/head.html：

```
//将原来的googleapis jquery库改为本地jQuery：
<script src="/javascripts/libs/jquery.min.js"></script>
```

改完后手机上访问也基本可以秒杀了。

用GitHub + Octopress建立博客，过程虽然复杂了点，但最终效果相当不错，你值得拥有！









