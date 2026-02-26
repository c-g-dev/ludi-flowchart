package ludi.flowchart.loader;

interface INodeFileParser {
    function parse(file:String):ParsedNodeInfo;
}
