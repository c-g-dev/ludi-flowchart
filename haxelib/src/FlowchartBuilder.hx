package;

import model.Graph;
import model.FlowchartNode;
import model.FlowchartConnection;
import model.NodeTemplate;
import ui.CanvasView;
import ui.PaletteView;
import ui.DialogView;
import ui.PreviewDialog;
import ui.OptionsDialog;
import serialize.FlowchartSerializer;
import js.Browser;
import js.html.FileReader;
import js.html.InputElement;
import types.CustomParamType;

import model.Note;
import history.TransactionManager;
import history.Transactions;
import ui.ContextMenu;

class FlowchartBuilder {
    public var graph:Graph<FlowchartNode, FlowchartConnection>;
    public var notes:Array<Note>;
    public var canvasView:CanvasView;
    public var paletteView:PaletteView;
    public var dialogView:DialogView;
    public var previewDialog:PreviewDialog;
    public var optionsDialog:OptionsDialog;
    public var templates:Array<NodeTemplate>;
    public var customParamTypes:Array<CustomParamType>;
    public var onSave:Void->Void;
    public var transactionManager:TransactionManager;
    public var defaultConnectionTag:String = "";

    public function new(templates:Array<NodeTemplate>, ?customParamTypes:Array<CustomParamType>) {
        this.templates = templates;
        this.customParamTypes = customParamTypes != null ? customParamTypes : [];
    }

    public function init() {
        trace("Flowchart Builder Initialized");
        
        if (graph == null) graph = new Graph();
        if (notes == null) notes = [];
        
        transactionManager = new TransactionManager();
        
        canvasView = new CanvasView("flowchart-canvas", graph, notes);
        
        paletteView = new PaletteView("palette", templates);
        dialogView = new DialogView("node-editor", customParamTypes);
        previewDialog = new PreviewDialog("preview-dialog");
        optionsDialog = new OptionsDialog("options-dialog");

        optionsDialog.onSave = function(newTag) {
            defaultConnectionTag = newTag;
        };

        var contextMenu = new ContextMenu();

        // Hook up events
        canvasView.onNodeCreate = function(templateName, x, y) {
            var template = findTemplate(templateName);
            if (template != null) {
                var nodeId = "node_" + Date.now().getTime() + "_" + Math.floor(Math.random() * 1000);
                var node = new FlowchartNode(nodeId, template, x, y);
                
                transactionManager.add(new AddNodeTransaction(graph, node));
                graph.addNode(node);
                canvasView.draw();
            }
        };

        canvasView.onEditNode = function(node) {
            dialogView.open(node);
        };
        
        canvasView.onConnect = function(sourceId, targetId) {
             var source = findNodeById(sourceId);
             var target = findNodeById(targetId);
             if (source != null && target != null) {
                 var conn = new GraphConnection(source, target, new FlowchartConnection(defaultConnectionTag));
                 
                 transactionManager.add(new ConnectTransaction(graph, conn));
                 graph.addEdge(conn);
                 canvasView.draw();
             }
        };

        canvasView.onMoveNode = function(node, startX, startY, endX, endY) {
            if (startX != endX || startY != endY) {
                transactionManager.add(new MoveNodeTransaction(node, startX, startY, endX, endY));
            }
        };

        canvasView.onMoveNote = function(note, startX, startY, endX, endY) {
            if (startX != endX || startY != endY) {
                transactionManager.add(new MoveNoteTransaction(note, startX, startY, endX, endY));
            }
        };

        canvasView.onResizeNote = function(note, startW, startH, endW, endH) {
            if (startW != endW || startH != endH) {
                transactionManager.add(new ResizeNoteTransaction(note, startW, startH, endW, endH));
            }
        };

        canvasView.onEditConnection = function(edge) {
            var tag = Browser.window.prompt("Edit Connection Tag:", edge.edge.tag);
            if (tag != null) {
                // TODO: Add Transaction for connection edit
                edge.edge.tag = tag;
                canvasView.draw();
            }
        };

        canvasView.onEditNoteText = function(note) {
             dialogView.openNote(note);
        };
        
        dialogView.onSaveNote = function(note) {
            canvasView.draw();
        };

        canvasView.onContextMenu = function(x, y, targetType, targetId) {
            var items:Array<MenuItem> = [];
            
            if (targetType == "node") {
                items.push({
                    label: "Delete Node", 
                    action: function() {
                        var node = findNodeById(targetId);
                        if (node != null) {
                            transactionManager.add(new DeleteNodeTransaction(graph, node));
                            graph.removeNode(node);
                             var edges = graph.adjacent(node);
                             for (e in edges) graph.removeEdge(e);
                            canvasView.draw();
                        }
                    }
                });
            } else if (targetType == "connection") {
                items.push({
                    label: "Delete Connection", 
                    action: function() {

                    }
                });
            } else if (targetType == "note") {
                items.push({
                    label: "Delete Note", 
                    action: function() {
                        var note = findNoteById(targetId);
                        if (note != null) {
                            transactionManager.add(new DeleteNoteTransaction(notes, note));
                            notes.remove(note);
                            canvasView.draw();
                        }
                    }
                });
            }

            if (items.length > 0) {
                contextMenu.show(x, y, items);
            }
        };
        

        canvasView.onConnectionContextMenu = function(x, y, conn) {
            contextMenu.show(x, y, [
                {
                    label: "Delete Connection",
                    action: function() {
                        transactionManager.add(new DisconnectTransaction(graph, conn));
                        graph.removeEdge(conn);
                        canvasView.draw();
                    }
                }
            ]);
        };

        dialogView.onSave = function(node) {
            canvasView.draw();
        };

        setupToolbar();
        setupNoteButton();
        setupShortcuts();
    }
    
    function setupShortcuts() {
        Browser.window.addEventListener("keydown", function(e:js.html.KeyboardEvent) {
            if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() == "z") {
                if (e.shiftKey) {
                    transactionManager.redo();
                } else {
                    transactionManager.undo();
                }
                canvasView.draw();
                e.preventDefault();
            } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() == "y") {
                transactionManager.redo();
                canvasView.draw();
                e.preventDefault();
            }
        });
    }

    function setupNoteButton() {
        var btnAddNote = Browser.document.getElementById("btn-add-note");
        if (btnAddNote != null) {
            btnAddNote.onclick = function() {
                var noteId = "note_" + Date.now().getTime();
                var note = new Note(noteId, "New Note", 100, 100);
                
                transactionManager.add(new AddNoteTransaction(notes, note));
                notes.push(note);
                canvasView.draw();
            };
        }
    }
    
    function findNodeById(id:String):FlowchartNode {
        for (n in graph.nodes) {
            if (n.id == id) return n;
        }
        return null;
    }

    function findNoteById(id:String):Note {
        for (n in notes) {
            if (n.id == id) return n;
        }
        return null;
    }

    function findTemplate(name:String):NodeTemplate {
        for (t in templates) {
            if (t.name == name) return t;
        }
        return null;
    }

    function setupToolbar() {
        var btnSave = Browser.document.getElementById("btn-save");
        var btnLoad = Browser.document.getElementById("btn-load");
        var btnOptions = Browser.document.getElementById("btn-options");
        var btnPreview = Browser.document.getElementById("btn-preview");
        var fileInput:InputElement = cast Browser.document.getElementById("file-input");

        if (btnSave != null) {
            btnSave.onclick = function() {
                if (onSave != null) {
                    onSave();
                    return;
                }
                // Simple JSON serialization for now
                // We need to implement toJSON/fromJSON on Graph or use a serializer
                var data = {
                    nodes: graph.nodes,
                    edges: graph.edges.map(function(e) return {
                        sourceId: e.source.id,
                        targetId: e.target.id,
                        tag: e.edge.tag
                    }),
                    notes: notes
                };
                
                var json = haxe.Json.stringify(data, null, "  ");
                var blob = new js.html.Blob([json], {type: "application/json"});
                var url = js.html.URL.createObjectURL(blob);
                var a = Browser.document.createAnchorElement();
                a.href = url;
                a.download = "flowchart.json";
                a.click();
                js.html.URL.revokeObjectURL(url);
            };
        }

        if (btnLoad != null) {
            btnLoad.onclick = function() {
                fileInput.click();
            };
        }

        if (fileInput != null) {
            fileInput.onchange = function(e) {
                if (fileInput.files.length > 0) {
                    var file = fileInput.files[0];
                    var reader = new FileReader();
                    reader.onload = function(e) {
                        try {
                            var json = reader.result;
                            var data:Dynamic = haxe.Json.parse(json);
                            
                            // Clear current
                            graph = new Graph();
                            notes = [];
                            
                            // Reconstruct Nodes
                            if (data.nodes != null) {
                                var nodesList:Array<Dynamic> = data.nodes;
                                for (nData in nodesList) {
                                    var templateName = nData.template.name;
                                    var template = findTemplate(templateName);
                                    if (template != null) {
                                        var node = new FlowchartNode(nData.id, template, nData.x, nData.y);
                                        // Restore data
                                        var dataMap:Dynamic = nData.data;
                                        // Need to iterate keys of dynamic object
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
                                    var source = findNodeById(eData.sourceId);
                                    var target = findNodeById(eData.targetId);
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
                                    // Use defaults if width/height missing (backward compatibility)
                                    var w = (nData.width != null) ? nData.width : 200;
                                    var h = (nData.height != null) ? nData.height : 150;
                                    var note = new Note(nData.id, nData.text, nData.x, nData.y, w, h);
                                    notes.push(note);
                                }
                            }
                            
                            // Update View
                            canvasView.graph = graph;
                            canvasView.notes = notes;
                            
                            // Reset transaction history
                            transactionManager = new TransactionManager();
                            
                            canvasView.draw();
                            
                        } catch (err:Dynamic) {
                            Browser.window.alert("Error loading file: " + err);
                            trace(err);
                        }
                    };
                    reader.readAsText(file);
                }
                fileInput.value = ""; 
            };
        }

        if (btnOptions != null) {
            btnOptions.onclick = function() {
                optionsDialog.open(defaultConnectionTag);
            };
        }

        if (btnPreview != null) {
            btnPreview.onclick = function() {
                previewDialog.showOptions({
                    onTemplates: function() {
                         var json = haxe.Json.stringify(templates, null, "  ");
                         previewDialog.showContent("Templates", json);
                    },
                    onFlowchart: function() {
                         var nodes = graph.nodes.map(function(node) {
                             var dataObj = {};
                             for (k in node.data.keys()) {
                                 Reflect.setField(dataObj, k, node.data.get(k));
                             }
                             return {
                                 id: node.id,
                                 x: node.x,
                                 y: node.y,
                                 template: node.template.name,
                                 data: dataObj
                             };
                         });
                         var json = haxe.Json.stringify(nodes, null, "  ");
                         previewDialog.showContent("Flowchart Nodes", json);
                    },
                    onCode: function() {
                        var serializer = new FlowchartSerializer();
                        var code = serializer.write(graph);
                        previewDialog.showContent("Generated Code", code);
                    }
                });
            };
        }
    }
}
