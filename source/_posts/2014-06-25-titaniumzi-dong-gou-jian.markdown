---
layout: post
title: "Titanium移动开发之每日自动构建"
date: 2014-06-25 11:19:18 +0800
comments: true
toc: true
categories: 
- 移动开发
---

以下脚本用于构建Android 和 iOS版本的Titanium应用。可以将脚本加入cron中，每日定时构建。脚本还实现了自动获取svn日志，生成一个发布网页，直接上传到ftp的功能。

<!--more-->

```
#转到项目文件夹，更新脚本并执行Clean
cd /Users/mxs/Develop/CI/myProject
svn update 
titanium clean

#Android打包
echo build Android version
titanium build --log-level warn --platform android --build-only --force -K /Users/mxs/keystore -P company -L oasuit -O /Users/mxs/Develop/CI/build -T dist-playstore > ../android.build.log

#文件名加上时间
fileTime="OA-`date +'%Y-%m-%d_%H%M'`"
localApkName="/Users/mxs/Develop/CI/build/"$fileTime".apk"
localApkZip=$fileTime".apk.zip"
localApkZipSource=$fileTime".apk"
remoteApkName="/moa/test/"$fileTime".apk.zip"
oaapk=/Users/mxs/Develop/CI/build/OA.apk
oaapkinfo=""
if [ ! -f $oaapk ]
then
  oaapkinfo='<br/><strong><span style="color:red">OA.apk不存在，tiapp.xml配置不正确或者构建失败。</span></strong>'
fi
mv $oaapk $localApkName

#iOS打包
mv /Users/mxs/Develop/CI/i18n /Users/mxs/Develop/CI/myProject/i18n 
titanium clean
echo build iOS version
titanium build --log-level warn --platform ios --build-only --force --device-family iphone -O /Users/mxs/Develop/CI/build -P XXXXXXX -T dist-adhoc --distribution-name "Company Ltd./" > ../ios.build.log
localIpaName="/Users/mxs/Develop/CI/build/"$fileTime".ipa"
localIpaZip=$fileTime".ipa.zip"
localIpaZipSource=$fileTime".ipa"
remoteIpaName="/moa/test/"$fileTime".ipa.zip"
oaipa=/Users/mxs/Develop/CI/build/OA.ipa
oaipainfo=""
if [ ! -f $oaipa ]
then
  oaipainfo='<br/><strong><span style="color:red">OA.ipa不存在，tiapp.xml配置不正确或者构建失败。</span></string>'
fi
mv $oaipa $localIpaName
mv /Users/mxs/Develop/CI/myProject/i18n /Users/mxs/Develop/CI/i18n 

#获取昨天的日志，只要以#开始的注释
yesterday="`date -v -1d +'%Y-%m-%d'`"
today="`date +'%Y-%m-%d'`"
svn log -r {$yesterday}:{$today} > ../log.tmp
grep '^#' ../log.tmp > ../change.log
rm ../log.tmp

#生成releasenote
releaseFileName="../build/releasenote-`date +'%Y-%m-%d'`.txt"
date "+<h2>%Y-%m-%d</h2><hr/><p>构建时间：%Y-%m-%d %H:%M:%S</p>" > $releaseFileName
echo '<p>下载地址：<a href="'$remoteIpaName'" target="_blank">iOS</a> | <a href="'$remoteApkName'" target="_blank">Android</a></p>' >> $releaseFileName
echo '' >> $releaseFileName
echo '<h3>--------------变更日志-------------------</h3>' >> $releaseFileName
echo '<pre>' >> $releaseFileName
cat ../change.log >> $releaseFileName
echo '</pre>' >> $releaseFileName
echo '<h3>--------------构建日志-------------------</h3>' >> $releaseFileName
echo '注：只显示警告和错误信息。' >> $releaseFileName
echo $oaapkinfo >> $releaseFileName
echo $oaipainfo >> $releaseFileName
echo '<h4>Android</h4>' >> $releaseFileName
echo '<pre>' >> $releaseFileName
#删除Titanium构建日志的前4行
cat ../android.build.log  | sed 1d | sed 1d | sed 1d | sed 1d >> $releaseFileName
echo '</pre>' >> $releaseFileName
echo '<h4>iOS</h4>' >> $releaseFileName
echo '<pre>' >> $releaseFileName
cat ../ios.build.log  | sed 1d | sed 1d | sed 1d | sed 1d >> $releaseFileName
echo '</pre>' >> $releaseFileName
indexFileName="../build/index.html"
historyFileName="../index_history.html"
indexTopFileName="../index_top.html"
cat $historyFileName >> $releaseFileName
rm $historyFileName
mv $releaseFileName $historyFileName
echo '' > $indexFileName
cat $indexTopFileName >> $indexFileName
cat $historyFileName >> $indexFileName
rm ../change.log
rm ../android.build.log
rm ../ios.build.log
echo zip
#压缩成zip,必须切换到当前文件夹进行压缩操作，否则zip内容包括路径
cd ../build
zip $localApkZip $localApkZipSource
zip $localIpaZip $localIpaZipSource

#上传到FTP服务器
echo 'ftp action'
HOST='192.168....'
USER='xxx'
PASSWD='xxx'
remoteIndex="/xxx/index.html"
ftp -n $HOST <<END_SCRIPT
quote USER $USER
quote PASS $PASSWD
binary
put $localIpaZip $remoteIpaName
put $localApkZip $remoteApkName
put $indexFileName $remoteIndex
quit
END_SCRIPT
exit 0

```
