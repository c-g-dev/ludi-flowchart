package ludi.flowchart.serialize;

import ludi.flowchart.model.Graph;
import ludi.flowchart.model.FlowchartNode;
import ludi.flowchart.model.FlowchartConnection;

interface IFlowchartSerializer {
    function write(graph: Graph<FlowchartNode, FlowchartConnection>): String;
}