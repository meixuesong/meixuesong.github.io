---
layout: post
title: "Linux crontab定时任务"
date: 2015-03-28 21:04:50 +0800
comments: true
toc: true
categories:
- linux & mac
---

通过crontab命令可以固定的间隔时间循环执行指定的命令或shell脚本。时间间隔的单位可以是分钟、小时、日、月、周及以上的任意组合。这个命令非常适合周期性的工作。

<!--more-->

## 命令
crontab有两种命令形式：

```
crontab [ -u user ] file
crontab [ -u user ] [ -i ] { -e | -l | -r }
```

* -u user：用来设定某个用户的crontab服务；
* file：file是命令文件的名字,表示将file做为crontab的任务列表文件并载入crontab。如果在命令行中没有指定这个文件，crontab命令将接受标准输入（键盘）上键入的命令，并将它们载入crontab。
* -i：在删除用户的crontab文件时给确认提示。
* -e：编辑某个用户的crontab文件内容。如果不指定用户，则表示编辑当前用户的crontab文件。
* -l：显示某个用户的crontab文件内容，如果不指定用户，则表示显示当前用户的crontab文件内容。
* -r：从/var/spool/cron目录中删除某个用户的crontab文件，如果不指定用户，则默认删除当前用户的crontab文件。

## crontab文件格式

```
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * command to be executed
  23 20 *  *  * shutdown  -r  now
```  

## 建立cron任务

```
为当前用户建立cron任务
# crontab -e
为root建立cron任务
# sudo crontab -e
```

系统会打开默认编辑器（如果没有会让你选择），然后进行任务编辑。

## cron任务示例

```
#实例1：每1分钟执行一次myCommand
* * * * * myCommand
#实例2：每5分钟执行一次myCommand
*/5 * * * * myCommand
#实例3：每小时的第3和第15分钟执行
3,15 * * * * myCommand
#实例4：在上午8点到11点的第3和第15分钟执行
3,15 8-11 * * * myCommand
#实例5：每隔两天的上午8点到11点的第3和第15分钟执行
3,15 8-11 */2  *  * myCommand
#实例6：每周一上午8点到11点的第3和第15分钟执行
3,15 8-11 * * 1 myCommand
#实例7：每晚的21:30重启smb
30 21 * * * /etc/init.d/smb restart
#实例8：每月1、10、22日的4 : 45重启smb
45 4 1,10,22 * * /etc/init.d/smb restart
#实例9：每周六、周日的1 : 10重启smb
10 1 * * 6,0 /etc/init.d/smb restart
#实例10：每天18 : 00至23 : 00之间每隔30分钟重启smb
0,30 18-23 * * * /etc/init.d/smb restart
#实例11：每星期六的晚上11 : 00 pm重启smb
0 23 * * 6 /etc/init.d/smb restart
#实例12：每一小时重启smb
* */1 * * * /etc/init.d/smb restart
#实例13：晚上11点到早上7点之间，每隔一小时重启smb
* 23-7/1 * * * /etc/init.d/smb restart
```

## 注意事项
### 环境变量问题
我们手动执行某个任务时，是在当前shell环境下进行的，程序能找到环境变量。而系统自动执行任务调度时，是不会加载任何环境变量的，因此，就需要在crontab文件中指定任务运行所需的所有环境变量。因此需要注意：

* 脚本中涉及文件路径时写全局路径；
* 脚本执行要用到java或其他环境变量时，通过source命令引入环境变量，如:

```
cat start_cbp.sh
!/bin/sh
source /etc/profile
export RUN_CONF=/home/d139/conf/platform/cbp/cbp_jboss.conf
/usr/local/jboss-4.0.5/bin/run.sh -c mev &
```

* 当手动执行脚本OK，但是crontab执行不成功时,很可能是环境变量惹的祸，可尝试在crontab中直接引入环境变量解决问题。如:

```
*/5 * * * * . /etc/profile;/bin/sh /usr/bin/gitupdateblog.sh
```

### 重定向问题
每条任务调度执行完毕，系统都会将任务输出信息通过电子邮件的形式发送给当前系统用户，但如果没有配置电子邮件，通过日志会查看到提示信息：

```
# grep CRON /var/log/syslog
Mar 28 08:30:01 Jasondroplet CRON[26905]: (CRON) info (No MTA installed, discarding output)
```

也可将输出重定向，即在每条命令后面加上`/dev/null 2>&1`：

`*/5 * * * * . /etc/profile;/bin/sh /usr/bin/gitupdateblog.sh  >/dev/null 2>&1`

`/dev/null 2>&1`表示先将标准输出重定向到/dev/null，然后将标准错误重定向到标准输出，由于标准输出已经重定向到了/dev/null，因此标准错误也会重定向到/dev/null，这样日志输出问题就解决了。

### 系统级任务调度与用户级任务调度
系统级任务调度主要完成系统的一些维护操作，用户级任务调度主要完成用户自定义的一些任务，可以将用户级任务调度放到系统级任务调度来完成（不建议这么做），但是反过来却不行，root用户的任务调度操作可以通过”crontab –uroot –e”来设置，也可以将调度任务直接写入/etc/crontab文件，需要注意的是，如果要定义一个定时重启系统的任务，就必须将任务放到/etc/crontab文件，即使在root用户下创建一个定时重启系统的任务也是无效的。

### 重启服务

`# service cron restart`
