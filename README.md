# tiny_scripts

辅助脚本合集

## dict.sh

### 一个命令行的字典工具，依赖一个静态文本文件作为单词本

./dict.sh
    随机从单词本文件输出一个单词
./dict.sh -e hello -c 你好
    向单词本添加一个单词
./dict.sh hell
    在单词本中模糊查找包含子串hell的单词并输出

## capton.sh

### 一个循环抓包脚本，依赖tcpdump

./capton.sh -k 300 -i 30 -p "-A host name"
    抓取hostname的包，保存到当前目录，保持至少有300秒内的数据，其中每隔30秒切分一个文件


