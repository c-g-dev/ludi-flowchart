package;

import model.FlowchartNode;

/**
 * Event types for Flowchart Playback
 */
enum FlowchartPlayAdapterEvent {
    Start;
    Pause;
    PlayNode(n:FlowchartNode);
    ImmediatelyCompleteNode(n:FlowchartNode);
    Reset;
}

/**
 * Adapter interface for handling flowchart playback
 */
abstract class FlowchartPlayAdapter {
    
    public function new() {}

    /**
     * Handle playback events
     */
    public abstract function onEvent(e:FlowchartPlayAdapterEvent):Dynamic;
 
    /**
     * Override this to change the execution order of upstream nodes.
     * By default it returns the provided order (which is Depth-First Topological Sort).
     */
    public function orderNodes(nodes:Array<FlowchartNode>):Array<FlowchartNode> {
        return nodes;
    }
}
