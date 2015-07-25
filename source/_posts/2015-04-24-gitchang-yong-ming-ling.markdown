---
layout: post
title: "Git常用命令"
date: 2015-04-24 18:27:40 +0800
comments: true
toc: true
toc: true
categories: 
- others
---

Git是一个分布式版本控制系统。分布式版本控制系统最大的反传统之处在于，可以不需要集中式的版本库，每个人都工作在通过克隆建立的本地版本库中。也就是说每个人都拥有一个完整的版本库，查看提交日志、提交、创建里程碑和分支、合并分支、回退等所有操作都直接在本地完成而不需要网络连接。

<!--more-->

## 1. Git配置
在开始Git之旅之前，我们需要设置一下Git的配置变量，这是一次性的工作。即这些设置会在全局文件（用户主目录下的.gitconfig）或系统文件（如/etc/gitconfig）中做永久的记录。

```
git config --global user.name "meixuesong"   
git config --global user.email "meixuesong@gmail.com"
git config --global color.ui true #在Git命令输出中开启颜色显示
git config --global alias.co checkout #设置别名
git config --global alias.ci commit #设置别名
git config --global alias.st status #设置别名
git config --global alias.br branch #设置别名
git config -l  # 列出所有配置
```

## 2. 创建版本库

```
#在工作目录中初始化新仓库
git init
#从现有仓库克隆
git clone git://github.com/schacon/grit.git
#从现有仓库克隆，并重命名文件夹
git clone git://github.com/schacon/grit.git myproject
```

## 3. Git的基本概念
Git工作在三个区，理解这几个概念有助于理解git相关命令：

* 工作目录：git clone 后获得的一份本地的代码，也包括新编辑的，尚未加入版本控制的代码。
* 暂存区域：git add 后暂存起来，尚未git commit 的代码。
* 本地仓库：git commit 后正式被版本控制记录起来的代码。

如下图所示：

![image](/myresource/images/image_blog_-2015-04-24git_3_kingdom.png)

在工作目录中做的变更，如增加/修改/删除文件，需要使用git add/rm命令将其放到暂存区，git commit命令将暂存区的内容提交到本地仓库。

## 4. Git基本操作
### 4.1 检查当前文件状态
`git status`命令用于确定哪些文件当前处于什么状态。

```
git status
git status -s
```

### 4.2 跟踪文件

```
#将指定文件放入暂存区
git add <file>
#将所有修改过的工作文件放入暂存区
git add . 
#进入交互模式，对添加多个文件比较方便
git add -i
```

对于修改的文件，也是使用git add命令进行暂存。如果同一个文件修改了两次，第一次修改使用git add进行了暂存，第二次没有暂存，则git commit时，只会提交第一次修改的内容。

### 4.3 忽略文件
编辑.gitignore文件，列出要忽略的文件模式。文件 .gitignore 的格式规范如下：

* 所有空行或者以注释符号`＃`开头的行都会被 Git 忽略。
* 可以使用标准的 glob 模式匹配。
* 匹配模式最后跟反斜杠`/`说明要忽略的是目录。
* 要忽略指定模式以外的文件或目录，可以在模式前加上惊叹号`!`取反。

所谓的 glob 模式是指 shell 所使用的简化了的正则表达式。星号（*）匹配零个或多个任意字符；[abc] 匹配任何一个列在方括号中的字符（这个例子要么匹配一个 a，要么匹配一个 b，要么匹配一个 c）；问号（?）只匹配一个任意字符；如果在方括号中使用短划线分隔两个字符，表示所有在这两个字符范围内的都可以匹配（比如 [0-9] 表示匹配所有 0 到 9 的数字）。示例如下：

```
# 此为注释 – 将被 Git 忽略
# 忽略所有 .a 结尾的文件
*.a
# 但 lib.a 除外
!lib.a
# 仅仅忽略项目根目录下的 TODO 文件，不包括 subdir/TODO
/TODO
# 忽略 build/ 目录下的所有文件
build/
# 会忽略 doc/notes.txt 但不包括 doc/server/arch.txt
doc/*.txt
# ignore all .txt files in the doc/ directory
doc/**/*.txt
```

### 4.4 查看已暂存和未暂存的更新
尚未暂存的文件更新了哪些部分，不加参数直接输入git diff. 此命令比较的是工作目录中当前文件和暂存区域快照之间的差异，也就是修改之后还没有暂存起来的变化内容。

若要看已经暂存起来的文件和上次提交时的快照之间的差异，可以用 git diff --cached 命令。（Git 1.6.1 及更高版本还允许使用 git diff --staged，效果是相同的）

### 4.5 提交更新
将暂存区的内容提交到本地版本库。

```
#会启动文本编辑器以便输入备注
git commit
#直接加上备注
git commit -m "Story 182: Fix benchmarks for speed"
#自动把所有已经跟踪过的文件暂存起来一并提交，相当于add和commit
git commit -a -m 'added new benchmarks'
```

### 4.6 移除文件
git rm 从已跟踪文件清单中移除文件，并从工作目录中删除指定的文件。如果删除之前文件修改过并且已经放到暂存区域的话，则必须要用强制删除选项 -f，以防误删除文件后丢失修改的内容。

如果我们想把文件从 Git 仓库中删除（亦即从暂存区域移除），但仍然希望保留在当前工作目录中，可以使用: git rm --cached readme.txt

也可以在移除命令中使用glob 模式，例如：

```
#删除log文件夹下的所有.log文件(*之前的\为转义符)
$ git rm log/\*.log
#递归删除当前目录及其子目录中所有.log文件
$ git rm \*.log
```

### 4.7 移动文件
Git 并不跟踪文件移动操作。如果在 Git 中重命名了某个文件，仓库中存储的元数据并不会体现出这是一次改名操作。不过 Git 非常聪明，它会推断出究竟发生了什么。

```
$ git mv file_from file_to
```

## 5. 查看提交历史
git log用于查看提交历史。常用的选项包括：

* git log -p 展开显示每次提交的内容差异
* git log -2 限制输出数量，只显示最近2两次的提交
* git log --pretty=format:"%an, %cr %s" 格式化输出，显示为：“作者 提交时间 备注”

还有按照时间作限制的选项，比如 --since 和 --until。下面的命令列出所有最近两周内的提交：`$ git log --since=2.weeks`. 你可以给出各种时间格式，比如说具体的某一天（“2008-01-15”），或者是多久以前（“2 years 1 day 3 minutes ago”）。

还可以给出若干搜索条件，列出符合的提交。用 --author 选项显示指定作者的提交，用 --grep 选项搜索提交说明中的关键字。（请注意，如果要得到同时满足这两个选项搜索条件的提交，就必须用 --all-match 选项。否则，满足任意一个条件的提交都会被匹配出来）。

另一个真正实用的git log选项是路径(path)，如果只关心某些文件或者目录的历史提交，可以在 git log 选项的最后指定它们的路径。因为是放在最后位置上的选项，所以用两个短划线（--）隔开之前的选项和后面限定的路径名。

```
#2008 年 10 月期间，gitster提交的但未合并的位于项目t/ 目录下的文件
$ git log --pretty="%h - %s" --author=gitster --since="2008-10-01" \
   --before="2008-11-01" --no-merges -- t/
```

## 6. 撤消操作
### 6.1 修改最后一次提交
可以使用`--amend`选项修改最后一次提交。例如下面的三条命令只产生一个提交：

```
$ git commit -m 'initial commit'
$ git add forgotten_file
$ git commit --amend
```

第一条命令是普通的提交，提交后才想起来少暂存了一个文件，因此使用第二条命令进行暂存，然后第三条命令修改上一次提交。最终只产生了一次提交。

### 6.2 取消已经暂存的文件
当文件已经暂存，运行`git reset HEAD <file>`可以取消暂存，即文件又回到已修改未暂存的状态。

### 6.3 取消工作区中文件的修改
相当于svn的revert命令。在git中使用的命令是：`git checkout -- <file>`。注意，文件将恢复到修改前的版本，可能造成数据丢失。

## 7. 远程仓库的使用
### 7.1 查看当前的远程库
`git remote`会列出每个远程仓库的简短名称。如果克隆了某个项目，至少可以看到一个名为origin的远程库。Git 默认使用这个名字来标识你所克隆的原始仓库。`git remote -v`显示对应的克隆地址。

### 7.2 从远程仓库抓取数据
`git fetch [remote-name]`会到远程仓库中拉取所有你本地仓库中还没有的数据。`git pull`从原始克隆的远端仓库中抓取数据后，合并到工作目录中的当前分支。

### 7.3 推送数据到远程仓库
`git push [remote-name] [branch-name]`将本地仓库中的数据推送到远程仓库。通常为：`git push origin master`

## 8. 分支
关于分支，此处只列出常用命令。[这篇教程](http://git-scm.com/book/zh/v1/Git-%E5%88%86%E6%94%AF-%E4%BD%95%E8%B0%93%E5%88%86%E6%94%AF)以图示方式对分支进行了详细说明。

命令 | 说明 
---|---
git branch | 列出所有分支
git branch testing | 创建分支testing
git checkout testing | 切换到testing 分支
git checkout -b testing | 相当于执行了上面两个命令
git merge hotfix | 将hotfix分支修改的内容合并到当前分支
git branch -d hotfix | 删除hotfix分支
git branch --merged | 查看哪些分支已被并入当前分支
git branch --no-merged | 查看尚未与当前分支合并的分支






参考： http://git-scm.com/book/zh/v1

![image](/myresource/images/git-2015-07-26.png)




