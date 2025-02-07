# enterprise-practise

#### 登录显示系统信息脚本
- 将 脚本 color.awk、dynmotd 放于 /usr/local/bin下，赋予执行权限
- 编辑 /etc/profile，添加 `timeout 5s /usr/local/bin/dynmotd` ，即可在登录是自动显示系统使用梗概信息
