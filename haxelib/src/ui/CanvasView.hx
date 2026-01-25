package ui;

import model.Graph;
import model.FlowchartNode;
import model.FlowchartConnection;
import model.Note;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.Browser;

class CanvasView {
    public var canvas:CanvasElement;
    public var ctx:CanvasRenderingContext2D;
    public var graph:Graph<FlowchartNode, FlowchartConnection>;
    public var notes:Array<Note>;

    public var offsetX:Float = 0;
    public var offsetY:Float = 0;
    public var scale:Float = 1.0;

    // Interaction State
    var isPanning:Bool = false;
    var panStartX:Float = 0;
    var panStartY:Float = 0;
    var panStartOffsetX:Float = 0;
    var panStartOffsetY:Float = 0;

    var isDraggingNode:Bool = false;
    var isDraggingNote:Bool = false;
    var isResizingNote:Bool = false;
    var dragNodeId:String;
    var dragNoteId:String;
    var resizeNoteId:String;
    var dragStartX:Float = 0;
    var dragStartY:Float = 0;
    var nodeStartX:Float = 0;
    var nodeStartY:Float = 0;
    
    var resizeStartWidth:Float = 0;
    var resizeStartHeight:Float = 0;

    var isConnecting:Bool = false;
    var connStartNodeId:String;
    var mouseX:Float = 0;
    var mouseY:Float = 0;

    public var selectedNodeId:String = null;
    public var selectedNoteId:String = null;
    public var selectedConnection:GraphConnection<FlowchartNode, FlowchartConnection> = null;

    public dynamic function onNodeCreate(templateName:String, x:Float, y:Float) {}
    public dynamic function onEditNode(node:FlowchartNode) {}
    public dynamic function onEditConnection(edge:GraphConnection<FlowchartNode, FlowchartConnection>) {}
    public dynamic function onConnect(sourceId:String, targetId:String) {}
    public dynamic function onMoveNode(node:FlowchartNode, startX:Float, startY:Float, endX:Float, endY:Float) {}
    public dynamic function onMoveNote(note:Note, startX:Float, startY:Float, endX:Float, endY:Float) {}
    public dynamic function onResizeNote(note:Note, startW:Float, startH:Float, endW:Float, endH:Float) {}
    public dynamic function onEditNoteText(note:Note) {} // Changed to just trigger edit
    public dynamic function onContextMenu(x:Float, y:Float, type:String, id:String) {}
    public dynamic function onConnectionContextMenu(x:Float, y:Float, conn:GraphConnection<FlowchartNode, FlowchartConnection>) {}

    public function new(canvasId:String, graph:Graph<FlowchartNode, FlowchartConnection>, notes:Array<Note>) {
        this.graph = graph;
        this.notes = notes;
        this.canvas = cast Browser.document.getElementById(canvasId);
        this.ctx = canvas.getContext2d();

        // Handle resizing
        Browser.window.addEventListener('resize', onResize);
        onResize();

        // Events
        canvas.addEventListener('mousedown', onMouseDown);
        canvas.addEventListener('mousemove', onMouseMove);
        canvas.addEventListener('mouseup', onMouseUp);
        canvas.addEventListener('wheel', onWheel);
        canvas.addEventListener('dblclick', onDoubleClick);
        canvas.addEventListener('contextmenu', onContextMenuEvent);
        
        canvas.addEventListener('dragover', onDragOver);
        canvas.addEventListener('drop', onDrop);

        // Start render loop
        Browser.window.requestAnimationFrame(render);
    }

    function onContextMenuEvent(e:js.html.MouseEvent) {
        e.preventDefault();
        var rect = canvas.getBoundingClientRect();
        var mx = e.clientX; // Screen coords for menu
        var my = e.clientY;
        
        var canvasX = e.clientX - rect.left;
        var canvasY = e.clientY - rect.top;
        var worldX = (canvasX - offsetX) / scale;
        var worldY = (canvasY - offsetY) / scale;

        var node = getNodeAt(worldX, worldY);
        if (node != null) {
            onContextMenu(mx, my, "node", node.id);
            return;
        }

        var note = getNoteAt(worldX, worldY);
        if (note != null) {
            onContextMenu(mx, my, "note", note.id);
            return;
        }

        var conn = getConnectionAt(worldX, worldY);
        if (conn != null) {
            onConnectionContextMenu(mx, my, conn);
            return;
        }
    }

    function onDragOver(e:js.html.DragEvent) {
        e.preventDefault();
    }

    function onDrop(e:js.html.DragEvent) {
        e.preventDefault();
        var templateName = e.dataTransfer.getData("templateName");
        if (templateName != null && templateName != "") {
            var rect = canvas.getBoundingClientRect();
            var mx = e.clientX - rect.left;
            var my = e.clientY - rect.top;
            var worldX = (mx - offsetX) / scale;
            var worldY = (my - offsetY) / scale;

            onNodeCreate(templateName, worldX, worldY);
        }
    }

    function onMouseDown(e:js.html.MouseEvent) {
        var rect = canvas.getBoundingClientRect();
        var mx = e.clientX - rect.left;
        var my = e.clientY - rect.top;
        var worldX = (mx - offsetX) / scale;
        var worldY = (my - offsetY) / scale;

        // 1. Check for Note click
        var note = getNoteAt(worldX, worldY);
        if (note != null) {
            // Check for Resize Handle (Bottom Right 10x10)
            if (worldX > note.x + note.width - 10 && worldY > note.y + note.height - 10) {
                 isResizingNote = true;
                 resizeNoteId = note.id;
                 selectedNoteId = note.id;
                 resizeStartWidth = note.width;
                 resizeStartHeight = note.height;
                 dragStartX = mx;
                 dragStartY = my;
                 return;
            }

            isDraggingNote = true;
            dragNoteId = note.id;
            selectedNoteId = note.id;
            selectedNodeId = null;
            selectedConnection = null;
            dragStartX = mx;
            dragStartY = my;
            nodeStartX = note.x; // Re-use node variables for note dragging
            nodeStartY = note.y;
            return;
        }

        // 2. Check for Node click
        var node = getNodeAt(worldX, worldY);
        if (node != null) {
            // Check for Connection Zone (Right side)
            if (worldX > node.x + 150 - 20) { // Assuming fixed width 150 for now
                 isConnecting = true;
                 connStartNodeId = node.id;
                 mouseX = worldX;
                 mouseY = worldY;
                 selectedNodeId = null;
                 selectedNoteId = null;
                 selectedConnection = null;
                 return;
            }

            // Otherwise Drag
            isDraggingNode = true;
            dragNodeId = node.id;
            selectedNodeId = node.id;
            selectedNoteId = null;
            selectedConnection = null;
            dragStartX = mx;
            dragStartY = my;
            nodeStartX = node.x;
            nodeStartY = node.y;
            return;
        } 

        // 3. Check for Connection Click
        var conn = getConnectionAt(worldX, worldY);
        if (conn != null) {
             selectedConnection = conn;
             selectedNodeId = null;
             selectedNoteId = null;
             return;
        }

        // 4. Background click (Pan start)
        selectedNodeId = null;
        selectedNoteId = null;
        selectedConnection = null;
        isPanning = true;
        panStartX = mx;
        panStartY = my;
        panStartOffsetX = offsetX;
        panStartOffsetY = offsetY;
    }

    function onMouseMove(e:js.html.MouseEvent) {
        var rect = canvas.getBoundingClientRect();
        var mx = e.clientX - rect.left;
        var my = e.clientY - rect.top;
        var worldX = (mx - offsetX) / scale;
        var worldY = (my - offsetY) / scale;
        
        mouseX = worldX;
        mouseY = worldY;

        if (isPanning) {
            var dx = mx - panStartX;
            var dy = my - panStartY;
            offsetX = panStartOffsetX + dx;
            offsetY = panStartOffsetY + dy;
        } else if (isDraggingNode) {
            var dx = (mx - dragStartX) / scale;
            var dy = (my - dragStartY) / scale;
            var node = findNode(dragNodeId);
            if (node != null) {
                // Update locally for visual drag
                node.x = nodeStartX + dx;
                node.y = nodeStartY + dy;
            }
        } else if (isDraggingNote) {
            var dx = (mx - dragStartX) / scale;
            var dy = (my - dragStartY) / scale;
            var note = findNoteById(dragNoteId);
            if (note != null) {
                // Update locally
                note.x = nodeStartX + dx;
                note.y = nodeStartY + dy;
            }
        } else if (isResizingNote) {
            var dx = (mx - dragStartX) / scale;
            var dy = (my - dragStartY) / scale;
            var note = findNoteById(resizeNoteId);
            if (note != null) {
                note.width = Math.max(50, resizeStartWidth + dx);
                note.height = Math.max(50, resizeStartHeight + dy);
            }
        }
    }

    function onMouseUp(e:js.html.MouseEvent) {
        if (isConnecting) {
            var endNode = getNodeAt(mouseX, mouseY);
            if (endNode != null && endNode.id != connStartNodeId) {
                onConnect(connStartNodeId, endNode.id);
            }
        }

        if (isDraggingNode && dragNodeId != null) {
             var node = findNode(dragNodeId);
             if (node != null) {
                 // Trigger Move Transaction
                 onMoveNode(node, nodeStartX, nodeStartY, node.x, node.y);
             }
        }

        if (isDraggingNote && dragNoteId != null) {
             var note = findNoteById(dragNoteId);
             if (note != null) {
                 // Trigger Move Transaction
                 onMoveNote(note, nodeStartX, nodeStartY, note.x, note.y);
             }
        }

        if (isResizingNote && resizeNoteId != null) {
            var note = findNoteById(resizeNoteId);
            if (note != null) {
                onResizeNote(note, resizeStartWidth, resizeStartHeight, note.width, note.height);
            }
        }

        isPanning = false;
        isDraggingNode = false;
        isDraggingNote = false;
        isResizingNote = false;
        isConnecting = false;
        dragNodeId = null;
        dragNoteId = null;
        resizeNoteId = null;
    }

    function onDoubleClick(e:js.html.MouseEvent) {
        var rect = canvas.getBoundingClientRect();
        var mx = e.clientX - rect.left;
        var my = e.clientY - rect.top;
        var worldX = (mx - offsetX) / scale;
        var worldY = (my - offsetY) / scale;

        var node = getNodeAt(worldX, worldY);
        if (node != null) {
            onEditNode(node);
            return;
        }

        var note = getNoteAt(worldX, worldY);
        if (note != null) {
            onEditNoteText(note);
            return;
        }

        var connection = getConnectionAt(worldX, worldY);
        if (connection != null) {
            onEditConnection(connection);
        }
    }

    function onWheel(e:js.html.WheelEvent) {
        e.preventDefault();
        var zoomIntensity = 0.1;
        var delta = e.deltaY < 0 ? 1 : -1;
        var zoom = Math.exp(delta * zoomIntensity);
        
        var rect = canvas.getBoundingClientRect();
        var mx = e.clientX - rect.left;
        var my = e.clientY - rect.top;
        var worldX = (mx - offsetX) / scale;
        var worldY = (my - offsetY) / scale;

        scale *= zoom;
        offsetX = mx - worldX * scale;
        offsetY = my - worldY * scale;
    }

    function onResize(?e) {
        var parent = canvas.parentElement;
        canvas.width = parent.clientWidth;
        canvas.height = parent.clientHeight;
        draw();
    }

    function render(timestamp:Float) {
        draw();
        Browser.window.requestAnimationFrame(render);
    }

    public function draw() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = "#1e1e1e";
        ctx.fillRect(0, 0, canvas.width, canvas.height);

        drawGrid();
        
        // Draw Connections
        for (edge in graph.edges) {
            drawConnection(edge);
        }

        // Draw Temp Connection
        if (isConnecting) {
            var startNode = findNode(connStartNodeId);
            if (startNode != null) {
                var sx = (startNode.x + 150) * scale + offsetX;
                var sy = (startNode.y + 25) * scale + offsetY;
                var tx = mouseX * scale + offsetX;
                var ty = mouseY * scale + offsetY;

                ctx.beginPath();
                ctx.moveTo(sx, sy);
                ctx.lineTo(tx, ty);
                ctx.strokeStyle = "#fff";
                ctx.setLineDash([5, 5]);
                ctx.lineWidth = 2 * scale;
                ctx.stroke();
                ctx.setLineDash([]);
            }
        }

        // Draw Nodes
        for (node in graph.nodes) {
            drawNode(node);
        }
        
        // Draw Notes
        for (note in notes) {
            drawNote(note);
        }
    }

    function drawGrid() {
        var gridSize = 20 * scale;
        ctx.save();
        ctx.translate(offsetX, offsetY);
        ctx.strokeStyle = "#2d2d2d";
        ctx.lineWidth = 1;
        ctx.beginPath();
        var startX = -offsetX;
        var startY = -offsetY;
        var endX = startX + canvas.width;
        var endY = startY + canvas.height;
        var firstLineX = Math.floor(startX / gridSize) * gridSize;
        var firstLineY = Math.floor(startY / gridSize) * gridSize;

        var x = firstLineX;
        while (x < endX) {
            ctx.moveTo(x, startY);
            ctx.lineTo(x, endY);
            x += gridSize;
        }

        var y = firstLineY;
        while (y < endY) {
            ctx.moveTo(startX, y);
            ctx.lineTo(endX, y);
            y += gridSize;
        }
        ctx.stroke();
        ctx.restore();
    }

    function drawNode(node:FlowchartNode) {
        var x = node.x * scale + offsetX;
        var y = node.y * scale + offsetY;
        var w = 150 * scale; // Fixed width for now
        var h = 50 * scale;  // Fixed height for now

        ctx.fillStyle = "#34495e";
        if (node.id == selectedNodeId) ctx.fillStyle = "#2980b9";
        
        ctx.fillRect(x, y, w, h);
        
        ctx.fillStyle = "#ecf0f1";
        ctx.font = '${14 * scale}px Arial';
        ctx.fillText(node.template.name, x + 10 * scale, y + 30 * scale);

        // Connector handle
        ctx.fillStyle = "#95a5a6";
        ctx.fillRect(x + w - 10 * scale, y + 10 * scale, 10 * scale, 30 * scale);
    }

    function drawNote(note:Note) {
        var x = note.x * scale + offsetX;
        var y = note.y * scale + offsetY;
        var w = note.width * scale;
        var h = note.height * scale;
        
        ctx.fillStyle = "#f1c40f"; // Sticky note yellow
        if (note.id == selectedNoteId) ctx.fillStyle = "#f39c12"; // Darker when selected
        
        ctx.fillRect(x, y, w, h);
        
        // Note text
        ctx.fillStyle = "#2c3e50";
        ctx.font = '${12 * scale}px Arial';
        
        // Multi-line text wrapping with newline support
        var lineHeight = 16 * scale;
        var ty = y + 20 * scale;
        var margin = 5 * scale;
        var maxWidth = w - margin * 2;
        
        var paragraphs = note.text.split("\n");
        
        for (paragraph in paragraphs) {
             var words = paragraph.split(" ");
             var line = "";
             
             for (word in words) {
                 var testLine = line + word + " ";
                 var metrics = ctx.measureText(testLine);
                 if (metrics.width > maxWidth && line.length > 0) {
                     ctx.fillText(line, x + margin, ty);
                     line = word + " ";
                     ty += lineHeight;
                 } else {
                     line = testLine;
                 }
             }
             ctx.fillText(line, x + margin, ty);
             ty += lineHeight;
        }
        
        // Resize Handle
        ctx.fillStyle = "rgba(0,0,0,0.1)";
        ctx.beginPath();
        ctx.moveTo(x + w - 10 * scale, y + h);
        ctx.lineTo(x + w, y + h);
        ctx.lineTo(x + w, y + h - 10 * scale);
        ctx.fill();
    }

    function drawConnection(edge:GraphConnection<FlowchartNode, FlowchartConnection>) {
        var sx = (edge.source.x + 150) * scale + offsetX;
        var sy = (edge.source.y + 25) * scale + offsetY;
        var tx = edge.target.x * scale + offsetX;
        var ty = (edge.target.y + 25) * scale + offsetY;

        ctx.beginPath();
        ctx.moveTo(sx, sy);
        ctx.lineTo(tx, ty);
        ctx.strokeStyle = "#bdc3c7";
        if (edge == selectedConnection) ctx.strokeStyle = "#e74c3c"; // Highlight selected
        ctx.lineWidth = 2 * scale;
        ctx.stroke();

        // Draw Tag
        if (edge.edge.tag != null && edge.edge.tag.length > 0) {
             var midX = (sx + tx) / 2;
             var midY = (sy + ty) / 2;
             
             ctx.fillStyle = "#1e1e1e"; // Background for text
             ctx.font = '${12 * scale}px Arial';
             var textWidth = ctx.measureText(edge.edge.tag).width;
             ctx.fillRect(midX - textWidth/2 - 2, midY - 10 * scale, textWidth + 4, 20 * scale);
             
             ctx.fillStyle = "#bdc3c7";
             if (edge == selectedConnection) ctx.fillStyle = "#e74c3c";
             
             ctx.textAlign = "center";
             ctx.textBaseline = "middle";
             ctx.fillText(edge.edge.tag, midX, midY);
             ctx.textAlign = "left"; // Reset
             ctx.textBaseline = "alphabetic"; // Reset
        }
    }

    function getNodeAt(x:Float, y:Float):FlowchartNode {
        for (i in 0...graph.nodes.length) {
            var n = graph.nodes[graph.nodes.length - 1 - i]; // Reverse check
            if (x >= n.x && x <= n.x + 150 && y >= n.y && y <= n.y + 50) {
                return n;
            }
        }
        return null;
    }

    function getConnectionAt(x:Float, y:Float):GraphConnection<FlowchartNode, FlowchartConnection> {
        var threshold = 5.0 / scale; // 5 pixels tolerance, adjusted for scale
        
        for (edge in graph.edges) {
            var startNode = edge.source;
            var endNode = edge.target;
            
            var x1 = startNode.x + 150; // Source output X
            var y1 = startNode.y + 25;  // Source output Y
            var x2 = endNode.x;         // Target input X
            var y2 = endNode.y + 25;    // Target input Y
            
            // Distance from point (x, y) to line segment (x1,y1)-(x2,y2)
            var A = x - x1;
            var B = y - y1;
            var C = x2 - x1;
            var D = y2 - y1;
            
            var dot = A * C + B * D;
            var len_sq = C * C + D * D;
            var param = -1.0;
            if (len_sq != 0) // in case of 0 length line
                param = dot / len_sq;
            
            var xx = 0.0; 
            var yy = 0.0;
            
            if (param < 0) {
                xx = x1;
                yy = y1;
            } else if (param > 1) {
                xx = x2;
                yy = y2;
            } else {
                xx = x1 + param * C;
                yy = y1 + param * D;
            }
            
            var dx = x - xx;
            var dy = y - yy;
            var distance = Math.sqrt(dx * dx + dy * dy);
            
            if (distance < threshold) {
                return edge;
            }
        }
        return null;
    }

    function findNode(id:String):FlowchartNode {
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
    
    function getNoteAt(x:Float, y:Float):Note {
        for (i in 0...notes.length) {
            var n = notes[notes.length - 1 - i]; // Reverse check
            if (x >= n.x && x <= n.x + n.width && y >= n.y && y <= n.y + n.height) {
                return n;
            }
        }
        return null;
    }
}
