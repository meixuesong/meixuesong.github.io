---
layout: post
title: "最短路径"
date: 2014-11-03 20:22:31 +0800
comments: true
categories: 
- 算法
---
最短路径算法可以解决很多问题，例如地图导航、任务调度和网络路由等。本章的主题就是找到从一个顶点到达另一个顶点的成本最小的路径。

>在一幅加权有向图中，从顶点s到顶点t的最短路径是所有从s到t的路径中的权重最小者。

本章要涉及以下问题：

* 加权有向图的API、单点最短路径的API及它们的实现；
* 解决边的权重非负的最短路径问题的经典Dijkstra算法；
* 在无环加权有向图中解决该问题的一种快速算法，边的权重甚至可以是负值；
* 适用于一般情况的经典Bellman-Ford算法，其中图可以含有环，边的权重也可以是负值。

<!--more-->

## 1. 最短路径的性质

* 路径是有向的；
* 权重不一定等价于距离，但示例图会用距离代表权重；
* 并不是所有顶点都是可达的；
* 负权重会使问题更复杂，暂时假定边的权重是非负的；
* 算法会忽略构成环的零权重边，找到的最短路径都不会含有环；
* 最短路径不一定是唯一的，只找到其中一条即可；
* 可能存在平行边和自环，为避免歧义假设不存在平行边，但代码处理它们并没有困难。

单点最短路径的计算结果是一棵最短路径树（SPT），它包含了顶点s到达所有可达的顶点的最短路径。

>给定一幅加权有向图和一个顶点s，以s为起点的一棵最短路径树是图的一幅子图，它包含s和从s可达的所有顶点。这棵有向树的根结点是s，树的每条路径都是有向图中的一条最短路径。

## 2. 加权有向图的数据结构
有向边的数据结构比无向边更简单，因为有向边只有一个方向。其API定义如下：

![image](/myresource/images/image_blog_2014-11-04-directed-edge-api.png)

```java
public class DirectedEdge { 
    private final int v;				//边的起点
    private final int w;				//边的终点
    private final double weight;		//边的权重

    public DirectedEdge(int v, int w, double weight) {
        if (v < 0) throw new IndexOutOfBoundsException("Vertex names must be nonnegative integers");
        if (w < 0) throw new IndexOutOfBoundsException("Vertex names must be nonnegative integers");
        if (Double.isNaN(weight)) throw new IllegalArgumentException("Weight is NaN");
        this.v = v;
        this.w = w;
        this.weight = weight;
    }

    public int from() {return v;}
    public int to() {return w;}
    public double weight() {return weight;}

    public String toString() {
        return v + "->" + w + " " + String.format("%5.2f", weight);
    }
}
```

加权有向图的API也与无向图类似：

![image](/myresource/images/image_blog_2014-11-04-edge-weighted-digraph-api.png)

```java
public class EdgeWeightedDigraph {
    private final int V;					//顶点总数
    private int E;							//边的总数
    private Bag<DirectedEdge>[] adj;		//邻接表
    
    public EdgeWeightedDigraph(int V) {
        if (V < 0) throw new IllegalArgumentException("Number of vertices in a Digraph must be nonnegative");
        this.V = V;
        this.E = 0;
        adj = (Bag<DirectedEdge>[]) new Bag[V];
        for (int v = 0; v < V; v++)
            adj[v] = new Bag<DirectedEdge>();
    }

    public int V() {return V;}
    public int E() {return E;}

    //将e添加到有向图中
    public void addEdge(DirectedEdge e) {
        adj[e.from()].add(e);
        E++;
    }

    //从v指出的边
    public Iterable<DirectedEdge> adj(int v) {
        return adj[v];
    }

    //有向图中的所有边
    public Iterable<DirectedEdge> edges() {
        Bag<DirectedEdge> list = new Bag<DirectedEdge>();
        for (int v = 0; v < V; v++) {
            for (DirectedEdge e : adj(v)) {
                list.add(e);
            }
        }
        return list;
    } 
}
```

加权有向图的表示：

![image](/myresource/images/image_blog_2014-11-04-edge-weighted-digraph-representation.png)

### 2.1 最短路径
最短路径的API：

![image](/myresource/images/image_blog_2014-11-04-sp-api.png)

在实现时，分别用两个数组来表示最短路径：

* 最短路径树中的边：DirectedEdge[] edgeTo，edgeTo[v]的值为树中连接v和它的父结点的边。
* 到达起点的距离：Double[] distTo，distTo[v]为从起点s到v的已知最短路径的长度。

同时约定edgeTo[s] == null, distTo[s] == 0; 不可达的顶点的距离为Double.POSITIVE_INFINITY。

### 2.2 松弛操作
松弛（Relaxation）操作是最短路径实现中使用的关键操作。对边v->w松弛意味着检查从s到w的最短路径是否是先从s到v，然后再由v到w。如果是，则由v到达w的最短路径是distTo[v] + e.weight()。如果这个值不小于distTo[w]，则证明刚才的边失效可忽略，否则证明现在的值更小，需要更新数据。

下图演示了这种情况，左侧的v->w不满足条件，被忽略。而右侧的图v->满足条件，替换为新的最短路径。

![image](/myresource/images/image_blog_2014-11-04-relaxation-edge.png)

对顶点的松弛操作就是对该顶点指出的所有边进行松弛操作。每次顶点的松弛操作都能得出到达某个顶点的更短的路径。算法就这样最终找出到达每个顶点的最短路径。

## 3. 最短路径算法的理论基础
最短路径的最优性条件：

>令G为一幅加权有向图，顶点s是G中的起点，distTo[]是一个由顶点索引的数组，保存的是G中路径的长度。对于从s可达的所有顶点v，distTo[v]的值是从s到v的某条路径的长度，对于从s不可达的所有顶点v，该值为无穷大。当且仅当对于从v到w的任意一条边e, 这些值都满足distTo[w] <= distTo[v] + e.weight()时，它们是最短路径的长度。

根据最优性条件，我们可以得到一个通用算法，暂时只考虑非负权重的情况：

>将distTo[s]初始化为0，其它distTo[]元素初始化为无穷大，继续如下操作：放松G中的任意边，直到不存在有效边为止。对于任意从s可达的顶点w，进行这些操作后，distTo[w]的值即为从s到w的最短路径的长度。

## 4. Dijkstra算法
Dijkstra算法能够解决边权重非负的加权有向图的单起点最短路径问题。它与无向图的最小生成树的Prim算法（每一步都向最小生成树中添加一条新的边）非常相似。首先将distTo[s]初始华为0，distTo[]的其他元素初始化为正无穷。然后**将distTo[]最小的非树顶点放松并加入树中，如此这般，直到所有的顶点都在树中或者所有的非树顶点的distTo[]值均为无穷大。**

Dijkstra算法实现时，除了要distTo[]和edgeTo[]之外，还需要一条索引优先队列pa，以保存需要被放松的顶点并确认下一个被放松的顶点。只要将v和distTo[v]关联起来放入队列就可以立即实现Dijkstra算法。Prim算法每次添加的都是离树最近的非树顶点，而Dijkstra算法每次添加的都是离起点最近的非树顶点。如果将加权无向图看成加权有向图，对无向图中的每条边都相应地创建方向相反的有向边，最短路径的问题是等价的。Dijkstra算法实现实现如下：

```
public class DijkstraSP {
    private double[] distTo;          // distTo[v] = distance  of shortest s->v path
    private DirectedEdge[] edgeTo;    // edgeTo[v] = last edge on shortest s->v path
    private IndexMinPQ<Double> pq;    // priority queue of vertices

    /**
     * Computes a shortest paths tree from <tt>s</tt> to every other vertex in
     * the edge-weighted digraph <tt>G</tt>.
     * @param G the edge-weighted digraph
     * @param s the source vertex
     * @throws IllegalArgumentException if an edge weight is negative
     * @throws IllegalArgumentException unless 0 &le; <tt>s</tt> &le; <tt>V</tt> - 1
     */
    public DijkstraSP(EdgeWeightedDigraph G, int s) {
        for (DirectedEdge e : G.edges()) {
            if (e.weight() < 0)
                throw new IllegalArgumentException("edge " + e + " has negative weight");
        }

        distTo = new double[G.V()];
        edgeTo = new DirectedEdge[G.V()];
        for (int v = 0; v < G.V(); v++)
            distTo[v] = Double.POSITIVE_INFINITY;
        distTo[s] = 0.0;

        // relax vertices in order of distance from s
        pq = new IndexMinPQ<Double>(G.V());
        pq.insert(s, distTo[s]);
        while (!pq.isEmpty()) {
            int v = pq.delMin();
            for (DirectedEdge e : G.adj(v))
                relax(e);
        }
    }

    // relax edge e and update pq if changed
    private void relax(DirectedEdge e) {
        int v = e.from(), w = e.to();
        if (distTo[w] > distTo[v] + e.weight()) {
            distTo[w] = distTo[v] + e.weight();
            edgeTo[w] = e;
            if (pq.contains(w)) pq.decreaseKey(w, distTo[w]);
            else                pq.insert(w, distTo[w]);
        }
    }

    /**
     * Returns the length of a shortest path from the source vertex <tt>s</tt> to vertex <tt>v</tt>.
     * @param v the destination vertex
     * @return the length of a shortest path from the source vertex <tt>s</tt> to vertex <tt>v</tt>;
     *    <tt>Double.POSITIVE_INFINITY</tt> if no such path
     */
    public double distTo(int v) {
        return distTo[v];
    }

    /**
     * Is there a path from the source vertex <tt>s</tt> to vertex <tt>v</tt>?
     * @param v the destination vertex
     * @return <tt>true</tt> if there is a path from the source vertex
     *    <tt>s</tt> to vertex <tt>v</tt>, and <tt>false</tt> otherwise
     */
    public boolean hasPathTo(int v) {
        return distTo[v] < Double.POSITIVE_INFINITY;
    }

    /**
     * Returns a shortest path from the source vertex <tt>s</tt> to vertex <tt>v</tt>.
     * @param v the destination vertex
     * @return a shortest path from the source vertex <tt>s</tt> to vertex <tt>v</tt>
     *    as an iterable of edges, and <tt>null</tt> if no such path
     */
    public Iterable<DirectedEdge> pathTo(int v) {
        if (!hasPathTo(v)) return null;
        Stack<DirectedEdge> path = new Stack<DirectedEdge>();
        for (DirectedEdge e = edgeTo[v]; e != null; e = edgeTo[e.from()]) {
            path.push(e);
        }
        return path;
    }
}
```

要解决**加权有向图中给定两点（从s到t）的最短路径**这个问题，只要使用Dijkstra算法并从优先队列中取到t之后终止搜索。

## 5. 无环加权有向图中的最短路径算法
如果加权有向图是不含有有向环的，那么可以采用一种比Dijkstra更快、更简单的最短路径算法。它能够在线性时间内解决单点最短路径问题，能够处理负权重的边，还能解决一些其它问题，如找出最长的路径。

根据在[有向图](/blog/2014/10/30/you-xiang-tu/)中学习的拓扑顺序知识，我们知道一幅有向无环图的拓扑顺序就是所有顶点的逆后序排列。如果我们按照拓扑顺序放松顶点，就能在E+V成正比的时间内解决无环加权有向图的单点最短路径问题。代码实现如下：

```
public class AcyclicSP {
    private double[] distTo;         // distTo[v] = distance  of shortest s->v path
    private DirectedEdge[] edgeTo;   // edgeTo[v] = last edge on shortest s->v path


    /**
     * Computes a shortest paths tree from <tt>s</tt> to every other vertex in
     * the directed acyclic graph <tt>G</tt>.
     * @param G the acyclic digraph
     * @param s the source vertex
     * @throws IllegalArgumentException if the digraph is not acyclic
     * @throws IllegalArgumentException unless 0 &le; <tt>s</tt> &le; <tt>V</tt> - 1
     */
    public AcyclicSP(EdgeWeightedDigraph G, int s) {
        distTo = new double[G.V()];
        edgeTo = new DirectedEdge[G.V()];
        for (int v = 0; v < G.V(); v++)
            distTo[v] = Double.POSITIVE_INFINITY;
        distTo[s] = 0.0;

        // visit vertices in toplogical order
        Topological topological = new Topological(G);
        if (!topological.hasOrder())
            throw new IllegalArgumentException("Digraph is not acyclic.");
        for (int v : topological.order()) {
            for (DirectedEdge e : G.adj(v))
                relax(e);
        }
    }

    // relax edge e
    private void relax(DirectedEdge e) {
        int v = e.from(), w = e.to();
        if (distTo[w] > distTo[v] + e.weight()) {
            distTo[w] = distTo[v] + e.weight();
            edgeTo[w] = e;
        }       
    }

    /**
     * Returns the length of a shortest path from the source vertex <tt>s</tt> to vertex <tt>v</tt>.
     * @param v the destination vertex
     * @return the length of a shortest path from the source vertex <tt>s</tt> to vertex <tt>v</tt>;
     *    <tt>Double.POSITIVE_INFINITY</tt> if no such path
     */
    public double distTo(int v) {
        return distTo[v];
    }

    /**
     * Is there a path from the source vertex <tt>s</tt> to vertex <tt>v</tt>?
     * @param v the destination vertex
     * @return <tt>true</tt> if there is a path from the source vertex
     *    <tt>s</tt> to vertex <tt>v</tt>, and <tt>false</tt> otherwise
     */
    public boolean hasPathTo(int v) {
        return distTo[v] < Double.POSITIVE_INFINITY;
    }

    /**
     * Returns a shortest path from the source vertex <tt>s</tt> to vertex <tt>v</tt>.
     * @param v the destination vertex
     * @return a shortest path from the source vertex <tt>s</tt> to vertex <tt>v</tt>
     *    as an iterable of edges, and <tt>null</tt> if no such path
     */
    public Iterable<DirectedEdge> pathTo(int v) {
        if (!hasPathTo(v)) return null;
        Stack<DirectedEdge> path = new Stack<DirectedEdge>();
        for (DirectedEdge e = edgeTo[v]; e != null; e = edgeTo[e.from()]) {
            path.push(e);
        }
        return path;
    }
}
```

上面这个算法的效率几乎已经没有提高的空间。**在已知加权图是无环的情况下，它是找出最短路径的最好方法。**而且它与边的权重是否非负无关，因此无环加权有向图不会受到任何限制。

### 5.1 最长路径
**无环加权有向图中的单点最长路径。**给定一幅无环加权有向图（边的权重可能为负）和一个起点s，回答“是否存在一条从s到达给定的顶点v的路径？如果有，找出最长（总权重最大）的那条路径。”

最短路径的算法可以稍加改动就可以用于最长路径的计算。

* 方法一：将无环加权有向图复制一份，将副本的所有边的权重取反数。这样副本中的最短路径即为原图中的最长路径。
* 方法二：改变AcyclicLP类中relax()方法中的不等式方向。这种方法更加简单。

最长路径有什么意义？例如并行任务调度中的关键路径问题。关键路径是最长的任务序列，是任务调度中的关键手段。如何利用无环加权有向图计算关键路径？

>解决并行任务调度问题的关键路径方法的步骤如下：创建一幅无环加权有向图，其中包含一个起点s和一个终点t且每个任务都对应两个顶点（一个起点和一个结点顶点）。对于每个任务都有一条从它的起始顶点指向结束顶点的边，边的权重为任务所需的时间。对于每条优先级限制v->w，添加一条从v的结束顶点指向w的起始顶点的权重为零的边。为每个任务添加一条从起点指向该任务的起始顶点的权重为零的边以及一条从该任务的结束顶点到终点的权重为零的边。这样，每个任务预计的开始时间即为从起点到它的起始顶点的最长距离。

下图展示了一个任务调度的无环加权有向图表示。共有0-9个任务，红线表示任务依赖关系（如任务1、7和9依赖于任务0）其权重为0，图形表示如下：

![image](/myresource/images/image_blog_2014-11-05-scheduling-reduction.png)

通过计算最长路径，得到任务的关键路径：

![image](/myresource/images/image_blog_2014-11-05-scheduling-critical-path.png)

最后期限是任务调度中常见的问题，即某个任务必须在指定的时间点之前开始，这种类型的问题如何解决？相对最后期限限制下的并行任务调度问题是一个加权有向图中的最短路径问题（可能存在环和负权重边）。这时可以为每条最后期限限制添加一条边：如果任务v必须在任务w启动后的d个时间单位内开始，则添加一条从v指向w的负权重为d的边。将所有边的权重取反即可将该问题转化为一个最短路径问题。

因此，负权重的边具有实际作用，但前面的算法Dijkstra只适用于非负权重的边，AcyclicSP要求有向图是无环的。它们都无法完成任务，因此需要一种更通用的方法。

## 6. 一般加权有向图中的最短路径问题
所谓一般加权有向图的最短路径问题，就是能够处理有环、负权重边的加权有向图最短路径问题。一幅加权有向图中包含环并不可怕，可怕的是这个环的总权重为负，这时候最短路径就会失去意义。因为无论何时绕这个环一圈都能得到权重更小的路径。**负权重环**就是这样一个总权重（环上的所有边的权重之和）为负的有向环。

>当且仅当加权有向图中至少存在一条从s到v的有向路径且所有从s到v的有向路径上的任意顶点都不存在于任何负权重环中时，s到v的最短路径才是存在的。

Bellman-Ford算法，在任意含有V个顶点的加权有向图中给定起点s，从s无法到达任何负权重环，以下算法能够解决其中的单点最短路径问题：将distTo[s]初始化为0，其他distTo[]元素初始化为无穷大。以任意顺序放松有向图的所有边，重复V轮。

Bellman-Ford算法所需的时间和EV成正比，空间和V成正比。因为每一轮算法都会放松E条边，共重复了V轮。把这个算法稍加改进可以提高效率。每一轮放松所有边的过程中，许多边的放松都不会成功。只有上一轮中的distTo[]值发生变化的顶点指出的边才能够改变其他distTo[]元素的值。因此可以用FIFO队列记录这样的顶点，不需要放松所有边。代码实现如下（先忽略负权重环的代码）：

```
public class BellmanFordSP {
    private double[] distTo;               // distTo[v] = 从起点到某个顶点的路径长度
    private DirectedEdge[] edgeTo;         // edgeTo[v] = 从起点到某个顶点的最后一条边
    private boolean[] onQueue;             // onQueue[v] = 该顶点是否存在于队列中
    private Queue<Integer> queue;          // 正在被放松的顶点
    private int cost;                      // relax()的调用次数
    private Iterable<DirectedEdge> cycle;  // edgeTo[]是否有负权重环

    /**
     * Computes a shortest paths tree from <tt>s</tt> to every other vertex in
     * the edge-weighted digraph <tt>G</tt>.
     * @param G the acyclic digraph
     * @param s the source vertex
     * @throws IllegalArgumentException unless 0 &le; <tt>s</tt> &le; <tt>V</tt> - 1
     */
    public BellmanFordSP(EdgeWeightedDigraph G, int s) {
        distTo  = new double[G.V()];
        edgeTo  = new DirectedEdge[G.V()];
        onQueue = new boolean[G.V()];
        for (int v = 0; v < G.V(); v++)
            distTo[v] = Double.POSITIVE_INFINITY;
        distTo[s] = 0.0;

        // Bellman-Ford algorithm
        queue = new Queue<Integer>();
        queue.enqueue(s);
        onQueue[s] = true;
        while (!queue.isEmpty() && !hasNegativeCycle()) {
            int v = queue.dequeue();
            onQueue[v] = false;
            relax(G, v);
        }
    }

    // relax vertex v and put other endpoints on queue if changed
    private void relax(EdgeWeightedDigraph G, int v) {
        for (DirectedEdge e : G.adj(v)) {
            int w = e.to();
            if (distTo[w] > distTo[v] + e.weight()) {
                //成功放松的边指向的所有顶点加入到FIFO队列
                distTo[w] = distTo[v] + e.weight();
                edgeTo[w] = e;
                if (!onQueue[w]) {
                    queue.enqueue(w);
                    onQueue[w] = true;
                }
            }
            //周期性地检查是否有负权重环，避免无限循环
            if (cost++ % G.V() == 0) 
                findNegativeCycle();
        }
    }

    /**
     * Is there a negative cycle reachable from the source vertex <tt>s</tt>?
     * @return <tt>true</tt> if there is a negative cycle reachable from the
     *    source vertex <tt>s</tt>, and <tt>false</tt> otherwise
     */
    public boolean hasNegativeCycle() {
        return cycle != null;
    }

    /**
     * Returns a negative cycle reachable from the source vertex <tt>s</tt>, or <tt>null</tt>
     * if there is no such cycle.
     * @return a negative cycle reachable from the soruce vertex <tt>s</tt> 
     *    as an iterable of edges, and <tt>null</tt> if there is no such cycle
     */
    public Iterable<DirectedEdge> negativeCycle() {
        return cycle;
    }

    // by finding a cycle in predecessor graph
    private void findNegativeCycle() {
        int V = edgeTo.length;
        EdgeWeightedDigraph spt = new EdgeWeightedDigraph(V);
        for (int v = 0; v < V; v++)
            if (edgeTo[v] != null)
                spt.addEdge(edgeTo[v]);

        EdgeWeightedDirectedCycle finder = new EdgeWeightedDirectedCycle(spt);
        cycle = finder.cycle();
    }

    /**
     * Returns the length of a shortest path from the source vertex <tt>s</tt> to vertex <tt>v</tt>.
     * @param v the destination vertex
     * @return the length of a shortest path from the source vertex <tt>s</tt> to vertex <tt>v</tt>;
     *    <tt>Double.POSITIVE_INFINITY</tt> if no such path
     * @throws UnsupportedOperationException if there is a negative cost cycle reachable
     *    from the source vertex <tt>s</tt>
     */
    public double distTo(int v) {
        if (hasNegativeCycle())
            throw new UnsupportedOperationException("Negative cost cycle exists");
        return distTo[v];
    }

    /**
     * Is there a path from the source <tt>s</tt> to vertex <tt>v</tt>?
     * @param v the destination vertex
     * @return <tt>true</tt> if there is a path from the source vertex
     *    <tt>s</tt> to vertex <tt>v</tt>, and <tt>false</tt> otherwise
     */
    public boolean hasPathTo(int v) {
        return distTo[v] < Double.POSITIVE_INFINITY;
    }

    /**
     * Returns a shortest path from the source <tt>s</tt> to vertex <tt>v</tt>.
     * @param v the destination vertex
     * @return a shortest path from the source <tt>s</tt> to vertex <tt>v</tt>
     *    as an iterable of edges, and <tt>null</tt> if no such path
     * @throws UnsupportedOperationException if there is a negative cost cycle reachable
     *    from the source vertex <tt>s</tt>
     */
    public Iterable<DirectedEdge> pathTo(int v) {
        if (hasNegativeCycle())
            throw new UnsupportedOperationException("Negative cost cycle exists");
        if (!hasPathTo(v)) return null;
        Stack<DirectedEdge> path = new Stack<DirectedEdge>();
        for (DirectedEdge e = edgeTo[v]; e != null; e = edgeTo[e.from()]) {
            path.push(e);
        }
        return path;
    }
}
```

### 6.1 负权重环的检测
BellmanFordSP的实现会检测负权重环来避免陷入无限循环。当BellmanFordSP构造函数运行之后，将所有边放松V轮之后当且仅当队列非空时有向图中才存在从起点可达的负权重环。如果是这样，edgeTo[]数组中所表示的子图必然含有这个负权重环。因此nagativeCycle()的实现中，会根据edgeTo[]中的边构造一幅加权有向图并在该图中检测环。我们修改DirectedCycle类来在加权有向图中寻找环：

```
public class EdgeWeightedDirectedCycle {
    private boolean[] marked;             // marked[v] = has vertex v been marked?
    private DirectedEdge[] edgeTo;        // edgeTo[v] = previous edge on path to v
    private boolean[] onStack;            // onStack[v] = is vertex on the stack?
    private Stack<DirectedEdge> cycle;    // directed cycle (or null if no such cycle)

    /**
     * Determines whether the edge-weighted digraph <tt>G</tt> has a directed cycle and,
     * if so, finds such a cycle.
     * @param G the edge-weighted digraph
     */
    public EdgeWeightedDirectedCycle(EdgeWeightedDigraph G) {
        marked  = new boolean[G.V()];
        onStack = new boolean[G.V()];
        edgeTo  = new DirectedEdge[G.V()];
        for (int v = 0; v < G.V(); v++)
            if (!marked[v]) dfs(G, v);
    }

    // check that algorithm computes either the topological order or finds a directed cycle
    private void dfs(EdgeWeightedDigraph G, int v) {
        onStack[v] = true;
        marked[v] = true;
        for (DirectedEdge e : G.adj(v)) {
            int w = e.to();

            // short circuit if directed cycle found
            if (cycle != null) return;

            //found new vertex, so recur
            else if (!marked[w]) {
                edgeTo[w] = e;
                dfs(G, w);
            }

            // trace back directed cycle
            else if (onStack[w]) {
                cycle = new Stack<DirectedEdge>();
                while (e.from() != w) {
                    cycle.push(e);
                    e = edgeTo[e.from()];
                }
                cycle.push(e);
            }
        }

        onStack[v] = false;
    }

    /**
     * Does the edge-weighted digraph have a directed cycle?
     * @return <tt>true</tt> if the edge-weighted digraph has a directed cycle,
     * <tt>false</tt> otherwise
     */
    public boolean hasCycle() {
        return cycle != null;
    }

    /**
     * Returns a directed cycle if the edge-weighted digraph has a directed cycle,
     * and <tt>null</tt> otherwise.
     * @return a directed cycle (as an iterable) if the edge-weighted digraph
     *    has a directed cycle, and <tt>null</tt> otherwise
     */
    public Iterable<DirectedEdge> cycle() {
        return cycle;
    }
}
```

### 6.2 套汇
前面的问题都是权重之和，而套汇问题演示了另一种方式。套汇是通过不同货币间进行兑换赚取利润。这也是一个加权有向图的应用。顶点是货币，s->t表示货币s到t的汇率。如何交易使得利润最大，就是找到各权重之**积**最大者。但我们之前所学的都是权重之和，那么如何解决这个问题呢？

套汇问题等价于加权有向图中的负权重环的检测问题：
>取每条边权重的自然对数并取反，这样在原始问题中所有边的权重之积的计算就转化为新图中所有边的权重之和的计算。任意权重之积 w<sub>1</sub>w<sub>2</sub>...w<sub>k</sub>即对应-ln(w<sub>1</sub>)-ln(w<sub>2</sub>)-...-ln(w<sub>k</sub>)之和。转换后边的权重可能为正也可能为负。一条从v到w的路径表示将货币v兑换为货币w，任意负权重环都是一次套汇的好机会。

## 7. 总结
最短路径算法的性能特点如下表：

算法|局限|一般情况|最坏情况|所需空间| 优势
---|---|---|---|---|---
Dijkstra算法（即时版本） | 边的权重必须为正 | ElogV | ElogV | V | 最坏情况下仍有较好的性能
拓扑排序| 只适用于无环加权有向图| E + V | E + V | V | 是无环图中的最优算法
Bellman-Ford算法（基于队列）|不能存在负权重环| E+V | EV | V| 适用领域广泛



参考：[http://algs4.cs.princeton.edu/44sp/](http://algs4.cs.princeton.edu/44sp/)
