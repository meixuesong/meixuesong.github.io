---
layout: post
title: "符号表"
date: 2014-10-02 11:26:20 +0800
comments: true
categories: 
- 算法
---

符号表就是用键和值的方式来存储和检索数据。其关键点在于如何快速检索和高效插入。本章介绍了符号表的简单实现、二叉查找树、红黑树的实现。

<!--more-->

首先还是来定义一下简单的符号表API：

![image](/myresource/images/image_blog_20141002_170641.jpg)

## 1. API定义
符号表遵循以下规则：

* 每个键只对应一个值；
* 当存入的键值对和表中已有的键冲突时，新的值会替代旧的值；
* 键不能为空；
* 值不允许为空；

在简单的符号表中，键的等价性由equals()方法保证。而很多典型应用中，键都是Comparable对象，因此有序符号表可以保持键的有序并扩展其API：

![image](/myresource/images/image_blog_20141002_170651.jpg)

* floor：向下取整，找出小于等于该键的最大键；
* ceiling：向上取整，找出大于等于该键的最小键；
* rank：小于key的键的数量；
* select：获得排名为第k的键。

对于0到size()-1的所有i都有：i == rank(select(i))，且所有键都满足：key == select(rank(key))。

## 2. 实现
### 2.1 无序链表的顺序查找
可以用链表来实现符号表，每个结点存储一个键值对，并保持一个链接指向下一个结点。这种方式非常简单，但是效率非常低。不论是get方法还是put方法，都需要从首节点开始一个一个地遍历。

### 2.2 有序数组中的二分查找
另一种实现方法是通过两个平行的数组来存储符号表。一个储存键，一个存储值。二分法可以用于保证数组中Comparable类型的键有序，并高效地实现get和其他操作(如select)。

对N个键的有序数组进行二分查找最多需要（lgN + 1）次比较。然而put方法却仍然很慢，向大小为N的有序数组插入一个新的元素，在最坏的情况下需要访问约2N次数组。因此向一个空的符号表插入N个元素时，最坏的情况下需要访问约N^2次数组。

因此，我们需要一种结构，能够同时拥有二分法的查找效率和链表的插入效率。这就是二叉查找树。

### 2.3 二叉查找树(BST)
二叉查找树的定义：它是一棵二叉树，其中每个结点都含有一个Comparable的键以及相关联的值，每个结点的键都大于其左子树任意结点的键，同时小于右子树任意结点的键。

#### 2.3.1 基本实现
如果将一棵二叉查找树的所有键投影到一条直线上，我们可以得到一条有序的键列，如下图所示：

![image](/myresource/images/image_blog_2014-10-02_15.10.37.png)

树结点的实现：

```java
    private class Node {
        private Key key;           // sorted by key
        private Value val;         // associated data
        private Node left, right;  // left and right subtrees
        private int N;             // number of nodes in subtree

        public Node(Key key, Value val, int N) {
            this.key = key;
            this.val = val;
            this.N = N;
        }
    }
```

##### 查找
可以使用递归算法在二叉查找树中查找一个键：如果树是空的，则查找未命中；如果被查找的键和根结点的键相等，查找命中；否则就（递归地）在某个子树中继续查找。如果被查找的键较小就选择左子树，较大则选择右子树。查找过程与二分查找一样简单，代码实现如下：

```java
    public Value get(Key key) {
        return get(root, key);
    }

    private Value get(Node x, Key key) {
        if (x == null) return null;
        int cmp = key.compareTo(x.key);
        if      (cmp < 0) return get(x.left, key);
        else if (cmp > 0) return get(x.right, key);
        else              return x.val;
    }
```
##### 插入
二叉查找树的插入实现难度和查找差不多。当查找到一个不存在于树中的结点并结束于一条空链接时，我们需要做的就是将链接指向一个含有被查找的键的新结点。代码实现如下：

```java
    public void put(Key key, Value val) {
        if (val == null) { delete(key); return; }
        root = put(root, key, val);
    }

    private Node put(Node x, Key key, Value val) {
        if (x == null) return new Node(key, val, 1);
        int cmp = key.compareTo(x.key);
        if      (cmp < 0) x.left  = put(x.left,  key, val);
        else if (cmp > 0) x.right = put(x.right, key, val);
        else              x.val   = val;
        x.N = 1 + size(x.left) + size(x.right);
        return x;
    }
```

##### 分析
二叉查找树的算法效率取决于树的形状。在最好的情况下，树是完全平衡的，此时查找和插入的效率都非常高。

但是，树的结构与结点插入的顺序是相关的。在最坏的情况下（例如升序队列中的元素按顺序插入）可能形成一条单边的树，就变成了链表的结构。这种不平衡的树完全失去了二分查找的效率。

因此，如何保持树的平衡是一个重要问题。要在二叉树动态插入中保证树的完美平衡，代价太高了。因此需要对结构进行一些调整，这就是平衡查找树。

### 2.4 2-3查找树
所谓2-3查找树，是指它或者为一棵空树，或者由以下结点组成：

* 2-结点，含有一个键（及其对应的值）和两条链接，左链接指向的树的所有键都小于该结点，右链接指向的树的所有键都大于该结点。
* 3-结点，含有两个键（及其对应的值）和两条链接，左链接指向的树的所有键都小于该结点，中链接指向的树的所有键都位于该结点的两个键之间，右链接指向的树的所有键都大于该结点。

利用2-3查找树，可以方便地实现完美平衡的查找树，2-3查找树示意图如下：

![image](/myresource/images/image_blog_2014-10-02_17_49.png)

#### 2.4.1 查找
查找的过程与二叉查找树类似，区别仅在于3-结点树多了一个中链接。

#### 2.4.2 插入 
2-3查找树实现平衡的关键是插入过程，插入时先进行查找，如果未命中，将根据结束位置的多种情况，采用不同的方法。详细说明如下：

##### 向2-结点插入新键
如果查找结束于一个2-结点，只要把这个2-结点替换为一个3-结点，将要插入的键保存在其中即可。如下图所示：

![image](/myresource/images/image_blog_2014-10-02_23tree-insert2.png)

##### 向一棵只含有一个3-结点的树中插入新键
向3-结点的树中插入新键，也有多种情况，先看最简单的这种。如下图所示，先将3-结点变成4-结点，然后再分解为2-3树。

![image](/myresource/images/image_blog_2014-10-02_23tree-insert3a.png)

##### 向一个父结点为2-结点的3-结点插入新键
如果父结点为2-结点，则先把3-结点变成4-结点，然后将2-结点变成3-结点，如下图所示：

![image](/myresource/images/image_blog_2014-10-02_23tree-insert3b.png)

##### 向一个父结点为3-结点的3-结点插入新键
跟前一步一样，先变成4-结点并分解它，然后再将它的中键插入它的父结点中。但其父结点也是3-结点，因此再用这个中键构造一个临时的4-结点，进行相同的变化，直到遇到一个2-结点将它变成3-结点。如果一直到根结点都是3-结点，则需要分解根结点。插入新键的过程如下图所示：

![image](/myresource/images/image_blog_2014-10_02_23tree-insert3c.png)

##### 分解根结点
在上一步中，根结点变成了一个临时的4-结点，此时我们按照向一棵只有一个3-结点的树中插入新键的方法处理此问题。将4-结点分解成3个2-结点，树高加1。如下图所示：

![image](/myresource/images/image_blog_2014-10-02_23tree-split.png)

#### 2.4.3 性能分析 
从上面这些情况可以看出，插入过程都是进行局部变换，除了相关的结点和链接之外不必修改或检查树的其他部分，因此效率非常高。经过变换后，保持了树的有序性和平衡性。因此在一棵大小为N的2-3树中，查找和插入操作访问的结点必然不超过lgN个！例如含有10亿个结点的一棵2-3树的高度仅在19-30之间，最多只需要访问30个结点就能够在10亿个键中进行任意查找和插入操作，这是多么惊人！这也是[程序员的数学](/blog/2014/08/25/cheng-xu-yuan-de-shu-zi/)中提到的利用指数爆炸解决问题。

### 2.5 红黑二叉查找树
2-3查找树很容易理解，现在我们通过红黑二叉树来表达并实现它。其关键是3-结点如何实现。我们将树中的链接分为两种类型：红链接将两个2-结点连接起来构成一个3-结点，黑链接则是普通链接。如下图所示：

![image](/myresource/images/image_blog_2014-10-02_redblack-encoding.png)

红黑树是含有红黑链接并满足以下条件的二叉查找树：

* 红链接均为左链接；
* 没有任何一个结点同时和两条红链接相连；
* 该树是完美黑色平衡的，即任意空链接到根结点的路径上的黑链接数量相同。

因此在节点类（Node）中，增加一个属性color表示从父结点指向自己的链接是否为红链接，当：

```java
    private class Node {
        private Key key;           // sorted by key
        private Value val;         // associated data
        private Node left, right;  // left and right subtrees
        private int N;             // number of nodes in subtree
        boolean color;			   //是否红链接	

        public Node(Key key, Value val, int N, boolean color) {
            this.key = key;
            this.val = val;
            this.N = N;
            this.color = color;
        }
    }
```

在进一步实现红黑树之前，要了解几个基本的动作：左旋转、右旋转和颜色转换。

#### 2.5.1 旋转
左旋转是将一条红色的右链接转化为左链接。转换的过程为：将两个键中的较小者作为根结点变为将较大者作为根结点。如下图所示：

![image](/myresource/images/image_blog_2014-10-02_redblack-left-rotate.png)

右旋转是将一条红色的左链接转化为右链接，实现过程与左旋转相似，只需要将left和right互换即可：

![image](/myresource/images/image_blog_2014-10-02_redblack-right-rotate.png)

#### 2.5.2 颜色转换
颜色转换是对一个结点的两个红色子结点的颜色进行转换。除了将子结点的颜色由红变黑外，还要同时将父结点的颜色由黑变红。如下图所示：

![image](/myresource/images/image_blog_2014-10-02_color-flip.png)

#### 2.5.3 插入处理过程
插入新键时，都使用红链接与父结点相连，然后谨慎地使用左旋转、右旋转和颜色转换这三个简单的操作，就能够保证操作后的红黑树与2-3树一一对应的关系。在沿着插入点到根结点的路径向上移动时在所经过的每个结点中顺序完成以下操作，我们就能完成插入操作：

1. 如果右子结点是红色，而左子结点是黑色，进行左旋转；
2. 如果左子结点是红色，且它的左子结点也是红色，进行右旋转；
3. 如果左右子结点都是红色，进行颜色转换。

下面是各种情况的示例：

![image](/myresource/images/IMG_20141002_222628.jpg)

![image](/myresource/images/IMG_20141002_222714.jpg)

#### 2.5.4 插入算法的实现
以下为红黑树的插入算法：

```java
public class RedBlackBST<Key extends Comparable<Key>, Value> {

    private static final boolean RED   = true;
    private static final boolean BLACK = false;

    private Node root;     // root of the BST

    // BST helper node data type
    private class Node {
        private Key key;           // key
        private Value val;         // associated data
        private Node left, right;  // links to left and right subtrees
        private boolean color;     // color of parent link
        private int N;             // subtree count

        public Node(Key key, Value val, boolean color, int N) {
            this.key = key;
            this.val = val;
            this.color = color;
            this.N = N;
        }
    }

    // insert the key-value pair; overwrite the old value with the new value
    // if the key is already present
    public void put(Key key, Value val) {
        root = put(root, key, val);
        root.color = BLACK;
    }

    // insert the key-value pair in the subtree rooted at h
    private Node put(Node h, Key key, Value val) { 
        if (h == null) return new Node(key, val, RED, 1);

        int cmp = key.compareTo(h.key);
        if      (cmp < 0) h.left  = put(h.left,  key, val); 
        else if (cmp > 0) h.right = put(h.right, key, val); 
        else              h.val   = val;

        // fix-up any right-leaning links
        if (isRed(h.right) && !isRed(h.left))      h = rotateLeft(h);
        if (isRed(h.left)  &&  isRed(h.left.left)) h = rotateRight(h);
        if (isRed(h.left)  &&  isRed(h.right))     flipColors(h);
        h.N = size(h.left) + size(h.right) + 1;

        return h;
    }
}
```

#### 2.5.5 删除操作
##### 删除最小键
先来看删除最小键。从树底部的3-结点删除键很简单，但2-结点则不然。为了保证我们不会删除一个2-结点，我们沿着左链接向下进行变换，确保当前结点不是2-结点。在沿着左链接向下的过程中，保证以下情况之一成立：

* 如果当前结点的左子结点不是2-结点，完成；
* 如果当前结点的左子结点是2-结点而它的亲兄弟结点不是2-结点，将左子结点的兄弟结点中的一个键移到左子结点；
* 如果当前结点的左子结点和它的亲兄弟结点都是2-结点，将左子结点、父结点中的最小键和左子结点最近的兄弟结点合并为一个4-结点，使父结点由3-结点变为2-结点或者4-结点变为3-结点。

在遍历的过程中执行这个过程，最后能够得到一个含有最小键的3-结点或者4-结点，然后我们就可以直接从中将其删除，将3-结点变为2-结点，或者将4-结点变为3-结点。然后我们再回头向上分解所有临时的4-结点。

![image](/myresource/images/IMG_20141002_232607.jpg)

##### 删除操作
在查找路径上进行和删除最小键相同的变换同样可以保证在查找过程中任意当前结点均不是2-结点。如果被查找的键在树的底部，我们可以直接删除它。如果不在，我们需要将它和它的后续结点交换，就和二叉查找树一样。因为当前结点必然不是2-结点，问题已经转化为在一棵根结点不是2-结点的子树中删除最小键，我们可以在这棵子树中使用上面的算法。删除之后，同样需要向上回溯并分解余下的4-结点。

[红黑树完整代码](/myresource/code/RedBlackBST.java)

#### 2.5.6 红黑树的性能
一棵大小为N的红黑树的高度不会超过2lgN，根结点到任意结点的平均路径长度为1.00lgN，以下操作在最坏的情况下所需的时间是对数级别的：get, put, min, max, floor, ceiling, rank, select, deleteMin, deleteMax, delete, range。

## 总结
各种符号表实现的性能总结：

![image](/myresource/images/IMG_20141002_233353.jpg)

在信息世界的汪洋大海中，表的大小可能是上千亿，但我们仍然能够确保在几十次比较之内就完成这些操作！