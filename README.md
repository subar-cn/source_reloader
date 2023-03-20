### source_reloader(源码自动重载)
主体逻辑参考自Rack::Reloader
https://github.com/rack/rack/blob/main/lib/rack/reloader.rb


### 实现原理
1. 根据`$LOADED_FEATURES`和`$LOAD_PATH`找到所有已加载的文件。
2. 使用UI.start_timer每间隔一定时间(目前是写的2秒)去检测一次所有文件的修改时间。
3. 如文件的mtime有变，则重新load一下。


### 功能列表
1. 自动重载
2. 手功开启/关闭自动重载
3. 没有了


### TODO LIST
- [ ] 新建文件无法自动加载
(动态添加的新文件因为不在`$LOADED_FEATURES`列表中，所以无法检测)
- [ ] 参照https://github.com/thomthom/extension-sources 引入插件列表，可单插件开启/关闭自动重载
- [ ] 安装了大量的插件，每2秒遍历所有文件是否存在性能问题？(可以先排除掉SU自带的ruby库)
- [ ] 用Mac开发的，Windows兼容性目前尚未验证
