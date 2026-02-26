package ludi.flowchart.loader;

import ludi.flowchart.model.NodeTemplate.NodeParameter;

class ParsedNodeInfo {
    public var params:Array<NodeParameter>;
    public var attachMethodName:String;
    public var className:String;
    public var nodeCategory:String;

    public function new() {
        params = [];
    }
}
