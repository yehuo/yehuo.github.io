---
title: Git Operation
date: 2016-03-18
excerpt: "Just First Try on Git"
categories:
  - CI
tags:
  - Git
---



# 分区


# Branch 操作

- 分支操作

	```shell
	git checkout -b dev		#创建并切换分支
	git branch dev			#创建分支
	git checkout dev 		#切换分支
	git branch 				#查看当前分支 当前分支前面有*
	git add "file name"		#修改提交
	git commit -m "branch test"
	git merge dev			#dev与当前分支合并
	git branch -d dev		#删除分支
	git status	#查看合并冲突文件
	git log 	#查看分支合并情况
	
	#图示分支合并过程
	git log --graph --pretty=oneline --abbrev-commit
	```

- Fast Forward Merge

	options: --ff | --no-ff | --ff-only

	> Specifies how a merge is handled when the merged-in history is already a descendant of the current history. `--ff` is the default unless merging an annotated (and possibly signed) tag that is not stored in its natural place in the `refs/tags/` hierarchy, in which case `--no-ff` is assumed.
	>
	> With `--ff`, when possible resolve the merge as a fast-forward (only update the branch pointer to match the merged branch; do not create a merge commit). When not possible (when the merged-in history is not a descendant of the current history), create a merge commit.
	>
	> With `--no-ff`, create a merge commit in all cases, even when the merge could instead be resolved as a fast-forward.
	>
	> With `--ff-only`, resolve the merge as a fast-forward when possible. When not possible, refuse to merge and exit with a non-zero status.

- 常见分支命名策略
  - master稳定分支
  - dev不稳定分支
  - name如Bob，Michael等
- 恢复操作

```bash
git stash		#工作现场存储
git stash apply	#现场恢复
git stash drop	#删除现场文件
git stash pop	#恢复现场并删除存储的现场文件工作现场存储
git stash list	#stash many times并查看保存的多个现场
git stash spply stash@{0}	#恢复某版本现场
```

---

## workspace

在工作区内，可以直接增加修改源代码

#### Repository

- stage：暂存区
- branch：分支

```bash
git add .	#将所有修改加入暂存区
git commit -m "git track changes"	#将所有修改提交分支
git status	#查看暂存区状态，未提交文件等
git diff HEAD -- readme.txt	#查看当前工作区与版本库区别
```

#### 反馈种类

- Changes not staged for commit：文件修改过未放入暂存区
- Untracked files：新建文件未被添加
- Changes to be commit：暂存区还未加入分支的文件
- working directory clean：工作区清空/工作区与版本库相同

---

## fork

在开源项目中点击fork，该项目便会拷贝一份到你的respositories中，可以通过clone将你的respositories中的代码下载到本地进行二次开发。默认远程的别名为origin，此为我们自己项目中的版本，并非原始作者的代码库。为了方便区分，我们可以为原始代码库创建别名。

#### 为代码库添加别名

```bash
git remote add upstream git://github.com/user_name/proj_name.git 
git fetch upstream	#设定别名为upstream
```

#### 追踪原始代码 

```bash
git push origin master		#提交代码更新到自己的代码库
git fetch upstream 			#获取原始代码库的更新
git merge upstream/master	#自己的代码合并到原始代码库中
```

#### pull request

[pull request](http://help.github.com/send-pull-requests/)：将自己的代码发给到原始代码库作者

---

## Git Page

- Follow：在你的dashboard提示被follow用户动态
- Watch：你可以在dashboard上看到被watch项目更新
- Compare & pull request：将你fork的代码修改后，可以对比源项目代码，然后将你的修改提交源作者
- Issues:在你与别人合作开发过程中，发现，可以帮你keep track of problems，就是在你的分支上发现问题，然后可以看别人分支上对相关问题的修改
- Star Page：可以看到你赞(star)过的项目

---

## Push

本地可以多次commit，一次性push到远程服务器上，服务器上同样可以查看本地的多次commit记录。

例如，休假时离线开发三天时，每天commit，第四天回公司上线push所有修改。GitHub的记录中，前三天的commit同样会被保存。