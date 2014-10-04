---
layout: post
title: "无向图"
date: 2014-10-03 18:18:44 +0800
comments: true
categories: 
- 算法
---
无向图由一组顶点(Vertex)和一组能够将两个顶点相连的边(Edge)组成。本章学习无向图的邻接表实现，以及相关的搜索和应用，例如深度优先和广度优先搜索，路径查找和最短路径计算，连通分量和符号图。

<!--more-->

## 1. 术语
v-w表示连接v和w的边。自环和平行边是两种特殊的图。**自环**即一条连接一个顶点和其自身的边；**平行边**是连接同一对顶点的两条边。含有平行边的图称为多重图，没有平行边和自环的图称为**简单图**。

当两个顶点通过一条边相连时，这两个顶点是**相邻的**。某个顶点的**度数(Degree)**即为依附于它的边的总数。**子图**是由一幅图的所有边的一个子集（以及它们所依附的所有顶点）组成的图。

在图中，**路径**是由边顺序连接的一系列顶点。**简单路径**是一条没有重复顶点的路径。**环**是一条至少含有一条边，并且起点和终点相同的路径。**简单环**是一条（除了起点和终点必须相同之外）不含有重复顶点和边的环。路径或环的**长度**为其中所包含的边数。

如果从任意一个顶点都存在一条路径到达另一个任意顶点，这幅图就是**连通图**。一幅非连通的图由若干连通的部分组成，它们都是其极大连通子图。

树是一幅无环(Acyclic)连通图。互不相连的树组成的集合称为**森林**。连通图的**生成树**是它的一幅子图，它含有图中的所有顶点且是一棵树。图的**生成树森林**是它的所有连通子图的生成树的集合。

当且仅当一幅含有V个顶点的图G满足下列5个条件之一时，它就是一棵树：

* G有V-1条边且不含有环；
* G有V-1条边且是连通的；
* G是连通的，但删除任意一条边都会使它不再连通；
* G是无环图，但添加任意一条边都会产生一条环；
* G中的任意一对顶点之间仅存在一条简单路径。

## 2. API
先看一份定义了无向图的基本操作的API：

![image](/myresource/images/image_blog_2014-10-04_graph-api.png)

```java
//////////////////常用的图处理代码//////////////////

//计算v的度数
public static int degree(Graph G, int v) {
	int degree = 0;
	for(int w: G.adj(v)) degree++;
	return degree;
}

//计算所有顶点的最大度数
public static int maxDegree(Graph G) {
	int max = 0;
	for(int v = 0; v < G.V(); v++) 
		if (degree(G, v) > max)
			max = degree(G, v);
	return max;
}

//计算所有顶点的平均度数
public static double avgDegree(Graph G) {
	return 2.0 * G.E() / G.V(); 
}

//计算自环的个数
public static int numberOfSelfLoops(Graph G) {
	int count = 0;
	for(int v = 0; v < G.V(); v++)
		for(int w : G.adj(v))
			if (v == w) count++;
	return count / 2; //每条边都被记过2次
}
```

### 2.1 邻接表
图有多种表示方法，包括邻接矩阵（V乘V的布尔矩阵，占用空间过大），边的数组（边类含有两个int实例变量，实现adj方法需要检查图中的所有边）和邻接表数组。

邻接表数组是以顶点为索引的列表数组，例如第0个顶点的列表中每个元素都是和顶点0相邻的顶点。示意图如下：

![image](/myresource/images/image_blog_2014-10-03_adjacency-lists.png)

它具有以下特点：

* 使用的空间和V+E成正比；
* 添加一条边所需的时间为常数；
* 遍历顶点v的所有相邻顶点所需的时间和v的度数成正比。

代码实现示意如下：

```java
public class Graph {
	private final int V;        //顶点数目
	private int E;              //边的数目
	private Bag<Integer>[] adj; //邻接表
	
	public void addEdge(int v, int w) {
		adj[v].add(w);
		adj[w].add(v);
		E++;
	}
	
	public Iterable<Integer> adj(int v) {
		return adj[v];
	}
}
```

### 2.2 图的处理算法API

![image](/myresource/images/image_blog_2014-10-04_search-api.png)

## 3. 深度优先搜索(DFS)
深度优先搜索一幅图，只需要一个递归方法来遍历所有顶点。在访问其中一个顶点时：

* 将它标记为已访问；
* 递归地访问它的所有没有被标记过的邻居顶点。

```java
//深度优先搜索
public class DepthFirstSearch {
	private boolean[] marked;
	private int count;
	
	public DepthFirstSearch(Graph G, int s) {
		marked = new boolean[G.V()];
		dfs(G, s);
	}
	
	private void dfs(Graph G, int v) {
		marked[v] = true;
		count++;
		for(int w : G.adj(v))
			if (!marked[w]) dfs(G, w);
	}
	
	public boolean marked(int w) {return marked[w];}
	
	public int count() {return count;}
}
```

利用深度优先搜索很容易找到一些问题的答案。例如“两个给定的顶点是否连通？有多少个连通子图？从s到给定目的顶点v是否存在一条路径？如果有，找到这条路径。”

## 4. 寻找路径
路径的API:

![image](/myresource/images/image_blog_2014-10-04_paths-api.png)

```java
//使用深度优先搜索查找图的路径
public class DepthFirstPaths {
	private boolean[] marked;   //这个顶点上调用过dfs()吗？
	private int[] edgeTo;       //从起点到一个顶点的已知路径上的最后一个顶点
	private final int s;        //起点
	
	public DepthFirstPaths(Graph G, int s) {
		marked = new boolean[G.V()];
		edgeTo = new int[G.V()];
		this.s = s;
		dfs(G, s);
	}
	
	private void dfs(Graph G, int v) {
		marked[v] = true;
		for(int w : G.adj(v))
			if (!marked[w]) {
				edgeTo[w] = v;
				dfs(G, w);
			}
	}
	
	public boolean hasPathTo(int v) {return marked[v];}
	
	public Iterable<Integer> pathTo(int v) {
		if (!hasPathTo(v)) return null;
		Stack<Integer> path = new Stack<Integer>();
		for(int x = v; x != s; x = edgeTo[x])
			path.push(x);
		path.push(s);
		return path;
	}
}
```

## 5. 广度优先搜索(BFS)
广度优先搜索可以解决单点最短路径的问题，即“从s到给定目的顶点v是否存在一条路径？如果有，找出其中最短的那条。”要找到从s到v的最短路径，从s开始，在所有由一条边就可以到达的顶点中寻找v，如果找不到就继续在与s距离两条边的所有顶点中找v，如此一直进行。实现广度优先搜索时，可以使用先进先出（FIFO）队列。代码示意如下：

```java
public class BreadthFirstPaths {
	private boolean[] marked;  //到达该顶点的最短路径已知吗？
	private int[] edgeTo;      //到达该顶点的已知路径上的最后一个顶点
	private final int s;       //起点
	
	public BreadthFirstPaths(Graph G, int s) {
		marked = new boolean[G.V()];
		edgeTo = new int[G.v()];
		this.s = s;
		bfs(G, s);
	}
	
	private void bfs(Grapth G, int s) {
		Queue<Integer> queue = new Queue<Integer>();
		marked[s] = true;  //标记起点
		queue.enqueue(s);  //入列
		while (!queue.isEmpty()) {
			int v = queue.dequeue();
			for(int w : G.adj(v))
				if (!marked[w]) {
					edgeTo[w] = v;
					marked[w] = true;
					queue.enqueue(w);
				}
		}
	}
	
	public boolean hasPathTo(int v) {return marked[v];}
	
	public Iterable<Integer> pathTo(int v) {//与深度优先实现相同}
}
```
## 6. 连通分量
所谓连通分量就是连通子图，深度优先搜索可用于找出一幅图的所有连通分量。其API定义如下：

![image](/myresource/images/image_blog_2014-10-04_cc-api.png)

递归的深度优先搜索第一次调用的参数是顶点0，它会标记所有与0连通的顶点。然后构造函数中的for循环会查找每个没有被标记的顶点并递归调用dfs()来标记和它相邻的所有顶点。代码如下：

```java
public class CC {
	private boolean[] marked;
	private int[] id;
	private int count = 0;
	
	public CC(Graph G) {
		marked = new boolean[G.V()];
		id = new int[G.V()];
		for(int s = 0; s < G.V(); s++)
			if (!marked[s]) {
				dfs(G, s);
				count++;
			}
	}
	
	private void dfs(Graph G, int v) {
		marked[v] = true;
		id[v] = count;
		for(int w : G.adj(v))
			if (!marked[w])
				dfs(G, w);
	}
	
	public boolean connected(int v, int w) { return id[v] == id[w]; }
	
	public int id(int v) {return id[v]; }
	
	public int count() {return count;}
}
```

深度优先搜索还可用于解决两个问题：1. 给定的图是无环图吗（假定不存在自环和平行边）？[代码实现](http://algs4.cs.princeton.edu/41undirected/Cycle.java.html) 2. 这是一幅二分图吗？也就是说能够用两种颜色将图的所有顶点着色，使得任意一条边的两个端点的颜色都不相同。[二分图](http://baike.baidu.com/view/501081.htm)，[代码实现](http://algs4.cs.princeton.edu/41undirected/Bipartite.java.html)

## 7. 符号图
在典型应用中，通常使用字符串而非整数来表示和指代顶点。为了适应这样的应用，需要符号图。符号图使用字符串代替整数索引。其API定义如下：

![image](/myresource/images/image_blog_2014-10-04_symbol-graph-api.png)

符号图的实现可以在无向图的基础上增加一个符号表和反向索引。符号表完成符号到邻接表索引的映射，键为String(顶点名)，值的类型为int(邻接表的索引)。反向索引是一个数组keys[]，保存每个顶点索引所对应的顶点名。结构如下图：

![image](/myresource/images/image_blog_2014-10-04_symbol-graph.png)

其实现较为简单，[查看代码](http://algs4.cs.princeton.edu/41undirected/SymbolGraph.java.html)。

利用符号图可以处理一个经典问题，找到一个社交网络中两个人间隔的度数。这其实就是用符号图+广度优先求最短路径的用例。
