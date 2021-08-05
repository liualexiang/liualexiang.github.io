#### Git 最基本的几个命令

##### 初始化git
在一个空目录下，初始化git

```bash
Git init
```

在目录中放一些文件，然后添加到本地git中

```bash
Git add .
```

检查git状态

``` bash
Git status
```

要提交到远程仓库，那么必须先commit一下

``` bash
Git commit -m "first commit"
```

提交到远程仓库，如果没有配置远程地址，则会报错，解决办法请参考下面的步骤

``` bash
Git push origin master
```

##### 配置github的key

在github上创建一个repo，然后在账户设置，SSH and GPG keys里面，添加 ssh pub key
产生ssh public key方法，添加~/.ssh/id_rsa.pub文件内容

``` bash
ssh-keygen -t rsa -b 4096 -C "liualexiang@gmail.com"
```

之后可以测试一下

``` bash
ssh -T git@github.com
```

添加remote origin:
``` bash
git remote add origin git@github.com:liualexiang/learninguide.git

# 使用https方式的话不会走ssh key。
git remote add origin https://github.com/liualexiang/aws_transcribe_catpions/ 
```

然后进行push

```  bash
git push origin master
```

##### 将远程git同步到本地
```bash
#在一个空文件夹下，初始化git
git init

# 添加远程repo
git remote add master git@github.com:liualexiang/learninguide.git

#取回数据
git fetch origin

# 此时ls直接看到是空的，checkout到master分支
git checkout master

# 再ls就看到了

```


##### git 管理多个github repo
在本地创建另外一个folder，在github上创建好repo
```bash
git init
git remote add new_repo https://github.com/liualexiang/new_repo

git remote //检查新增加的repo，在本路径下放一个文件，然后git add, git commit -m "ss"
git push new_repo mster
```


##### Git 多分支管理
```bash
# 创建一个test分支
git branch test
# 切换到test分支
git checkout test
# 查看当前所在的分支
git branch
# 创建文件，然后提交到test分支
touch aa
git add .
git commit -m "add aa file"
git push origin test

# 对分支进行merge，先看一下branch
git branch
# 切换到main分支上
git checkout main
# 将master分支merge到main分支（也就是将master分支的内容复制到main分支，将main分支作为汇总）
git merge master

# 删除远程的分支
git branch -a # 先看下远程分支，比如看到的结果如下，既有本地分支，又有远程分支

* main
  remotes/origin/main
  remotes/origin/master
  
# 此时我们要删除远程origin下的master分支，命令为 
git push origin --delete master
```

##### git 日志与回滚
```
git log
git reflog
git reset --hard commit_id
```

##### git repo搭建
```
# 示例：再home目录下创建一个 repos 目录，然后再这个目录下创建一个 app.git 目录，之后在app.git目录中执行命令
git init --bare

# 在另外一台机器上使用git clone之前的git repo中的内容(以下两种方法都可以)
git clone ssh://username@ip/home/repos/app.git
# git clone username@ip:/home/repos/app.git

# 可以通过ssh-keygen在git server中的~/.ssh/authorized_keys文件中添加public key来实现无密钥登录


```


##### github 配置ssh key
在github个人settings中，SSH and GPG Keys中添加ssh public key，添加之后可以使用ssh测试下连通性

```
# git remote add origin git@github.com/username/repos
ssh -T git@github.com

```
