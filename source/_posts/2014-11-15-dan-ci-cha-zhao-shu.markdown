---
layout: post
title: "单词查找树"
date: 2014-11-16 22:37:38 +0800
comments: true
toc: true
categories: 
- 算法
---
在[符号表](/blog/2014/10/02/cha-zhao-suan-fa-fu-hao-biao/)中学习了二叉树、红黑树等，单词查找树比这些通用算法更加有效。它查找命中所需的时间与被查找的键的长度成正比，查找未命中只需检查若干个字符。这样的性能是相当惊人的，它们是算法研究的最高成就之一。

<!--more-->

我们扩展符号表的API，增加基于字符的用于处理字符串类型的键的操作。

以字符串为键的符号表的API(`StringST<Value>`)

方法|说明
---|---
`StringST()` | 创建一个符号表
`void put(String key, Value val)` | 向表中插入键值对（如果值为null则删除键key）
`Value get(String key)` | 键key所对应的值，如果不存在则返回null
`void delete(String key)` | 删除键key（和它的值）
`boolean contains(String key)` | 表中是否存在key的值
`boolean isEmpty()` | 符号表是否为空
**`String longestPrefixOf(String s)`** | s的前缀中最长的键 
**`Iterable<String> keysWithPrefix(String s)`** | 所有以s为前缀的键
**`Iterable<String> keysThatMatch(String s)`** | 所有和s匹配的键（其中“.”能够匹配任意字符）
`int size()`  | 键值对的数量 
`Iterable<String> keys()` | 符号表中的所有键 

上面的API与符号表API的不同之处在于Key换成了String, 增加了粗体显示的三个方法。

## 1. R向单词查找树
与各种查找树一样，单词查找树也是由链接的结点所组成的数据结构。每个结点只有一个父结点（根结点除外），每个结点都含有R条链接，其中R为字母表的大小。每个键所关联的值保存在该键的最后一个字母所对应的结点中。值为空的结点在符号表中没有对应的键，它们的存在是为了简化单词查找树中的查找操作。

![image](/myresource/images/image_blog_2014-11-16-tries-node.jpg)

### 1.1 查找操作
单词查找树的查找操作非常简单，从首字母开始延着树结点查找就可以：

* 键的尾字符所对应的结点中的值非空，命中！
* 键的尾字符所对应的结点中的值为空，未命中！
* 查找结束于一条空链接，未命中！

### 1.2 插入操作
和二叉查找树一样，在插入之前要进行一次查找。

* 在到达键的尾字符之前就遇到了一个空链接。证明不存在匹配的结点，为键中还未被检查的每个字符创建一个对应的结点，并将键对应的值保存到最后一个字符的结点中。
* 在遇到空链接之前就到达了键的尾字符。将该结点的值设为键对应的值（无论该值是否为空）。

### 1.3 删除操作
删除的第一步是找到键所对应的结点并将它的值设为空null. 如果该结点含有一个非空的链接指向某个子结点，那么就不需要再进行其他操作了。如果它的所有链接均为空，那就需要从数据结构中删除这个结点。如果删除它使得它的父结点的所有链接也均为空，就要继续删除它的父结点，依此类推。

### 1.4 实现

```java
public class TrieST<Value> {
    private static final int R = 256;        // extended ASCII


    private Node root;      // root of trie
    private int N;          // number of keys in trie

    // R-way trie node
    private static class Node {
        private Object val;
        private Node[] next = new Node[R];
    }

    public TrieST() {
    }

   /**
     * Initializes an empty string symbol table.
     */

    /**
     * Returns the value associated with the given key.
     * @param key the key
     * @return the value associated with the given key if the key is in the symbol table
     *     and <tt>null</tt> if the key is not in the symbol table
     * @throws NullPointerException if <tt>key</tt> is <tt>null</tt>
     */
    public Value get(String key) {
        Node x = get(root, key, 0);
        if (x == null) return null;
        return (Value) x.val;
    }

    /**
     * Does this symbol table contain the given key?
     * @param key the key
     * @return <tt>true</tt> if this symbol table contains <tt>key</tt> and
     *     <tt>false</tt> otherwise
     * @throws NullPointerException if <tt>key</tt> is <tt>null</tt>
     */
    public boolean contains(String key) {
        return get(key) != null;
    }

    private Node get(Node x, String key, int d) {
        if (x == null) return null;
        if (d == key.length()) return x;
        char c = key.charAt(d);
        return get(x.next[c], key, d+1);
    }

    /**
     * Inserts the key-value pair into the symbol table, overwriting the old value
     * with the new value if the key is already in the symbol table.
     * If the value is <tt>null</tt>, this effectively deletes the key from the symbol table.
     * @param key the key
     * @param val the value
     * @throws NullPointerException if <tt>key</tt> is <tt>null</tt>
     */
    public void put(String key, Value val) {
        if (val == null) delete(key);
        else root = put(root, key, val, 0);
    }

    private Node put(Node x, String key, Value val, int d) {
        if (x == null) x = new Node();
        if (d == key.length()) {
            if (x.val == null) N++;
            x.val = val;
            return x;
        }
        char c = key.charAt(d);
        x.next[c] = put(x.next[c], key, val, d+1);
        return x;
    }

    /**
     * Returns the number of key-value pairs in this symbol table.
     * @return the number of key-value pairs in this symbol table
     */
    public int size() {
        return N;
    }

    /**
     * Is this symbol table empty?
     * @return <tt>true</tt> if this symbol table is empty and <tt>false</tt> otherwise
     */
    public boolean isEmpty() {
        return size() == 0;
    }

    /**
     * Returns all keys in the symbol table as an <tt>Iterable</tt>.
     * To iterate over all of the keys in the symbol table named <tt>st</tt>,
     * use the foreach notation: <tt>for (Key key : st.keys())</tt>.
     * @return all keys in the sybol table as an <tt>Iterable</tt>
     */
    public Iterable<String> keys() {
        return keysWithPrefix("");
    }

    /**
     * Returns all of the keys in the set that start with <tt>prefix</tt>.
     * @param prefix the prefix
     * @return all of the keys in the set that start with <tt>prefix</tt>,
     *     as an iterable
     */
    public Iterable<String> keysWithPrefix(String prefix) {
        Queue<String> results = new Queue<String>();
        Node x = get(root, prefix, 0);
        collect(x, new StringBuilder(prefix), results);
        return results;
    }

    private void collect(Node x, StringBuilder prefix, Queue<String> results) {
        if (x == null) return;
        if (x.val != null) results.enqueue(prefix.toString());  //有值才是键
        for (char c = 0; c < R; c++) {
            prefix.append(c);
            collect(x.next[c], prefix, results);
            prefix.deleteCharAt(prefix.length() - 1);
        }
    }

    /**
     * Returns all of the keys in the symbol table that match <tt>pattern</tt>,
     * where . symbol is treated as a wildcard character.
     * @param pattern the pattern
     * @return all of the keys in the symbol table that match <tt>pattern</tt>,
     *     as an iterable, where . is treated as a wildcard character.
     */
    public Iterable<String> keysThatMatch(String pattern) {
        Queue<String> results = new Queue<String>();
        collect(root, new StringBuilder(), pattern, results);
        return results;
    }

    private void collect(Node x, StringBuilder prefix, String pattern, Queue<String> results) {
        if (x == null) return;
        int d = prefix.length();
        if (d == pattern.length() && x.val != null)
            results.enqueue(prefix.toString());
        if (d == pattern.length())
            return;
        char c = pattern.charAt(d);
        if (c == '.') {
            for (char ch = 0; ch < R; ch++) {
                prefix.append(ch);
                collect(x.next[ch], prefix, pattern, results);
                prefix.deleteCharAt(prefix.length() - 1);
            }
        }
        else {
            prefix.append(c);
            collect(x.next[c], prefix, pattern, results);
            prefix.deleteCharAt(prefix.length() - 1);
        }
    }

    /**
     * Returns the string in the symbol table that is the longest prefix of <tt>query</tt>,
     * or <tt>null</tt>, if no such string.
     * @param query the query string
     * @throws NullPointerException if <tt>query</tt> is <tt>null</tt>
     * @return the string in the symbol table that is the longest prefix of <tt>query</tt>,
     *     or <tt>null</tt> if no such string
     */
    public String longestPrefixOf(String query) {
        int length = longestPrefixOf(root, query, 0, 0);
        return query.substring(0, length);
    }

    // returns the length of the longest string key in the subtrie
    // rooted at x that is a prefix of the query string,
    // assuming the first d character match and we have already
    // found a prefix match of length length
    private int longestPrefixOf(Node x, String query, int d, int length) {
        if (x == null) return length;
        if (x.val != null) length = d;
        if (d == query.length()) return length;
        char c = query.charAt(d);
        return longestPrefixOf(x.next[c], query, d+1, length);
    }

    /**
     * Removes the key from the set if the key is present.
     * @param key the key
     * @throws NullPointerException if <tt>key</tt> is <tt>null</tt>
     */
    public void delete(String key) {
        root = delete(root, key, 0);
    }

    private Node delete(Node x, String key, int d) {
        if (x == null) return null;
        if (d == key.length()) {
            if (x.val != null) N--;
            x.val = null;
        }
        else {
            char c = key.charAt(d);
            x.next[c] = delete(x.next[c], key, d+1);
        }

        // remove subtrie rooted at x if it is completely empty
        if (x.val != null) return x;
        for (int c = 0; c < R; c++)
            if (x.next[c] != null)
                return x;
        return null;
    }

}
```

上面的代码可以处理扩展ASCII码，但很容易就可以修改为能够处理由任意字母表得到的键：

1. 实现一个构造函数，接受Alphabet，将R设置为字母表大小。
2. 在get()、put()中使用Alphabet的toIndex()，将字符串中的字符转化为0到R-1的索引值。
3. 在keys()、keysWithPrefix()和keysThatMatch()方法中，使用Alphabet的toChar()方法，将0到R-1之间的索引值转化为字符型(char)值。

### 1.5 单词查找树的性质
单词查找树的链表结构（形状）和键的插入或删除顺序无关，对于任意给定的一组键，其单词查找树都是唯一的。

在单词查找树中查找一个键或是插入一个键时，访问数组的次数最多为键的长度加1！

字母表的大小为R，在一棵由N个随机键构造的单词树中，未命中查找平均所需检查的结点数量为~log<sub>R</sub><sup>N</sup>。

一棵单词查找树中的链接总数在RN到RNw之间，其中w为键的平均长度。因此单词查找树的空间消耗非常大。长键也可能占用大量空间，因为它通常有一条长长的尾巴。单词查找树的内部也可能存在单向的分支。例如两个长键可能只有最后一个字符不同。

如果能够负担得起R向单词查找树的庞大空间，它的性能是无可匹敌的。

## 2. 三向单词查找树
三向单词查找树可以避免R向单词查找树过度的空间消耗。它的每个结点都含有一个字符、三条链接和一个值。三条链接分别对应当前字母小于、等于和大于结点字母的所有键。

![image](/myresource/images/image_blog_2014-11-16-tst.jpg)

### 2.1 查找、插入和删除操作
在查找时，首先比较键的首字母和根结点的字母。如果键的首字母较小，就选择左链接；如果较大，就选择右链接；如果相等则选择中链接。然后递归地使用相同的算法。如果遇到一个空链接或者当键结束时结点的值为空，那么查找未命中。如果键结束时结点的值非空则查找命中。

插入一个新键时，首先进行查找，然后和单词查找树一样，在树中补全键末尾的所有结点。

在三向单词查找树中，需要使用在二叉查找树中删除结点的方法来删去与该字符对应的结点。

### 2.2 实现

```java
public class TST<Value> {
    private int N;       // size
    private Node root;   // root of TST

    private class Node {
        private char c;                 // character
        private Node left, mid, right;  // left, middle, and right subtries
        private Value val;              // value associated with string
    }

    // return number of key-value pairs
    public int size() {
        return N;
    }

   /**************************************************************
    * Is string key in the symbol table?
    **************************************************************/
    public boolean contains(String key) {
        return get(key) != null;
    }

    public Value get(String key) {
        if (key == null) throw new NullPointerException();
        if (key.length() == 0) throw new IllegalArgumentException("key must have length >= 1");
        Node x = get(root, key, 0);
        if (x == null) return null;
        return x.val;
    }

    // return subtrie corresponding to given key
    private Node get(Node x, String key, int d) {
        if (key == null) throw new NullPointerException();
        if (key.length() == 0) throw new IllegalArgumentException("key must have length >= 1");
        if (x == null) return null;
        char c = key.charAt(d);
        if      (c < x.c)              return get(x.left,  key, d);
        else if (c > x.c)              return get(x.right, key, d);
        else if (d < key.length() - 1) return get(x.mid,   key, d+1);
        else                           return x;
    }


   /**************************************************************
    * Insert string s into the symbol table.
    **************************************************************/
    public void put(String s, Value val) {
        if (!contains(s)) N++;
        root = put(root, s, val, 0);
    }

    private Node put(Node x, String s, Value val, int d) {
        char c = s.charAt(d);
        if (x == null) {
            x = new Node();
            x.c = c;
        }
        if      (c < x.c)             x.left  = put(x.left,  s, val, d);
        else if (c > x.c)             x.right = put(x.right, s, val, d);
        else if (d < s.length() - 1)  x.mid   = put(x.mid,   s, val, d+1);
        else                          x.val   = val;
        return x;
    }


   /**************************************************************
    * Find and return longest prefix of s in TST
    **************************************************************/
    public String longestPrefixOf(String s) {
        if (s == null || s.length() == 0) return null;
        int length = 0;
        Node x = root;
        int i = 0;
        while (x != null && i < s.length()) {
            char c = s.charAt(i);
            if      (c < x.c) x = x.left;
            else if (c > x.c) x = x.right;
            else {
                i++;
                if (x.val != null) length = i;
                x = x.mid;
            }
        }
        return s.substring(0, length);
    }

    // all keys in symbol table
    public Iterable<String> keys() {
        Queue<String> queue = new Queue<String>();
        collect(root, "", queue);
        return queue;
    }

    // all keys starting with given prefix
    public Iterable<String> prefixMatch(String prefix) {
        Queue<String> queue = new Queue<String>();
        Node x = get(root, prefix, 0);
        if (x == null) return queue;
        if (x.val != null) queue.enqueue(prefix);
        collect(x.mid, prefix, queue);
        return queue;
    }

    // all keys in subtrie rooted at x with given prefix
    private void collect(Node x, String prefix, Queue<String> queue) {
        if (x == null) return;
        collect(x.left,  prefix,       queue);
        if (x.val != null) queue.enqueue(prefix + x.c);
        collect(x.mid,   prefix + x.c, queue);
        collect(x.right, prefix,       queue);
    }


    // return all keys matching given wildcard pattern
    public Iterable<String> wildcardMatch(String pat) {
        Queue<String> queue = new Queue<String>();
        collect(root, "", 0, pat, queue);
        return queue;
    }
 
    private void collect(Node x, String prefix, int i, String pat, Queue<String> q) {
        if (x == null) return;
        char c = pat.charAt(i);
        if (c == '.' || c < x.c) collect(x.left, prefix, i, pat, q);
        if (c == '.' || c == x.c) {
            if (i == pat.length() - 1 && x.val != null) q.enqueue(prefix + x.c);
            if (i < pat.length() - 1) collect(x.mid, prefix + x.c, i+1, pat, q);
        }
        if (c == '.' || c > x.c) collect(x.right, prefix, i, pat, q);
    }
}
```

### 2.3 三向单词查找树的性质
三向单词查找树与R向单词查找树的数据结构性质截然不同。它和其他所有二叉查找树一样，每个单词查找树结点的二叉查找树表示也取决于键的插入顺序。

它的每个结点只含有三个链接，因此所需空间远小于对应的单词查找树。由N个平均长度为w的字符串构造的三向单词查找树中的链接总数在3N到3Nw之间。

在一棵由N个随机字符串构造的三向单词查找树中，查找未命中平均需要比较字符~lnN次。除~lnN次外，一次插入或命中的查找会比较一次被查找的键中的每个字符。

使用三向单词查找树的最大好处是它能够很好地适应实际应用中可能出现的被查找键的不规则性。它可以使用256个字符的ASCII编码或者65536个字符的Unicode编码，而不必担心分支带来的巨大开销。

## 3. 总结

![image](/myresource/images/image_blog_2014-11-16-wordsfind-conclude.jpg)

参考：[http://algs4.cs.princeton.edu/52trie/](http://algs4.cs.princeton.edu/52trie/)
