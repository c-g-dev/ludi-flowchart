package model;

class Graph<V,E> {
    public var nodes:Array<V>;
    public var edges:Array<GraphConnection<V,E>>;

    public function new() {
        this.nodes = [];
        this.edges = [];
    }

    public function adjacent(node:V):Array<GraphConnection<V,E>> {
        return edges.filter(function(e) return e.source == node || e.target == node);
    }

    public function incoming(node:V):Array<GraphConnection<V,E>> {
        return edges.filter(function(e) return e.target == node);
    }

    public function outgoing(node:V):Array<GraphConnection<V,E>> {
        return edges.filter(function(e) return e.source == node);
    }

    public function neighbors(node:V):Array<V> {
        return adjacent(node).map(function(e) return e.source == node ? e.target : e.source);
    }

    public function addNode(node:V):Void {
        nodes.push(node);
    }

    public function addEdge(edge:GraphConnection<V,E>):Void {
        edges.push(edge);
    }

    public function removeNode(node:V):Void {
        nodes = nodes.filter(function(n) return n != node);
    }

    public function removeEdge(edge:GraphConnection<V,E>):Void {
        edges = edges.filter(function(e) return e != edge);
    }

    public function getRoots():Array<V> {
        var roots = [];
        for (node in nodes) {
            var isTarget = false;
            for (edge in edges) {
                if (edge.target == node) {
                    isTarget = true;
                    break;
                }
            }
            if (!isTarget) {
                roots.push(node);
            }
        }
        return roots;
    }
}


class GraphConnection<V,E> {
    public var source:V;
    public var target:V;
    public var edge:E;

    public function new(source:V, target:V, edge:E) {
        this.source = source;
        this.target = target;
        this.edge = edge;
    }
}
