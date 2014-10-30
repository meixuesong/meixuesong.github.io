---
layout: post
title: "有向图"
date: 2014-10-30 20:10:54 +0800
comments: true
categories: 
- 算法
---
有向图也就是有方向性的图，是由一组顶点和一组有方向的边组成，每条有方向的边都连接着有序的一对顶点。本文要解决的有向图问题：

1. 单点和多点的可达性
2. 单点有向路径
3. 单点最短有向路径
4. 有向环检测
5. 深度优先的顶点排序
6. 优先级限制下的调度问题
7. 拓扑排序
8. 强连通性
9. 顶点对的可达性

<!--more-->

##1. 术语

* 出度：一个顶点指出的边的总数；
* 入度：指向该顶点的边的总数；
* 一条有向边的第一个顶点称为头，第二个顶点称为尾。
* 在一幅有向图中，有向路径由一系列顶点组成，对于其中的每个顶点都存在一条有向边从它指向序列中的下一个顶点。

## 2. 有向图的数据类型
有向图的API与无向图本质相同，只是多了一个取反操作。如下图：

![image](/myresource/images/image_blog_2014-10-20-digraph-api.png)

其中，reverse()方向返回有向图的一个副本，但是将其中的方向反转。adj()返回的是每个顶点指出的边所连接的所有顶点。

Diagraph的实现与无向图Graph非常类似，也是采用邻接表实现，但由于边是有向的，所以假设7-->8的一条边，则在顶点7的邻接表中有8，而顶点8的邻接表却没有7. [实现代码](http://algs4.cs.princeton.edu/42directed/Digraph.java.html)不再重复。

## 3. 有向图中的可达性
* 单点可达性：是否存在一条从s到达给定顶点v的有向路径？
* 多点可达性：是否存在一条从集合中的任意顶点到达给定顶点v的有向路径？

API定义和实现如下：

```
public class DirectedDFS {
	private boolean[] marked;
	
	//在G中找到从s可达的所有顶点
	public DirectedDFS(Digraph G, int s) {
		marked = new boolean[G.V()];
		dfs(G, s);
	}
	
	//在G中找到从sources中的所有顶点可达的所有顶点
	public DirectedDFS(Digraph G, Iterable<Integer> sources) {
		marked = new boolean[G.V()];
		for(int s : sources) {
			if (! marked[s]) dfs(G, s);
		}
	}
	
	private void dfs(Digraph G, int v) {
		marked[v] = true;
		for(int w : G.adj(v)){
			if (!marked[w]) dfs(G, w);
		}
	}
	
	//v是可达的吗？
	public boolean marked(int v) {
		return marked[v];
	}
}
```

**标记-清除：**多点可达性的一个重要典型应用就是内存管理，包括许多Java的实现。一个顶点表示一个对象，一条边表示一个对象对另一个对象的引用。在程序执行任何时候，都有某些对象是可以被直接访问的，而不能通过这些对象访问到的所有对象都应该被回收。标记-清除的垃圾回收策略会为每个对象保留一个位做垃圾收集之用。

**有向图的寻路：**

* 单点有向路径：从s到给定的顶点v是否存在一条有向路径？如果有，找出这条路径。
* 单点最短有向路径：从s到给定的顶点v是否存在一条有向路径？如果有，找出最短的那边。

这两个问题都可以通过深度优先和广度优先解决，它们仍是有向图的重要算法。API和代码也基本相同。

## 4. 环和有向无环图

### 4.1 有向图中的环
任务调度是一个典型的有向图用例，其限制条件包括任务的起始时间、时耗、优先级限制（某个任务是另一个任务的前置条件）等。如何进行正确的任务调度？这需要**拓扑排序**：给定一幅有向图，将所有的顶点排序，使得所有的有向边均从排在前面的元素指向排在后面的元素。拓扑排序的例子还包括课程安排（先导课程限制）、继承（Java extends）、电子表格公式等等。

如果一个有优先级限制的问题中存在有向环，例如任务x必须在任务y之前完成，而y必须在z之前完成，但z又必须在x之前完成，那么这个问题就无解了！所以首先要解决**有向环的检测**：给定的有向图中包含有向环吗？

**有向无环图（DAG）是一幅不含有向环的有向图。**

有向环的检测可以通过深度优先搜索来解决。用一个栈表示正在遍历的有向路径，一旦找到一条有向边v->w且w已经在堆栈中，就找到了一个环。

```java
public class DirectedCycle {
    private boolean[] marked;        // marked[v] = 顶点v是否已经访问过?
    private int[] edgeTo;            // edgeTo[v] = 指向v的前一个顶点
    private boolean[] onStack;       // onStack[v] = 顶点v在递归调用的堆栈上吗？
    private Stack<Integer> cycle;    // 有向环 (null表示不存在有向环)

    public DirectedCycle(Digraph G) {
        marked  = new boolean[G.V()];
        onStack = new boolean[G.V()];
        edgeTo  = new int[G.V()];
        for (int v = 0; v < G.V(); v++)
            if (!marked[v]) dfs(G, v);
    }

    private void dfs(Digraph G, int v) {
        onStack[v] = true;
        marked[v] = true;
        for (int w : G.adj(v)) {
            // 如果环已找到，退出
            if (cycle != null) {
            	   return;
            }
            //找到新顶点，继续
            else if (!marked[w]) {
                edgeTo[w] = v;
                dfs(G, w);
            }
            // 找到有向环，记录下路径
            else if (onStack[w]) {
                cycle = new Stack<Integer>();
                for (int x = v; x != w; x = edgeTo[x]) {
                    cycle.push(x);
                }
                cycle.push(w);
                cycle.push(v);
            }
        }

        onStack[v] = false;
    }

	//是否含有有向环
    public boolean hasCycle() {
        return cycle != null;
    }

    //有向环中的所有顶点（如果存在有向环的话）
    public Iterable<Integer> cycle() {
        return cycle;
    }
}
```
### 4.2 顶点的深度优先次序与拓扑排序
优先级限制下的调度问题等价于计算有向无环图中的所有顶点的拓扑排序。只需要在标准深度优先搜索中，将`dfs()`的顶点参数保存在一个数据结构中，遍历这个数据结构就能访问所有的顶点。遍历的顺序取决于这个数据结构的性质以及是在递归调用之前还是之后进行保存。主要有3种排序顺序：

1. 前序(pre)：在递归调用之前将顶点加入队列。
2. 后序(post)：在递归调用之后将顶点加入队列。
3. 逆后序(reversePost)：在递归调用之后将顶点压入堆栈。

对于这样一张有向图，三种顺序遍历过程如下：

![image](/myresource/images/image_blog_2014-10-29-dag.png)

![image](/myresource/images/image_blog_2014-10-29-depth-first-orders.png)


下面实现的DepthFirstOrder实现了这三种排序：

```java
public class DepthFirstOrder {
    private boolean[] marked;          // marked[v] = has v been marked in dfs?
    private Queue<Integer> pre;                 // pre[v]    = preorder  number of v
    private Queue<Integer> post;                // post[v]   = postorder number of v
    private Stack<Integer> reversePost;
    
    public DepthFirstOrder(Digraph G) {
        pre    = new Queue<Integer>();
        post   = new Queue<Integer>();
        reversePost = new Stack<Integer>();
        marked    = new boolean[G.V()];
        
        for (int v = 0; v < G.V(); v++)
            if (!marked[v]) dfs(G, v);
    }

    private void dfs(Digraph G, int v) {
        pre.enqueue(v);
        
        marked[v] = true;
        
        for (int w : G.adj(v)) {
            if (!marked[w]) {
                dfs(G, w);
            }
        }
        
        post.enqueue(v);
        reversePost.push(v);
    }
    
    public Iterable<Integer> pre() {
    	return pre;
    }
    public Iterable<Integer> post() {
    	return post;
    }   
    public Iterable<Integer> reversePost() {
    	return reversePost;
    }
}
```

DepthFirstOrder提供了三种排序的顶点列表：pre, post, reversePost，因此拓扑排序就非常简单了：

```java
public class Topological {
    private Iterable<Integer> order;    // topological order

    public Topological(Digraph G) {
        DirectedCycle finder = new DirectedCycle(G);
        if (!finder.hasCycle()) {
            DepthFirstOrder dfs = new DepthFirstOrder(G);
            order = dfs.reversePost();
        }
    }

	//拓扑有序的所有顶点
    public Iterable<Integer> order() {
        return order;
    }

	//G是有向无环图吗？
    public boolean isDAG() {
        return order != null;
    }
}    
```

**一幅有向无环图的拓扑顺序就是所有顶点的逆后序排列。**这是一个重要结论！证明如下：对于任意边v->w, 在调用dfs(v)时，必有以下三种情况之一：

1. dfs(w)已经被调用过且已经返回（w已经被标记）。
2. dfs(w)还没有被调用，因此v->会直接或间接调用并返回dfs(w)，且dfs(w)会在dfs(v)返回前返回。
3. dfs(w)已经被调用但未返回。

第3种情况表示存在环，所以在有向无环图中是不可能出现的。第1、2种情况都证明了dfs(w)会先于dfs(v)完成。后序排列时w在v之前，只有逆后序时，w排在v之后。因此逆后序是有向无环图的拓扑顺序。

再次说明，拓扑排序和有向环的检测总是一起出现的，因为有向环的检测是排序的前提。

## 5. 有向图的强连通性
如果两个顶点v和w是互相可达的，也就是存在一条从v到w的有向路径，同时还存在一条从w到v的有向路径，那么v和w是**强连通**的。

强连通性将所有顶点分为一些等价类，每个等价类都由相互均为强连通的顶点的最大子集组成，这些子集称为**强连通分量**。强连通分量的典型应用包括：网络（网页和超链接）、软件（模块和调用）、食物链（物种和捕食关系）等。强连通分量的API:

![image](/myresource/images/image_blog_2014-10-30-scc-api.png)

### 5.1 Kosaraju算法
Kosaraju算法实现了SCC API：

* 在给定的一幅有向图G中，使用DepthFirstOrder来计算它的反向图G^R的逆后序排列。
* 在G中进行标准的深度优先搜索，但是要按照刚才计算得到的顺序而非标准的顺序来访问所有未被标记的顶点。
* 在构造函数中，所有在同一个递归dfs()调用中被访问到的顶点都在同一个强连通分量中，将它们按照和CC相同的方式识别出来。

要证明Kosaraju算法的正确性，首先证明：“每个和s强连通的顶点v都会在构造函数调用的dfs(G,s)中被访问到。”这个毫无疑问。然后再证明：“构造函数调用的dfs(G,s)所到达的任意顶点v都必然是和s强连通的。”设v为dfs(G,s)到达的某个顶点。那么G中必然存在一条从s到v的路径，因此只需证明G中还存在一条从v到s的路径即可。也就等价于证明G^R中存在一条从s到v的路径：

>按照逆后序进行的深度优先搜索意味着，在G^R中进行的深度优先搜索中，dfs(G,v)必然在dfs(G,s)之前就已经结束了，这样dfs(G,v)的调用就只会出现两种情况：

> 1. 调用在dfs(G,s)的调用之前（并且也在dfs(G,s)的调用之前结束）
> 2. 调用在dfs(G,s)的调用之后（并且也在dfs(G,s)的调用之前结束）
> 
> 第一种情况不可能出现，因为在G^R中存在一条从v到s的路径；而第二种情况说明G^R中存在一条从s到v的路径。证毕。

```java
public class KosarajuSharirSCC {
    private boolean[] marked;     //已访问过的顶点
    private int[] id;             //强连通分量的标识符
    private int count;            //强连通分量的数量

    public KosarajuSharirSCC(Digraph G) {

        // compute reverse postorder of reverse graph
        DepthFirstOrder dfs = new DepthFirstOrder(G.reverse());

        // run DFS on G, using reverse postorder to guide calculation
        marked = new boolean[G.V()];
        id = new int[G.V()];
        for (int v : dfs.reversePost()) {
            if (!marked[v]) {
                dfs(G, v);
                count++;
            }
        }
    }

    private void dfs(Digraph G, int v) { 
        marked[v] = true;
        id[v] = count;
        for (int w : G.adj(v)) {
            if (!marked[w]) dfs(G, w);
        }
    }

    //图中的强连通分量的总数
    public int count() {
        return count;
    }

    //v和w是强连通的吗
    public boolean stronglyConnected(int v, int w) {
        return id[v] == id[w];
    }

    //v所在的强连通分量的标识符（在0至count()-1之间）
    public int id(int v) {
        return id[v];
    }
}    
```

### 5.2 顶点对的可达性
给定一幅有向图，回答“是否存在一条从一个给定的顶点v到达另一个给定的顶点w的路径？”对于无向图，这个问题等价于连通性问题。而对有向图，有很大区别。看似简单的问题困难了专家数十年。如何大幅减少预处理所需的时间和空间，又保证常数的查询时间。这仍然是一个有待解决的问题。而且这个问题有重要的实际意义：处理互联网这样的巨型有向图。

下面的算法只是简单地实现了可达性，但不适用于处理大型有向图，因为它所需的空间与V^2成正比，所需时间和V(V+E)成正比。但如果图小的话，仍然是一个理想的解决办法。

```
public class TransitiveClosure {
    private DirectedDFS[] tc;  // tc[v] = reachable from v

    //预处理的构造方法
    public TransitiveClosure(Digraph G) {
        tc = new DirectedDFS[G.V()];
        for (int v = 0; v < G.V(); v++)
            tc[v] = new DirectedDFS(G, v);
    }

    //w是从v可达的吗？
    public boolean reachable(int v, int w) {
        return tc[v].marked(w);
    }
}
```    



