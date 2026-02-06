package serialize;

import model.Graph;
import model.FlowchartNode;
import model.FlowchartConnection;
import model.NodeTemplate;

class FlowchartSerializer implements IFlowchartSerializer {
    
    public function new() {
    }

    public function write(graph: Graph<FlowchartNode, FlowchartConnection>): String {
        var sb = new StringBuf();
        
        sb.add("// Flowchart Generated Code\n");
        sb.add("function runFlowchart() {\n");
        
        // Helper to get safe var name
        var getVarName = function(node: FlowchartNode): String {
            var safeId = ~/[^a-zA-Z0-9_]/g.replace(node.id, "_");
            if (~/^[0-9]/.match(safeId)) {
                safeId = "_" + safeId;
            }
            return safeId;
        };

        // Helper to get constructor args
        var getConstructorArgs = function(node: FlowchartNode): String {
            var args = [];
            for (param in node.template.params) {
                var paramName = "";
                switch(param) {
                    case String(name, _, _): paramName = name;
                    case Number(name, _, _): paramName = name;
                    case Boolean(name, _, _): paramName = name;
                    case Array(name, _, _): paramName = name;
                    case Dropdown(name, _, _, _): paramName = name;
                    case Textarea(name, _, _): paramName = name;
                    case File(name, _, _): paramName = name;
                    case Custom(name, _, _): paramName = name;
                }
                
                var value = node.data.get(paramName);
                var argStr = "null";
                
                if (value != null) {
                     switch(param) {
                        case String(_, _, _), Dropdown(_, _, _, _), Textarea(_, _, _), File(_, _, _):
                            argStr = haxe.Json.stringify(value);
                        case Number(_, _, _):
                            argStr = Std.string(value);
                        case Boolean(_, _, _):
                            argStr = Std.string(value);
                        case Array(_, _, _):
                            argStr = haxe.Json.stringify(value);
                        case Custom(_, _, _):
                            argStr = "null";
                    }
                }
                args.push(argStr);
            }
            return args.join(", ");
        };
        
        // 1. Instantiate all nodes
        for (node in graph.nodes) {
            var serialization = node.template.serialization;
            if (serialization != null) {
                var varName = getVarName(node);
                var args = getConstructorArgs(node);
                var code = StringTools.replace(serialization.initializationTemplate, "{0}", varName);
                code = StringTools.replace(code, "{1}", args);
                sb.add(indent(code));
                sb.add("\n");
            }
        }
        
        sb.add("\n");
        
        // 2. Connect nodes
        for (edge in graph.edges) {
            var source = edge.source;
            var target = edge.target;
            
            var sourceSerialization = source.template.serialization;
            var targetSerialization = target.template.serialization;
            
            if (sourceSerialization != null && targetSerialization != null) {
                var sourceVar = getVarName(source);
                var targetVar = getVarName(target);
                var tag = edge.edge.tag != null ? edge.edge.tag : "";
                var tagStr = haxe.Json.stringify(tag);
                
                var code = StringTools.replace(sourceSerialization.attachToNodeTemplate, "{0}", sourceVar);
                code = StringTools.replace(code, "{1}", targetVar);
                code = StringTools.replace(code, "{2}", tagStr);
                
                sb.add(indent(code));
                sb.add("\n");
            }
        }

        sb.add("\n");

        // 3. Find and Start Roots
        // Roots are nodes that are not targets of any edge
        var targets = new Map<String, Bool>();
        for (edge in graph.edges) {
            targets.set(edge.target.id, true);
        }

        for (node in graph.nodes) {
            if (!targets.exists(node.id)) {
                var serialization = node.template.serialization;
                if (serialization != null) {
                     var varName = getVarName(node);
                     var code = StringTools.replace(serialization.attachToRootTemplate, "{0}", varName);
                     sb.add(indent(code));
                     sb.add("\n");
                }
            }
        }
        
        sb.add("}\n");
        
        return sb.toString();
    }
    
    function indent(str: String): String {
        var lines = str.split("\n");
        for (i in 0...lines.length) {
            if (lines[i].length > 0) {
                lines[i] = "    " + lines[i];
            }
        }
        return lines.join("\n");
    }
}
