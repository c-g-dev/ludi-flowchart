package;

import model.FlowchartNode;

enum FlowchartPlayAdapterEvent {
    Start;
    Pause;
    PlayNode(n:FlowchartNode);
    ImmediatelyCompleteNode(n:FlowchartNode);
    Reset;
}

abstract class FlowchartPlayAdapter {
    
    public function new() {}

    public abstract function onEvent(e:FlowchartPlayAdapterEvent):Dynamic;

    public function orderNodes(nodes:Array<FlowchartNode>):Array<FlowchartNode> {
        return nodes;
    }
}
