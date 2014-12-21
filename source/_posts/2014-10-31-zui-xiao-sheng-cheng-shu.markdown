---
layout: post
title: "最小生成树"
date: 2014-10-31 22:38:49 +0800
comments: true
categories: 
- 算法
---
加权图是一种为每条边关联一个权值或成本的图模型。这种图最令人感兴趣的是将成本最小化。本节学习加权无向图模型并找到它的一棵最小生成树。

图的生成树是它的一棵含有其所有顶点的无环连通子图。一幅加权图的最小生成树（MST）是它的一棵权值（树中所有边的权值之和）最小的生成树。

<!--more-->

## 1. 一些约定
为了方便说明，有以下这些约定：

* 只考虑连通图。如果图是非连通的，只能计算它的所有连通分量的最小生成树，合并起来称为最小生成森林。
* 边的权重不一定表示距离。但为了看起来方便，示意图会用距离来表示权重。
* 边的权重可能是0或者负数。
* 所有边的权重都各不相同。如果权重可以相同，最小生成树就不一定唯一，算法证明会更复杂。但实际上算法也适用于存在权重相等的情况。

## 2. 原理
图的一种**切分**是将图的所有顶点分为两个非空且不重叠的两个集合。**横切边**是一条连接两个属于不同集合的顶点的边。

>切分定理：在一幅加权图中，给定任意的切分，它的横切边中的权重最小者必然属于图的最小生成树。

切分定理会把加权图中的所有顶点分为两个集合，检查横跨两个集合的所有边并识别哪边边应属于图的最小生成树。

## 3. 加权无向图的数据结构
通过扩展无向图的邻接矩阵来表示加权无向图。在无向图的邻接表表示中，第v个顶点的列表中每个元素都是和顶点v相邻的顶点。在加权无向图中，我们将其替换为一个加权边Edge：

![image](/myresource/images/image_blog_2014-11-02-edge-api.png)

上图中，eaither()表示边的两个顶点中的某一个，而other()则返回另一个顶点。有了加权边Edge，加权无向图的API就与无向图非常接近，在实现上，只是在邻接表中用Edge对象替代了无向图Graph中的整数作为链表的结点：

![image](/myresource/images/image_blog_2014-11-02-edge-weighted-graph-api.png)

加权无向图的表示如下：

![image](/myresource/images/image_blog_2014-11-02-edge-weighted-graph-representation.png)

代码实现如下：

```java
public class Edge implements Comparable<Edge> { 
    private final int v;
    private final int w;
    private final double weight;

    public Edge(int v, int w, double weight) {
        if (v < 0) throw new IndexOutOfBoundsException("Vertex name must be a nonnegative integer");
        if (w < 0) throw new IndexOutOfBoundsException("Vertex name must be a nonnegative integer");
        if (Double.isNaN(weight)) throw new IllegalArgumentException("Weight is NaN");
        this.v = v;
        this.w = w;
        this.weight = weight;
    }

    public double weight() {
        return weight;
    }

    public int either() {
        return v;
    }

    public int other(int vertex) {
        if      (vertex == v) return w;
        else if (vertex == w) return v;
        else throw new IllegalArgumentException("Illegal endpoint");
    }

    public int compareTo(Edge that) {
        if      (this.weight() < that.weight()) return -1;
        else if (this.weight() > that.weight()) return +1;
        else                                    return  0;
    }

    public String toString() {
        return String.format("%d-%d %.5f", v, w, weight);
    }
}    
```

```java
public class EdgeWeightedGraph {
    private final int V;
    private int E;
    private Bag<Edge>[] adj;
    
    /**
     * Initializes an empty edge-weighted graph with <tt>V</tt> vertices and 0 edges.
     * param V the number of vertices
     * @throws java.lang.IllegalArgumentException if <tt>V</tt> < 0
     */
    public EdgeWeightedGraph(int V) {
        if (V < 0) throw new IllegalArgumentException("Number of vertices must be nonnegative");
        this.V = V;
        this.E = 0;
        adj = (Bag<Edge>[]) new Bag[V];
        for (int v = 0; v < V; v++) {
            adj[v] = new Bag<Edge>();
        }
    }

    /**
     * Initializes a random edge-weighted graph with <tt>V</tt> vertices and <em>E</em> edges.
     * param V the number of vertices
     * param E the number of edges
     * @throws java.lang.IllegalArgumentException if <tt>V</tt> < 0
     * @throws java.lang.IllegalArgumentException if <tt>E</tt> < 0
     */
    public EdgeWeightedGraph(int V, int E) {
        this(V);
        if (E < 0) throw new IllegalArgumentException("Number of edges must be nonnegative");
        for (int i = 0; i < E; i++) {
            int v = (int) (Math.random() * V);
            int w = (int) (Math.random() * V);
            double weight = Math.round(100 * Math.random()) / 100.0;
            Edge e = new Edge(v, w, weight);
            addEdge(e);
        }
    }

    /**  
     * Initializes an edge-weighted graph from an input stream.
     * The format is the number of vertices <em>V</em>,
     * followed by the number of edges <em>E</em>,
     * followed by <em>E</em> pairs of vertices and edge weights,
     * with each entry separated by whitespace.
     * @param in the input stream
     * @throws java.lang.IndexOutOfBoundsException if the endpoints of any edge are not in prescribed range
     * @throws java.lang.IllegalArgumentException if the number of vertices or edges is negative
     */
    public EdgeWeightedGraph(In in) {
        this(in.readInt());
        int E = in.readInt();
        if (E < 0) throw new IllegalArgumentException("Number of edges must be nonnegative");
        for (int i = 0; i < E; i++) {
            int v = in.readInt();
            int w = in.readInt();
            double weight = in.readDouble();
            Edge e = new Edge(v, w, weight);
            addEdge(e);
        }
    }

    /**
     * Initializes a new edge-weighted graph that is a deep copy of <tt>G</tt>.
     * @param G the edge-weighted graph to copy
     */
    public EdgeWeightedGraph(EdgeWeightedGraph G) {
        this(G.V());
        this.E = G.E();
        for (int v = 0; v < G.V(); v++) {
            // reverse so that adjacency list is in same order as original
            Stack<Edge> reverse = new Stack<Edge>();
            for (Edge e : G.adj[v]) {
                reverse.push(e);
            }
            for (Edge e : reverse) {
                adj[v].add(e);
            }
        }
    }

    //图的顶点数
    public int V() {
        return V;
    }

    //图的边数
    public int E() {
        return E;
    }

    //向图中添加一条边e
    public void addEdge(Edge e) {
        int v = e.either();
        int w = e.other(v);
        if (v < 0 || v >= V) throw new IndexOutOfBoundsException("vertex " + v + " is not between 0 and " + (V-1));
        if (w < 0 || w >= V) throw new IndexOutOfBoundsException("vertex " + w + " is not between 0 and " + (V-1));
        adj[v].add(e);
        adj[w].add(e);
        E++;
    }

    //与v相关联的所有边
    public Iterable<Edge> adj(int v) {
        if (v < 0 || v >= V) throw new IndexOutOfBoundsException("vertex " + v + " is not between 0 and " + (V-1));
        return adj[v];
    }

    //图中的所有边
    public Iterable<Edge> edges() {
        Bag<Edge> list = new Bag<Edge>();
        for (int v = 0; v < V; v++) {
            int selfLoops = 0;
            for (Edge e : adj(v)) {
                if (e.other(v) > v) {
                    list.add(e);
                }
                // only add one copy of each self loop (self loops will be consecutive)
                else if (e.other(v) == v) {
                    if (selfLoops % 2 == 0) list.add(e);
                    selfLoops++;
                }
            }
        }
        return list;
    }

    public String toString() {
        String NEWLINE = System.getProperty("line.separator");
        StringBuilder s = new StringBuilder();
        s.append(V + " " + E + NEWLINE);
        for (int v = 0; v < V; v++) {
            s.append(v + ": ");
            for (Edge e : adj[v]) {
                s.append(e + "  ");
            }
            s.append(NEWLINE);
        }
        return s.toString();
    }
}
```

## 4. 最小生成树的API及实现
下面API定义的构造函数接受加权无向图作为参数，并返回最小生成树和其权重。

![image](/myresource/images/image_blog_2014-11-02-mst-api.png)

Prim算法和Kruskal算法都可以实现最小生成树，它们都基于贪心算法，区别在于保存切分和判定权重最小的横切边的方式。

>贪心算法：初始状态下所有边均为灰色，找到一种切分，它产生的横切边均不为黑色。将权重最小的横切边标记为黑色。反复这个步骤直到标记了V-1条黑色边为止。

### 4.1 Prim算法
Prim算法每一步都会为一棵生长中的树添加一条边。一开始这棵树只有一个顶点，然后会向它添加V-1条边，每次总是找到这样一条边并将其加入树中：这条边的一端在树中，另一端不在树中，并且权值最小。

![image](/myresource/images/image_blog_2014-11-02-prim-eager.jpg)

每当向树中添加一条边后，也向树中添加了一个顶点。要维护一个包含所有横切边的集合，可以将连接这个顶点和其他所有不在树中的顶点的边加入优先队列。这样就可以得到符合条件的权值最小的边。当一个顶点加入树中后，连接这个顶点与树中其它顶点的所有边就失效了，因为这些边的两个顶点都已经在树中，这些边不再是横切边。那么何时删除这些边就形成了Prim算法的两种实现：

* 延时(Lazy)实现会先把它们留在队列中，等要删除时再检查边的有效性；
* 即时实现可以将它们从优先队列中删除。

这两种实现所需的时间都与ElogE成正比（最坏情况下），延时实现所需的空间与E成正比，瓶颈在于优先队列的insert()和delMin()中比较边的权重次数。而即时实现所需空间的上限与V成正比，比延时实现有优势。两种实现代码如下：

```java
public class LazyPrimMST {
    private double weight;       // total weight of MST
    private Queue<Edge> mst;     // edges in the MST
    private boolean[] marked;    // marked[v] = true if v on tree
    private MinPQ<Edge> pq;      // edges with one endpoint in tree

    /**
     * Compute a minimum spanning tree (or forest) of an edge-weighted graph.
     * @param G the edge-weighted graph
     */
    public LazyPrimMST(EdgeWeightedGraph G) {
        mst = new Queue<Edge>();
        pq = new MinPQ<Edge>();
        marked = new boolean[G.V()];
        for (int v = 0; v < G.V(); v++)     // run Prim from all vertices to
            if (!marked[v]) prim(G, v);     // get a minimum spanning forest
    }

    // run Prim's algorithm
    private void prim(EdgeWeightedGraph G, int s) {
        scan(G, s);
        while (!pq.isEmpty()) {                        // better to stop when mst has V-1 edges
            Edge e = pq.delMin();                      // smallest edge on pq
            int v = e.either(), w = e.other(v);        // two endpoints
            assert marked[v] || marked[w];
            if (marked[v] && marked[w]) continue;      // lazy, both v and w already scanned
            mst.enqueue(e);                            // add e to MST
            weight += e.weight();
            if (!marked[v]) scan(G, v);               // v becomes part of tree
            if (!marked[w]) scan(G, w);               // w becomes part of tree
        }
    }

    //标记顶点v并将所有连接v和未被标记顶点的边加入pq
    private void scan(EdgeWeightedGraph G, int v) {
        assert !marked[v];
        marked[v] = true;
        for (Edge e : G.adj(v))
            if (!marked[e.other(v)]) pq.insert(e);
    }
        
    //树的所有边
    public Iterable<Edge> edges() {
        return mst;
    }

    //树的权重
    public double weight() {
        return weight;
    }
}
```

```java
public class PrimMST {
    private Edge[] edgeTo;        // 距离树最近的边，edgeTo[v] = shortest edge from tree vertex to non-tree vertex
    private double[] distTo;      // distTo[v] = weight of shortest such edge
    private boolean[] marked;     // marked[v] = true if v on tree, false otherwise
    private IndexMinPQ<Double> pq;  //有效的横切边

    /**
     * Compute a minimum spanning tree (or forest) of an edge-weighted graph.
     * @param G the edge-weighted graph
     */
    public PrimMST(EdgeWeightedGraph G) {
        edgeTo = new Edge[G.V()];
        distTo = new double[G.V()];
        marked = new boolean[G.V()];
        pq = new IndexMinPQ<Double>(G.V());
        for (int v = 0; v < G.V(); v++) distTo[v] = Double.POSITIVE_INFINITY;

        for (int v = 0; v < G.V(); v++)      // run from each vertex to find
            if (!marked[v]) prim(G, v);      // minimum spanning forest
    }

    // run Prim's algorithm in graph G, starting from vertex s
    private void prim(EdgeWeightedGraph G, int s) {
        distTo[s] = 0.0;
        pq.insert(s, distTo[s]); //用顶点0和权重0初始化pq
        while (!pq.isEmpty()) {
            int v = pq.delMin();  
            scan(G, v);          //将最近的顶点添加到树中
        }
    }

    // scan vertex v
    private void scan(EdgeWeightedGraph G, int v) {
    		//将顶点v添加到树中，更新数据
        marked[v] = true;
        for (Edge e : G.adj(v)) {
            int w = e.other(v);
            if (marked[w]) continue;         // v-w 已经失效
            if (e.weight() < distTo[w]) {
            		//连接w和树的最佳边Edge变为e
                distTo[w] = e.weight();
                edgeTo[w] = e;
                if (pq.contains(w)) pq.decreaseKey(w, distTo[w]);
                else                pq.insert(w, distTo[w]);
            }
        }
    }

    //所有边
    public Iterable<Edge> edges() {
        Queue<Edge> mst = new Queue<Edge>();
        for (int v = 0; v < edgeTo.length; v++) {
            Edge e = edgeTo[v];
            if (e != null) {
                mst.enqueue(e);
            }
        }
        return mst;
    }

    //权重
    public double weight() {
        double weight = 0.0;
        for (Edge e : edges())
            weight += e.weight();
        return weight;
    }
}
```

### 4.2 Kruskal算法
Kruskal算法构造最小生成树时也是一条边一条边地构造，但它寻找的边会连接一片森林中的两棵树。我们从一片由V棵单顶点的树构成的森林开始并不断将两棵树合并（用可以找到的最短边）直到只剩下一棵树。其主要思想是按边的权重顺序处理它们，将边加入最小生成树中，加入的边不会与已经加入的边构成环，直到树中含有V-1条边为止。

![image](/myresource/images/image_blog_2014-11-02-kruskal.jpg)

实现时，采用优先队列将边按照权重排序，用一个union-find数据结构识别会形成环的边，以及一个队列来保存最小生成树的所有边。代码实现如下：

```
public class KruskalMST {
    private double weight;  // weight of MST
    private Queue<Edge> mst = new Queue<Edge>();  // edges in MST

    public KruskalMST(EdgeWeightedGraph G) {
        // more efficient to build heap by passing array of edges
        MinPQ<Edge> pq = new MinPQ<Edge>();
        for (Edge e : G.edges()) {
            pq.insert(e);
        }

        // run greedy algorithm
        UF uf = new UF(G.V());
        while (!pq.isEmpty() && mst.size() < G.V() - 1) {
            Edge e = pq.delMin();  //从pq得到权重最小的边和它的顶点
            int v = e.either();
            int w = e.other(v);
            if (!uf.connected(v, w)) { // v-w does not create a cycle
                uf.union(v, w);  // merge v and w components
                mst.enqueue(e);  // add edge e to mst
                weight += e.weight();
            }
        }
    }

    //树的所有边
    public Iterable<Edge> edges() {
        return mst;
    }

    //树的权重
    public double weight() {
        return weight;
    }
}
```

Kruskal算法所需的空间与E成正比，所需时间与ElogE成正比（最坏情况下）。

Prim和Kruskal算法不能处理有向图。


参考：[http://algs4.cs.princeton.edu/43mst](http://algs4.cs.princeton.edu/43mst/)

