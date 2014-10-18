---
layout: post
title: "终于完成RSS2EPUB的项目"
date: 2014-10-18 22:37:33 +0800
comments: true
categories: 
- others
---
国庆期间，自从10月5日完成博客转EPUB电子书后，脑子突然短路，是不是可以把RSS订阅的内容也自动转成EPUB电子书呢？然后就没停下来，利用业余时间终于完成了，各项功能基本完善！

这个项目运行于GAE平台，接受用户订阅，然后每天把最新内容生成电子书发邮件给用户。

运行于GAE平台的好处是直接使用Google的云服务，特别是邮件服务和图片服务非常棒！但坏处是Google被墙，国内无法直接访问。所以又开发了邮件订阅的方法。总体来说效果不错！

详细介绍见[RSS](https://github.com/meixuesong/rss2epub)
