---
title: sed&gawk Command
date: 2021-08-03
excerpt: "Linux下文本处理了命令大全"
categories: "Linux"
tages: 
- shell
- linux
---



## sed [Stream Editor]

- 处理流程
	1. 一次从输入数据中读取一行
	2. 根据所提供的编辑器命令匹配数据
	3. 按照命令修改流中的数据
	4. 将新的数据输出到STDOUT（注意这里默认不是写回原文件）

- sed命令格式：`sed options script file`

- 参数内容

| Options     | Description                                       |
| ----------- | ------------------------------------------------- |
| `-e script` | 处理输入时，将scripts中指定命令添加到已有命令中   |
| `-f file`   | 将file中的命令添加到已有命令中                    |
| `-n`        | 取消将结果输出到STDOUT，需要使用print命令完成输出 |

```shell
# 命令行方式
sed -e 's/brown/green/; s/dog/cat/' data.txt

# 在file.txt中添加如下两行
# s/brown/green/
# s/dog/cat/

# 文件方式
sed -f file.txt data.txt
```

### 替换标记

默认只替换每行第一处，使用标记替换（substitution flag）可以指定替换位置`s/pattern/replacement/flags`，具体有四种替换标记：数字、g、p、w 

### 行寻址

`[address]command`或

```shell
address{
 command1
 command2
 command3
}
```



## gawk

- 功能
	- 使用变量
	- 使用算数和字符串操作
	- 使用结构化编程，if-then和循环，来添加逻辑
	- 提取数据元素，并重新排列，以形成格式化报告

- 参数
	- `-F fs`设定分隔符
	- `-f file`从文件读取程序
	- `-v var=value`设定变量默认值
	- `-mf N`【max field】指定每行处理的最大字段数
	- `-mr N`【max row】指定处理的最大行数
	- `-W keyword`指定gawk兼容模式、警告等级

- 变量

	- `$0`整个一行

	- `$n`行中第N个数据字段

		```shell
		gawk -F: '{print $1}' /etc/passwd
		```

	- 

- 关键字BEGIN&END

	```shell
	# BEGIN: 开始处理数据前要运行的脚本
	gawk 'BEGIN {print "New Data Contents"} {print $0}' temp.txt 
	# END: 处理完成后，要运行的脚本
	gawk 'BEGIN {print "The data File COntents:"} \
	{print $0} \
	END {print "End of File"}' temp.txt
	```

- gawk命令文件

	```shell
	BEGIN {
	print "The latest list of users and shells";
	print " UserID \t Shell";
	print "-------- \t -------" 
	FS=":" 
	}
	
	{
	print $1 "\t" $7
	}
	
	END {
	print "This concludes the listing" 
	}
	```