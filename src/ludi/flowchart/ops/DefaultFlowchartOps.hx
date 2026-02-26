package ludi.flowchart.ops;

import ludi.flowchart.model.Graph;
import ludi.flowchart.model.FlowchartNode;
import ludi.flowchart.model.FlowchartConnection;
import ludi.flowchart.model.Note;
import ludi.flowchart.model.NodeTemplate;
#if hxnodejs
import js.node.Fs;
#end
import js.Browser;
import js.html.FileReader;
import js.html.InputElement;
import js.html.Blob;
import js.html.URL;
import js.html.AnchorElement;

class DefaultFlowchartOps implements IFlowchartOps {
    
    public function new() {}

    public function tryLoadText(path:String):Null<String> {
        #if hxnodejs
        if (Fs.existsSync(path)) {
            return Fs.readFileSync(path, "utf8");
        }
        #end
        return null;
    }

    public function exists(path:String):Bool {
        #if hxnodejs
        return Fs.existsSync(path);
        #else
        return false;
        #end
    }

    public function saveFlowchart(graph:Graph<FlowchartNode, FlowchartConnection>, notes:Array<Note>, ?onComplete:Void->Void):Void {
        // Serialize node.data Map values into plain JSON objects.
        var data = {
            nodes: graph.nodes.map(function(node) return {
                id: node.id,
                template: node.template,
                x: node.x,
                y: node.y,
                data: mapToDynamic(node.data)
            }),
            edges: graph.edges.map(function(e) return {
                sourceId: e.source.id,
                targetId: e.target.id,
                tag: e.edge.tag
            }),
            notes: notes
        };
        
        var json = haxe.Json.stringify(data, null, "  ");
        var blob = new Blob([json], {type: "application/json"});
        var url = URL.createObjectURL(blob);
        var a:AnchorElement = Browser.document.createAnchorElement();
        a.href = url;
        a.download = "flowchart.json";
        a.click();
        URL.revokeObjectURL(url);
        
        if (onComplete != null) onComplete();
    }

    public function requestLoadFlowchart(templates:Array<NodeTemplate>, onLoaded:(Graph<FlowchartNode, FlowchartConnection>, Array<Note>)->Void):Void {
        var fileInput:InputElement = cast Browser.document.getElementById("file-input");
        if (fileInput == null) {
            // Create if not exists (fallback)
            fileInput = Browser.document.createInputElement();
            fileInput.type = "file";
            fileInput.id = "file-input";
            fileInput.style.display = "none";
            Browser.document.body.appendChild(fileInput);
        }

        // Remove old listener to avoid duplicates if possible, or just set onchange
        fileInput.onchange = function(e) {
            if (fileInput.files.length > 0) {
                var file = fileInput.files[0];
                var reader = new FileReader();
                reader.onload = function(e) {
                    try {
                        var json:String = cast reader.result;
                        var data:Dynamic = haxe.Json.parse(json);
                        
                        var graph = new Graph<FlowchartNode, FlowchartConnection>();
                        var notes = new Array<Note>();
                        
                        // Reconstruct Nodes
                        if (data.nodes != null) {
                            var nodesList:Array<Dynamic> = data.nodes;
                            for (nData in nodesList) {
                                var templateName = nData.template.name;
                                var template = findTemplate(templates, templateName);
                                if (template != null) {
                                    var node = new FlowchartNode(nData.id, template, nData.x, nData.y);
                                    // Restore data
                                    var dataMap:Dynamic = normalizeNodeData(nData.data);
                                    for (field in Reflect.fields(dataMap)) {
                                        node.data.set(field, Reflect.field(dataMap, field));
                                    }
                                    graph.addNode(node);
                                }
                            }
                        }
                        
                        // Reconstruct Edges
                        if (data.edges != null) {
                            var edgesList:Array<Dynamic> = data.edges;
                            for (eData in edgesList) {
                                var source = findNodeById(graph, eData.sourceId);
                                var target = findNodeById(graph, eData.targetId);
                                if (source != null && target != null) {
                                    var conn = new GraphConnection(source, target, new FlowchartConnection(eData.tag));
                                    graph.addEdge(conn);
                                }
                            }
                        }
                        
                        // Reconstruct Notes
                        if (data.notes != null) {
                            var notesList:Array<Dynamic> = data.notes;
                            for (nData in notesList) {
                                var w = (nData.width != null) ? nData.width : 200;
                                var h = (nData.height != null) ? nData.height : 150;
                                var note = new Note(nData.id, nData.text, nData.x, nData.y, w, h);
                                notes.push(note);
                            }
                        }
                        
                        onLoaded(graph, notes);
                        
                    } catch (err:Dynamic) {
                        Browser.window.alert("Error loading file: " + err);
                        trace(err);
                    }
                };
                reader.readAsText(file);
            }
            fileInput.value = ""; 
        };
        
        fileInput.click();
    }

    function findTemplate(templates:Array<NodeTemplate>, name:String):NodeTemplate {
        for (t in templates) {
            if (t.name == name) return t;
        }
        return null;
    }

    function findNodeById(graph:Graph<FlowchartNode, FlowchartConnection>, id:String):FlowchartNode {
        for (n in graph.nodes) {
            if (n.id == id) return n;
        }
        return null;
    }

    function mapToDynamic(data:Map<String, Dynamic>):Dynamic {
        var out:Dynamic = {};
        for (key in data.keys()) {
            Reflect.setField(out, key, data.get(key));
        }
        return out;
    }

    // Backward compatibility for previously saved malformed map wrappers.
    function normalizeNodeData(rawData:Dynamic):Dynamic {
        var current = rawData;

        while (current != null && isLegacyMapWrapper(current)) {
            current = Reflect.field(current, "h");
        }

        return current != null ? current : {};
    }

    function isLegacyMapWrapper(value:Dynamic):Bool {
        var fields = Reflect.fields(value);
        if (fields.length != 1 || fields[0] != "h") {
            return false;
        }

        var inner = Reflect.field(value, "h");
        return inner != null && Reflect.isObject(inner) && !Std.isOfType(inner, Array);
    }
}
