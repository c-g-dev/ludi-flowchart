package serialize;

import model.Graph;
import model.FlowchartNode;
import model.FlowchartConnection;

interface IFlowchartSerializer {
    function write(graph: Graph<FlowchartNode, FlowchartConnection>): String;
}