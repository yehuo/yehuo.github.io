#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

file=$1

if [ ! -f "$file" ]; then
  echo "File not found: $file"
  exit 1
fi

# 初始化条件变量
file_length=0

# 检查文件长度是否大于1行
if [ $(wc -l < "$file") -lt 1 ]; then
  echo "File length is less than 1 line."
  exit 1
fi

# 检查文件是否包含YAML front matter, 否则退出脚本
if ! head -n 1 "$file" | grep -q '^---$'; then
  echo "YAML frontmatter not found."
  exit 1
fi

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

# 输出yaml front matter
yfm_content=$(sed -n "${start_line},${end_line}p" "$file")
echo "Current YAML front matter:${IFS}$yfm_content${IFS}---"

# 检查是否存在以"excerpt:"开头的行，如果存在则退出脚本
if [ $(echo "$yfm_content" | grep "^excerpt:" | wc -l) -gt 0 ]; then
  echo "The excerpt exists, exiting."
  exit 0
fi

# 检查是否存在以"title:"开头的行，如果存在则提取title，否则提取文件名作为title
if [ $(echo "$yfm_content" | grep "^title:" | wc -l) -gt 0 ]; then
  title=$(echo "$yfm_content" | grep "^title:" | sed 's/^title: //')
else
  file_name=$(echo "$file" | awk -F'/' '{print $NF}')
  title=$(echo "$file_name" | cut -c12- | rev | cut -c4- | rev | tr '-' ' ')
fi
echo "The blog \"$title\" is under processing."
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
      model: "deepseek-chat",
      frequency_penalty: 0,
      max_tokens: 3000,
      presence_penalty: -1,
      response_format: {type: "text"},
      stop: null,
      stream: false,
      stream_options: null,
      temperature: 1.0,
      top_p: 1,
      tools: null,
      tool_choice: "none",
      logprobs: false,
      top_logprobs: null
    }')
# 构建deepseek请求
response=$(curl -s -L -X POST 'https://api.deepseek.com/chat/completions' \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "Authorization: Bearer $API_KEY" \
    --data-raw "$json_payload")

excerpt_content=$(echo "$response" | jq -r '.choices[0].message.content')
yfm_content=$(echo "$yfm_content" | sed '1d;' | yq e '. + {"excerpt": "'"$excerpt_content"'"}' -)
yfm_content="---"$'\n'"$yfm_content"
new_file=$(echo "$file" | sed 's/\.md$/.bkp.md/')
echo "$yfm_content"$'\n'"$blog_content" > "$new_file"

