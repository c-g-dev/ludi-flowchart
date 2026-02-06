package controller;

import ludi.compose.IComposible;
import ludi.compose.Composition;
import ludi.compose.CompositionEvent;
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
import serialize.IFlowchartSerializer;
import ops.IFlowchartOps;
import ops.DefaultFlowchartOps;
import js.Browser;
#if hxnodejs
import js.node.Path;
#end
import types.CustomParamType;
import model.Note;
import history.TransactionManager;
import history.Transactions;
import ui.ContextMenu;
import FlowchartPlayAdapter;

class FlowchartController implements IComposible {
    var graph:Graph<FlowchartNode, FlowchartConnection>;
    var notes:Array<Note>;
    var transactionManager:TransactionManager;
    var canvasView:CanvasView;
    var paletteView:PaletteView;
    var dialogView:DialogView;
    var previewDialog:PreviewDialog;
    var optionsDialog:OptionsDialog;
    var templates:Array<NodeTemplate>;
    var customParamTypes:Array<CustomParamType>;
    var ops:IFlowchartOps;
    var serializer:IFlowchartSerializer;
    var playAdapter:FlowchartPlayAdapter;
    var onSave:Void->Void;
    
    var defaultConnectionTag:String = "";
    var currentSelectedNode:FlowchartNode = null;
    var btnPlay:js.html.ButtonElement;

    public function new() {}

    public function onCompositionEvent(e:CompositionEvent, comp:Composition<Dynamic>):Void {
        switch (e) {
            case Setup:
                init(comp);
            case Other(event, payload):
                // Handle other events if needed
        }
    }

    function init(comp:Composition<Dynamic>) {
        this.graph = comp.fieldAccess("graph");
        this.notes = comp.fieldAccess("notes");
        this.transactionManager = comp.fieldAccess("transactionManager");
        this.canvasView = comp.fieldAccess("canvasView");
        this.paletteView = comp.fieldAccess("paletteView");
        this.dialogView = comp.fieldAccess("dialogView");
        this.previewDialog = comp.fieldAccess("previewDialog");
        this.optionsDialog = comp.fieldAccess("optionsDialog");
        this.templates = comp.fieldAccess("templates");
        this.customParamTypes = comp.fieldAccess("customParamTypes");
        this.ops = comp.fieldAccess("ops");
        this.serializer = comp.fieldAccess("serializer");
        this.playAdapter = comp.fieldAccess("playAdapter");
        this.onSave = comp.fieldAccess("onSave");

        trace("Flowchart Controller Initialized");

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
        setupPlayButton();
    }
    
    function setupPlayButton() {
        btnPlay = Browser.document.createButtonElement();
        btnPlay.id = "btn-play-flowchart";
        btnPlay.innerText = "Play From Node";
        btnPlay.className = "btn-play"; 
        btnPlay.style.position = "absolute";
        btnPlay.style.bottom = "20px";
        btnPlay.style.right = "20px";
        btnPlay.style.display = "none";
        btnPlay.style.zIndex = "1000";
        btnPlay.style.padding = "10px 20px";
        btnPlay.style.backgroundColor = "#2ecc71";
        btnPlay.style.color = "white";
        btnPlay.style.border = "none";
        btnPlay.style.borderRadius = "4px";
        btnPlay.style.cursor = "pointer";
        btnPlay.style.fontSize = "14px";
        
        Browser.document.body.appendChild(btnPlay);
        
        canvasView.onNodeSelected = function(node) {
             if (playAdapter != null) {
                 currentSelectedNode = node;
                 btnPlay.style.display = "block";
             }
        };
        
        canvasView.onSelectionCleared = function() {
            currentSelectedNode = null;
            btnPlay.style.display = "none";
        };
        
        btnPlay.onclick = function() {
            if (currentSelectedNode != null && playAdapter != null) {
                runPlaySequence(currentSelectedNode);
            }
        };
    }

    function runPlaySequence(startNode:FlowchartNode) {
        var upstream = collectUpstreamNodes(startNode);
        var ordered = playAdapter.orderNodes(upstream);
        
        playAdapter.onEvent(FlowchartPlayAdapterEvent.Start);
        
        for (node in ordered) {
             playAdapter.onEvent(FlowchartPlayAdapterEvent.ImmediatelyCompleteNode(node));
        }
        
        playAdapter.onEvent(FlowchartPlayAdapterEvent.PlayNode(startNode));
    }

    function collectUpstreamNodes(startNode:FlowchartNode):Array<FlowchartNode> {
        var visited = new Map<String, Bool>();
        var result = [];
        
        function visit(node:FlowchartNode) {
            if (visited.exists(node.id)) return;
            visited.set(node.id, true);
            
            var incomingEdges = graph.incoming(node);
            for (edge in incomingEdges) {
                visit(edge.source);
            }
            
            result.push(node);
        }
        
        visit(startNode);
        result.pop(); // Remove startNode
        return result;
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

        if (btnSave != null) {
            btnSave.onclick = function() {
                if (onSave != null) {
                    onSave();
                    return;
                }
                ops.saveFlowchart(graph, notes);
            };
        }

        if (btnLoad != null) {
            btnLoad.onclick = function() {
                ops.requestLoadFlowchart(templates, function(newGraph, newNotes) {
                    // Update View
                    // Need to update local references and composition target?
                    // The original code updated graph and notes variables.
                    // Here we update this.graph and this.notes.
                    // But we also need to update the references in views.
                    
                    graph = newGraph;
                    notes = newNotes;
                    
                    // Views need to know about new graph/notes if they hold references
                    // CanvasView does hold references.
                    canvasView.graph = graph;
                    canvasView.notes = notes;
                    
                    // Reset transaction history
                    transactionManager = new TransactionManager();
                    // We need to update this.transactionManager ref if we created a new one?
                    // Original code: transactionManager = new TransactionManager();
                    // So yes.
                    
                    canvasView.draw();
                });
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
                        var code = serializer.write(graph);
                        previewDialog.showContent("Generated Code", code);
                    }
                });
            };
        }
    }
}
