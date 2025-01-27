---
title: GPT with Canvas
date: 2024-10-12
excerpt: "GPT中关于Canvas的新用法"
categories: 
    - AI
tags: 
    - ChatGPT
---



![CanvasIntro](\images\20241012\Canvas.jpg)


## 0x01 什么是 Canvas ？

近期GPT 推出了一个测试模型： **GPT-4o Canvas**。

Canvas 使用了全新的界面，可用于与 ChatGPT 合作编写，甚至多文件的编码项目，而不仅仅是简单的聊天。

使用过程中，Canvas 会在一个单独的窗口中打开，让用户和 ChatGPT 合作完成一个项目。这个早期测试版引入了一种全新的合作方式 — 不仅仅是通过对话，还可以直接通过code或者文案来和GPT进行交互。 

Canvas 是使用 GPT-4o 构建的，在测试版中可以在模型选择器中手动选择。但仅有 ChatGPT Plus 和 Team 用户可以访问 Canvas。企业版和教育版用户将于下周（2024.10.10）获得访问权限。之后 OpenAI 还会计划在测试版结束后向所有 ChatGPT Free 用户提供 Canvas。

## 0x02 为什么要用 Canvas ？ 

作为 ChatGPT 深度用户，我基本每天都会使用 ChatGPT 来获取代码方面的帮助，包括从0到1编写脚本，以及优化、解释和注释我的代码。

但在使用过程中，聊天界面虽然易于和 AI 沟通信息，但当需要编辑和修改代码时，界面输入就会开始受限，同时经常因为反复提交代码，导致消耗海量的 token。

现在 Canvas 为这类工作提供了一个新界面。

通过 Canvas ，ChatGPT 可以很好地理解代码和需求的不同。而且可以突出显示特定部分，以准确表明希望 ChatGPT 关注的内容。就像文字编辑或 code reviewer 一样，来针对整个项目提供高相关度的反馈和建议。

此外，在之前的使用过程中，用户可以在 Canvas 中控制项目，也一个编辑器中同时生成多个文件。用户还可以直接编辑文本或代码。同时支持快捷方式菜单，可以让 ChatGPT 调整书写长度、调试代码以及​​快速执行其他有用的操作，甚至还可以使用 roll back 按钮恢复先前生成的版本。

## 0x03 怎么用 GPT Canvas

当 ChatGPT 检测到 Canvas 可能有用的场景时，它就会自动打开。用户还可以在提示中包含“使用 Canvas”以打开 Canvas 并使用它来处理现有项目。

在使用 Canvas 进行书写的时候，Canvas 页面支持下面的快捷方式：

- 建议编辑： ChatGPT 提供内联建议和反馈。
- 调整长度：编辑文档长度以使其更短或更长。
- **改变书写水平**：调整书写水平，从幼儿园到研究生院。
- 规范润色：检查语法、清晰度和一致性。
- 添加表情符号：添加相关表情符号以强调和着色。

在使用 Canvas 进行coding的时候，Canvas 页面支持下面的快捷方式：

- 审查代码： ChatGPT 提供内联建议来改进您的代码。
- 添加日志：插入打印语句以帮助调试和理解代码。
- 添加注释：在代码中添加注释，使其更容易理解。
- 修复错误：检测并重写有问题的代码以解决错误。
- **语言移植**：将已有代码翻译成 JavaScript、TypeScript、Python、Java、C++ 或 PHP。

## 0x04 Canvas 为什么会更强？

除了本身的功能介绍外，官方发布特别提到的一件事就是他们是如何训练新模型 GPT-4o with Canvas （相比于原生 Prompt GPT-4o）来变成一个更加智能的内容合作者。他们着重提到了下面三个优化项目。

### 1. 什么时候 Canvas 会被触发

官方提到产品设计过程中的一个关键挑战是确定何时触发 Canvas 页面。他们教会模型打开 Canvas 页面来处理诸如“写一篇关于咖啡豆历史的博客文章”之类的提示，同时避免过度触发一般问答任务，例如“帮我做一道新的晚餐菜谱”。对于 Writing 任务，他们优先改进了“正确的触发器”（以“正确的非触发器”为代价），与带有提示指令的基线零样本 GPT-4o 相比，成功率达到了 83%。

但值得注意的是，此类基线的质量对所使用的特定提示高度敏感。使用不同的提示，基线可能仍然表现不佳，但表现方式不同。例如，在编码和写作任务中表现不准确，导致错误分布不同，并导致表现不佳。对于编码，OpenAI 故意让模型偏向于触发，以避免打扰使用代码功能的高级用户。他们也将根据用户反馈继续完善这一点。

![TriggerCanvasBenchmark](\images\20241012\Benchmark-01.jpg)

> For writing and coding tasks, we improved correctly triggering the canvas decision boundary, reaching 83% and 94% respectively compared to a baseline zero-shot GPT-4o with prompted instructions.

### 2. 如何避免 Canvas 进行非必要的重写（re-writing）

官方在发布中提到的第二个挑战则是在触发 Canvas 后，如何调整模型的编辑行为。具体来说，就是决定何时进行有针对性的编辑，而不是重写整个内容。

他们有意训练模型在用户通过提示词明确给出要编辑的部分时，优先执行有针对性的编辑，否则倾向于重写。而且后续随着模型的完善，这种行为会不断进行优化。在使用过程中，这样的优化确实大大加快了生成速度和代码变更的准确度。

![CanvasModelBenchmark](\images\20241012\Benchmark-02.jpg)

> For writing and coding tasks, we prioritized improving canvas targeted edits. GPT-4o with canvas performs better than a baseline prompted GPT-4o by 18%.

### 3. 如何让 Canvas 的意见（Comments）更加准确

而官方提到的最后一个挑战，是以往模型训练过程中，生成高质量评论往往需要细致的迭代。

与前两种情况不同，前两种情况很容易使用自动评估结合部分人工审核来评估效果，但以自动化方式衡量 Comment 质量则很具有挑战性。

因此，他们使用了人工评估来分析 Comment 的质量和准确性。OpenAI 在集成 Canvas 模型在准确率和质量上均优于零样本 GPT-4o，前者高出 30%，后者高出 16%，这表明与带有详细说明的零样本提示相比，合成训练显著提高了响应质量和行为。

![CommentBenchmark](\images\20241012\Benchmark-03.jpg)

> Human evaluations assessed canvas comment quality and accuracy functionality. Our canvas model outperforms the zero-shot GPT-4o with prompted instructions by 30% in accuracy and 16% in quality.

最后，在我个人实际使用过程中，GPT-4o with Canvas 确实感觉也会在用户发送内容理解上更加“聪明”。同时对于我要求修改的部分确实也可以更加精准地定位和修改。

## 0x05 我对 Canvas 产品力的一点看法

作为各类 AI 产品的资深使用用户，从 copilot 到 Notion AI，热点的文本和代码创作类 AI 我基本都使用过。这方面一直都是业界热点，同时也是最能直接提升生产力的领域。但是不同的使用场景和产品形态，严重地导致了不同 AI 发挥效能的大小。在这一领域中 AI 模型的好坏，已经不再是产品的唯一决定因素。

而结合我之前的使用体验，现在如果拿 Canvas 和先前的 Copilot 以及 Notion AI 做个对比的话，在代码生成方面，OpenAI公司本身强悍的模型能力赋予了 Canvas 比 Copilot 更强大的代码生成能力和分析能力（copilot在提示词理解方面，感觉是差点意思）。

而文本生成方面，虽然 Notion AI 对提示词理解和内容生成方面基本满足我的要求，但是各式各样的功能限制，和付费限制，让 Notion AI 的使用成本（操作复杂度和价格）方面都显得有些让人不爽。

但 Canvas 其实也有劣势，那就是因为 **没有与既有产品（例如vscode）的绑定**，这导致 Canvas 中很多代码操作并不是那么用户友好的。

举例来说，在 copilot 对代码的修改中，真的是可以通过右键做到代码块级别的重写和注释，而在 Canvas 即使不需要进行通篇重写时，也会从头逐行扫描代码（ Canvas中通常是包括很多文件的 ），直至找到需要修改的代码块。

对比 GPT-4o 的反应速度，我们可以知道导致 Canvas 中修改代码块的时间都花在了代码逐行输入输出上。而能否补足这种产品上的缺陷或许是他们能否真的抢占相关市场的关键。