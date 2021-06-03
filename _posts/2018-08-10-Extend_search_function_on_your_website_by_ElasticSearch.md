# 手把手教你如何从零开始开发一个全文检索网站

[toc]

## 0x00 源起

不知boss吃了谁家安利，有一天忽然心血来潮，要搞一波nosql来推进我司工作，还要求支持全文检索

具体到技术栈，boss也做了很具体的要求：“就是MongoDB+Elasticsearch+PHP搞一个检索终端...”

另外...boss通俗易懂地告诉我：“Nosql就是把数据以JSON格式存入数据库...”

于是...在开工前，boss先给我司运营下达任务，要求花了几天把全部mysql数据手工转换为json文件发给了我...~~（还好数据库不大~~

然后...一把梭的重任就落到了我肩上，看着boss发来的n份~~完全没做过正确性检验的~~json文件，我心里有一句MMP想讲...

那么简而言之，这里就是要记述我是如何从一份json文件开始，搞出一套~~业务逻辑混乱的~~支持全文检索的网站的...

## 0x01 将json文件批量导入MongoDB

## 0x02 使用bulk API将json批量导入Elasticsearch

## 0x03 设定从MongoDB到Elasticsearch集群的定期同步

## 0x04 使用PHP-Elasticsearch组件调用Elasticsearch全文检索功能

## 0x05 设计前端页面以获取PHP发送的JSON格式数据

## 0x06 设计前端跳转逻辑

## 0x07 在前端页面中添加CRUD操作端口以直接操作MongoDB
