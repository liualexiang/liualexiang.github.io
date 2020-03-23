#### Git 最基本的几个命令

##### 初始化git
在一个空目录下，初始化git
``` Git init ```

在目录中放一些文件，然后添加到本地git中
``` Git add . ```

检查git状态
``` Git status ```

要提交到远程仓库，那么必须先commit一下
``` Git commit -m "first commit" ```

提交到远程仓库，如果没有配置远程地址，则会报错，解决办法请参考下面的步骤
``` Git push origin ```

##### 配置github的key

在github上创建一个repo，然后在账户设置，SSH and GPG keys里面，添加 ssh pub key
产生ssh public key方法，添加~/.ssh/id_rsa.pub文件内容
``` ssh-keygen -t rsa -b 4096 -C "liualexiang@gmail.com" ```

之后可以测试一下
``` ssh -T git@github.com ```

添加remote origin:
``` git remote add origin https://github.com/liualexiang/aws_transcribe_catpions/  ```

然后进行push
``` git push origin master ```

##### git 多分支合并
暂不更新

