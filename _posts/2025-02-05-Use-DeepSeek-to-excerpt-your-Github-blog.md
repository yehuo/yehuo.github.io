---
title: "DeepSeek API 初体验：使用 DeepSeek 为你的Github博客编写AI摘要"
date: 2025-02-05
excerpt: "关于如何使用 DeepSeek 来为 GitHub 博客自动生成摘要。通过集成 DeepSeek API 和 GitHub Actions，来实现了新博客提交后自动生成摘要的工作流。从本地测试到线上部署都进行了清晰的操作说明，为开发节省了时间和精力。"
categories:
  - AI
tags:
  - DeepSeek
---



从2022年开始，我就一直在写[个人技术博客](https://yehuo.github.io/)，前前后后写了接近100篇左右的技术分享，然后一直稳定运行在我的 github.io 上。

但随着技术分析越写越多，在众多博客中查找根据主题来查找内容逐渐成为了一个比较麻烦的事情。目前博客默认只会在主页上使用博客内容第一行为摘要，只有通过使用 yaml frontmatter 手动添加摘要才能覆盖掉默认的内容。

但如何把自己辛勤耕耘了几千字的内容缩略成包含关键字的几十字摘要，对工科生显然是个比较烦人的事情，直到我想到了使用 DeepSeek。例如在我的[博客主页](https://yehuo.github.io/year-archive/)上，下面的几篇内容里，Kernel Tuning for Kubernetes 就是使用了 DeepSeek 来编写摘要的。


![blog](\images\20250205\blog.png)

此外，为了更加便于使用英语词汇查询，使用英文编写摘要逐渐也被提上了日程。所以最理想状态就是能让 DeepSeek 同时总结和翻译写好的文章来形成摘要，但这往往意味着要做很多提示词，而如果是通过手工输入的方式和 DeepSeek 交互，这个过程显然会非常消耗人力，让写博客变成一个很不爽的事情。

所以，这时候自然就想到了，除了让 DeepSeek 写摘要，能不能让 DeepSeek 来写一个工作流，自动化完成这个工作呢？

## 0x01 开发逻辑

说干就干，DeepSeek  Excerpt Bot 的逻辑其实非常简单。概括来讲，就是在 Blog Repo 有新提交的时候，使用 github action 自动获取 `_post` 目录下更新的文件列表，然后逐一将博客发送给 DeepSeek ，要求 DeepSeek 按要求总结，最后将返回的摘录内容添加到文章 frontmatter 中，并将新生成的文件作为备份再次提交回 Blog Repo。

核心文件包括两项：

1. github action 脚本 `AIExcerptGenerator`：管理触发逻辑，并将更新后的文章重新提交到 Repo
2. shell 脚本 `excerptor` ：用于和 DeepSeek API 进行交互

## 0x02 编写 Github Action

[Github Action](https://docs.github.com/en/actions) 本质上是一个 yaml 格式的工作流定义，在 Repo 发生指定的时候触发。这里直接使用 DeepSeek 来编写一个简单 Github Action 处理框架：

```yaml
name: Trigger on new posts

on:
  push:
    paths:
      - '_posts/**'	# blog 存放位置
jobs:
  new_post_detected:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      with:
        fetch-depth: 2	# 至少抓取两个版本的repo，从而对比是否有新文件

    - name: 
      id: get_changed_files
      run: ...
    
    - name: Run excerptor.sh on new files
      env:
      	# 从 github action env 获取 DeepSeek API Key
        API_KEY: ${{ secrets.DS_API_KEY }}
        # 将 API Key 设置为 workflow环境变量
      run: ...

    - name: Commit and push changes
			run: |
        git config --global user.email "github-actions[bot]@users.noreply.github.com"
        git config --global user.name "github-actions[bot]"
        git add _posts/
        git commit -m "Add excerpts to new posts"
        git push
```

基本框架写好后，就需要处理 3 个小问题：

1. 如何获得 `_post` 中指定目录的更新？鉴于我们只需要文件名，这里推荐使用 [`git show`](https://git-scm.com/docs/git-show) 命令来查看更新。
2. 如何保证DeepSeek API Key 不在代码中被泄露？关于如何在 Github Action 中安全地使用密数据，可以参考 [在 GitHub Actions 中使用机密 ](https://docs.github.com/zh/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions) 来解决。
3. 如何调用目录下的 shell 脚本？调用很简单，使用 Github Action 中 `run` 模块即可，但是为了保证脚本路径正确，建议使用绝对路径或者模块的 `working-directory` 属性来确立根目录，并在 `awk` 命令处理文件名时，注意空格的处理。

## 0x03 编写 DeepSeek API 访问脚本

`excerptor.sh` 的功能是单独处理一份 markdown 文件，切分出 `frontmatter` 部分，并将剩余的文章和文章标题发送给 DeepSeek API，构建请求可以参考官方文档 [Your First API Call](https://api-docs.DeepSeek.com/)

```shell
#!/bin/bash

# 使用参数获取文件绝对路径 $file
...
# 检查文件是否包含YAML front matter的结束符，否则退出脚本
line_numbers=$(grep -n '^---$' "$file" | cut -d: -f1)
if [ $(echo "$line_numbers" | wc -l) -lt 2 ]; then
  echo "YAML front matter is not closed properly."
  exit 1
fi

# 获取yaml front matter的起止行
start_line=1
second_delim=$(echo "$line_numbers" | sed -n '2p')
end_line=$((second_delim - 1))

# 检查是否存在以"excerpt:"开头的行，如果存在则退出脚本
...
# 检查是否存在以"title:"开头的行，如果存在则提取title，否则提取文件名作为title
...

# 如果不存在excerpt，提取文章内容
blog_content=$(sed -n "$((end_line + 1)),\$p" "$file")

# 构建payload
json_payload=$(jq -n \
    --arg title "$title" \
    --arg content "$blog_content" \
    '{
      messages: [
        {content: "You are a helpful assistant to help me summary my blog excerpt", role: "system"},
        {content: "My blog title is: \($title)", role: "user"},
        {content: "Could you give me an raw excerpt in one-line English within 50 words: \($content)", role: "user"}
      ],
      # 设置 api 参数
      ...
    }')

# 构建 DeepSeek 请求
response=$(curl -s -L -X POST 'https://api.DeepSeek.com/chat/completions' \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "Authorization: Bearer $API_KEY" \
    --data-raw "$json_payload")
echo "Authorization: Bearer $API_KEY"

# 获取 excerpt 构建新的 frontmatter 结构，并写入新文件
excerpt_content=$(echo "$response" | jq -r '.choices[0].message.content')
yfm_content=$(echo "$yfm_content" | sed '1d;' | yq e '. + {"excerpt": "'"$excerpt_content"'"}' -)
yfm_content="---"$'\n'"$yfm_content"
new_file=$(echo "$file" | sed 's/\.md$/.bkp.md/')
echo "$yfm_content"$'\n'"$blog_content" > "$new_file"
```

脚本部分最核心的是主义调整下api的请求参数：

| 参数                 | 定义                                                         | 最佳设置      |
| -------------------- | ------------------------------------------------------------ | ------------- |
| **model**            | 使用模型，可选**DeepSeek-reasoner**，不过价格比DeepSeek-chat贵 | DeepSeek-chat |
| **max_tokens**       | 介于 1 到 8192 间的整数，限制一次请求中模型生成 completion 的最大 token 数。输入 token 和输出 token 的总长度受模型的上下文长度的限制。 | 3000          |
| **presence_penalty** | 介于 -2.0 和 2.0 之间的数字。如果该值为正，那么新 token 会根据其是否已在已有文本中出现受到相应的惩罚，从而增加模型谈论新主题的可能性。 | -2            |
| **temperature**      | 采样温度，介于 0 和 2 之间。更高的值，如 0.8，会使输出更随机，而更低的值，如 0.2，会使其更加集中和确定。 我们通常建议可以更改这个值或者更改 `top_p`，但不建议同时对两者进行修改。\**建议参考 [Temperature 设置](https://api-docs.deepseek.com/zh-cn/quick_start/parameter_settings) 来设置不同类型任务的参数*。 | 1.0           |
| **stream**           | 如果设置为 True，将会以 SSE（server-sent events）的形式以流式发送消息增量。消息流以 `data: [DONE]` 结尾。 | **false**     |

## 0x04 实战测试

### 本地测试

首先在本地替换 `excerptor.sh` 中的 `DS_API` 参数后，使用下面命令来给一个博客编写总结

```shell
./.github/workflows/excerptor.sh _posts/2025-01-25-DDIA-Chapter-02-Data-Model-and-DSL.md
```

![offline](\images\20250205\offline.png)

这时候目录中就出现了对应的 `2025-01-25-DDIA-Chapter-02-Data-Model-and-DSL.bkp.md` 文件，里面对应的 frontmatter 如下：

```yaml
title: "DDIA Chapter 02 Data Model and DS"
date: 2025-01-25
categories:
  - Architect Design
tags:
  - DDIA
excerpt: The blog excerpt discusses the evolution of data models, comparing relational and document models, highlighting the limitations of each, and exploring the rise of NoSQL and graph data models for handling complex relationships like many-to-many.
```

### 线上测试

本地测试后，只要将 Action 文件放到 `.github/workflows` 目录下，然后 push 回代码仓库。

之后打开Repo的Action面版，就能看到所有执行中的工作流了

- `xxx` 和 `test post` 是编写摘要的工作流，名称来源于使用的 commit 信息
- `pages build and deployment` 是 github.io 渲染线上页面的工作流

![online1](\images\20250205\online1.png)

打开一个编写摘要的工作流，还能看到具体所有子任务的执行状态和输出。

![online2](\images\20250205\online2.png)

最后打开目录，就能看到包含 excerpt 的新博客。

![online3](\images\20250205\online3.png)

## 0x05 预期成本

根据官方分析，使用 DeepSeek 模型输入字数和耗费 Token 的换算可以按下面公式计算，

- 1 个英文字符 ≈ 0.3 token
- 1 个中文字符 ≈ 0.6 token

按照一篇博客大概 2000-3000 个汉字计算，均值为 2500，平均一篇博客需要耗费1500个 token，按照使用 `deepseek-chat` 模型，且不使用缓存的情况，百万token耗费2元，赠送的10元，大概够跑3300多篇博客，增加了缓存后，还会更便宜。



