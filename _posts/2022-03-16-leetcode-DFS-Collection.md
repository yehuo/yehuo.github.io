---
title: "leetcode DFS Collection"
date: 2022-03-16
excerpt: "关于模拟的五道题，尤其注意回溯和深度搜索的使用"
categories: 
    - Algorithm
tags:
    - Leetcode
---



# 题目[2044](https://leetcode-cn.com/problems/count-number-of-maximum-bitwise-or-subsets)——统计按位或能得到最大值的子集数目

>给你一个整数数组 nums ，请你找出 nums 子集 按位或 可能得到的 最大值 ，并返回按位或能得到最大值的 不同非空子集的数目 。
>
>如果数组 a 可以由数组 b 删除一些元素（或不删除）得到，则认为数组 a 是数组 b 的一个 子集 。如果选中的元素下标位置不一样，则认为两个子集 不同 。
>
>对数组 a 执行 按位或 ，结果等于 a[0] OR a[1] OR ... OR a[a.length - 1]（下标从 0 开始）。

# 样例输入

> 输入：nums = [2,2,2]
> 输出：7
> 解释：[2,2,2] 的所有非空子集的按位或都可以得到 2 。总共有 23 - 1 = 7 个子集。

# 题目解析

直接爆搜即可，默认的搜法类似于从0001=>1111，逐个确定取不取，最终统一计算按位或（每次计算过程时间复杂度为$$O(N)$$）。

但是如果使用回溯，就不用重复计算某个数字之前的按位或之和，可以将时间复杂度从
$$
O(2^n×n)
$$
优化为
$$
O(2^0+2^1+...+2^n)=O(2×2^n)=O(2^n)
$$

# 题解

```python
class Solution:
    def countMaxOrSubsets(self, nums: List[int]) -> int:
        cnt,maxVal=0,0
        def dfs(pos: int,OrVal: int)->None:
            nonlocal cnt,maxVal
            if pos==len(nums):
                if OrVal>maxVal:
                    maxVal,cnt=OrVal,1
                elif OrVal==maxVal:
                    cnt+=1
                return
            dfs(pos+1,OrVal | nums[pos])
            dfs(pos+1,OrVal)
            return
        dfs(0,0)
        return cnt
```

# 题目[37](https://leetcode-cn.com/problems/sudoku-solver/)——解数独

> 编写一个程序，通过填充空格来解决数独问题。
>
> 数独的解法需 遵循如下规则：
>
> 数字 1-9 在每一行只能出现一次。
> 数字 1-9 在每一列只能出现一次。
> 数字 1-9 在每一个以粗实线分隔的 3x3 宫内只能出现一次。（请参考示例图）
> 数独部分空格内已填入了数字，空白格用 '.' 表示。

# 样例输入

> 输入：board = [["5","3",".",".","7",".",".",".","."],["6",".",".","1","9","5",".",".","."],[".","9","8",".",".",".",".","6","."],["8",".",".",".","6",".",".",".","3"],["4",".",".","8",".","3",".",".","1"],["7",".",".",".","2",".",".",".","6"],[".","6",".",".",".",".","2","8","."],[".",".",".","4","1","9",".",".","5"],[".",".",".",".","8",".",".","7","9"]]
>
> 输出：[["5","3","4","6","7","8","9","1","2"],["6","7","2","1","9","5","3","4","8"],["1","9","8","3","4","2","5","6","7"],["8","5","9","7","6","1","4","2","3"],["4","2","6","8","5","3","7","9","1"],["7","1","3","9","2","4","8","5","6"],["9","6","1","5","3","7","2","8","4"],["2","8","7","4","1","9","6","3","5"],["3","4","5","2","8","6","1","7","9"]]
>
> 解释：题目保证每个数独仅有唯一解


# 题目解析

爆搜，但是比较灵巧的地方在于行、列、块中出现数字的记录方式，如果为了进一步压缩空间，可以使用一个二进制数压缩对应记录。容易卡的地方，在于回溯终点以及`return`的位置。

# 题解

```python
class Solution:
    def solveSudoku(self, board: List[List[str]]) -> None:
        """
        Do not return anything, modify board in-place instead.
        """
        line=[[False]*9 for _ in range(9)]
        column=[[False]*9 for _ in range(9)]
        cell=[[[False]*9 for _a in range(3)] for _b in range(3)]
        space=[]
        valid=False

        def dfs(pos:int)->None:
            nonlocal line,column,cell,space,valid
            if pos==len(space):
                valid=True
                return
            i,j=space[pos]
            for x in range(9):
                if valid is True:
                    return     
                if line[i][x]==column[j][x]==cell[i//3][j//3][x]==False:
                    line[i][x]=column[j][x]=cell[i//3][j//3][x]=True
                    board[i][j]=str(x+1)
                    dfs(pos+1)
                    line[i][x]=column[j][x]=cell[i//3][j//3][x]=False  
        for i in range(9):
            for j in range(9):
                if board[i][j] =='.':
                    space.append((i,j))
                else:
                    val=int(board[i][j])-1
                    line[i][val]=True
                    column[j][val]=True
                    cell[i//3][j//3][val]=True
        dfs(0)
```



# 题目[67](https://leetcode-cn.com/problems/add-binary/)——二进制求和

> 给你两个二进制字符串，返回它们的和（用二进制表示）。
>
> 输入为 非空 字符串且只包含数字 1 和 0。

# 样例输入

> 输入: a = "11", b = "1"
> 输出: "100"

# 题目解析

理论上讲，应当按位运算，自己模拟实现进位。但是Python和Java都有字符转二进制的偷鸡办法，于是就直接去题解找Python黑魔法了。

# 题解

```python
class Solution:
    def addBinary(self, a, b) -> str:
        return '{0:b}'.format(int(a, 2) + int(b, 2))
```



# 题目[94](https://leetcode-cn.com/problems/binary-tree-inorder-traversal/)——二叉树的中序遍历

> 给定一个二叉树的根节点 `root` ，返回它的 **中序** 遍历。

# 样例输入

> 输入：root = [1,null,2,3]
> 输出：[1,3,2]

# 题目解析

几乎是无脑写出来的easy，这里有一个常识，就是要中序和后续遍历，以及从树回复数组的时候，往往需要单开一个递归函数，思路比较清晰。前序遍历如后面的100题，直接用也会比较轻松。

# 题解

```python
class Solution:
    def inorderTraversal(self, root: Optional[TreeNode]) -> List[int]:
        rest=[]
        if not root: return rest
        def searchNode(nodex: TreeNode)->None:
            nonlocal rest
            if nodex.left:
                searchNode(nodex.left)
            rest.append(nodex.val)
            if nodex.right:
                searchNode(nodex.right)
            return
        searchNode(root)
        return rest
```



# 题目[100](https://leetcode-cn.com/problems/same-tree/)——相同的树

> 给你两棵二叉树的根节点 `p` 和 `q` ，编写一个函数来检验这两棵树是否相同。
>
> 如果两个树在结构上相同，并且节点具有相同的值，则认为它们是相同的。

# 样例输入

> 输入：p = [1,2,3], q = [1,2,3]
> 输出：true

# 题目解析

因为本节点的值最好比较，一旦不符则直接结束比对，无需再比子树。所以这个题就是个先序遍历二叉树。注意`True`和`False`的递归终点，要么两个节点同时为空，要么任一为空，若两个都有值，则需比较`nodeVal`后继续比较子树。

# 题解

```python
class Solution:
    def isSameTree(self, p: TreeNode, q: TreeNode) -> bool:
        if p is None and q is None:
            return True
        if p is None or q is None:
            return False
        return p.val==q.val and self.isSameTree(p.left,q.left) and self.isSameTree(p.right,q.right)
```



# 小结

今天做的主题就是回溯、模拟、深度优先搜索，要注意以下几点：

- Python3实现深度优先搜索时，状态变量最好在函数中通过nonlocal关键字重新声明
- DFS大结构上就两点，一点是要在函数内重复调用自身函数，另一个就是搞好递归终点，注意要在哪些地方写`return`
- DFS比较坑的点在于，一个分支搜索完了一定要记得**恢复状态**，再进行下一分支搜索
- DFS难点则在于优化状态记录方法，剪枝
- 大模拟往往就是爆搜，就是要写好循环，终点就是要定义好循环层数，参照好$$ O(2^N) $$的时间复杂度