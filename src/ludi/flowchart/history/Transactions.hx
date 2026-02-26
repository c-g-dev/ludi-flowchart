package ludi.flowchart.history;

import ludi.flowchart.model.Graph;
import ludi.flowchart.model.FlowchartNode;
import ludi.flowchart.model.FlowchartConnection;
import ludi.flowchart.model.Note;

class AddNodeTransaction implements Transaction {
    var graph:Graph<FlowchartNode, FlowchartConnection>;
    var node:FlowchartNode;

    public function new(graph:Graph<FlowchartNode, FlowchartConnection>, node:FlowchartNode) {
        this.graph = graph;
        this.node = node;
    }

    public function undo() {
        graph.removeNode(node);
    }

    public function redo() {
        graph.addNode(node);
    }

    public function getLabel() {
        return "Add Node " + node.template.name;
    }
}

class DeleteNodeTransaction implements Transaction {
    var graph:Graph<FlowchartNode, FlowchartConnection>;
    var node:FlowchartNode;
    var connectedEdges:Array<GraphConnection<FlowchartNode, FlowchartConnection>>;

    public function new(graph:Graph<FlowchartNode, FlowchartConnection>, node:FlowchartNode) {
        this.graph = graph;
        this.node = node;
        this.connectedEdges = graph.adjacent(node);
    }

    public function undo() {
        graph.addNode(node);
        for (edge in connectedEdges) {
            graph.addEdge(edge);
        }
    }

    public function redo() {
        for (edge in connectedEdges) {
            graph.removeEdge(edge);
        }
        graph.removeNode(node);
    }

    public function getLabel() {
        return "Delete Node";
    }
}

class MoveNodeTransaction implements Transaction {
    var node:FlowchartNode;
    var startX:Float;
    var startY:Float;
    var endX:Float;
    var endY:Float;

    public function new(node:FlowchartNode, startX:Float, startY:Float, endX:Float, endY:Float) {
        this.node = node;
        this.startX = startX;
        this.startY = startY;
        this.endX = endX;
        this.endY = endY;
    }

    public function undo() {
        node.x = startX;
        node.y = startY;
    }

    public function redo() {
        node.x = endX;
        node.y = endY;
    }

    public function getLabel() {
        return "Move Node";
    }
}

class ConnectTransaction implements Transaction {
    var graph:Graph<FlowchartNode, FlowchartConnection>;
    var connection:GraphConnection<FlowchartNode, FlowchartConnection>;

    public function new(graph:Graph<FlowchartNode, FlowchartConnection>, connection:GraphConnection<FlowchartNode, FlowchartConnection>) {
        this.graph = graph;
        this.connection = connection;
    }

    public function undo() {
        graph.removeEdge(connection);
    }

    public function redo() {
        graph.addEdge(connection);
    }

    public function getLabel() {
        return "Connect Nodes";
    }
}

class DisconnectTransaction implements Transaction {
    var graph:Graph<FlowchartNode, FlowchartConnection>;
    var connection:GraphConnection<FlowchartNode, FlowchartConnection>;

    public function new(graph:Graph<FlowchartNode, FlowchartConnection>, connection:GraphConnection<FlowchartNode, FlowchartConnection>) {
        this.graph = graph;
        this.connection = connection;
    }

    public function undo() {
        graph.addEdge(connection);
    }

    public function redo() {
        graph.removeEdge(connection);
    }

    public function getLabel() {
        return "Delete Connection";
    }
}

class AddNoteTransaction implements Transaction {
    var notes:Array<Note>;
    var note:Note;

    public function new(notes:Array<Note>, note:Note) {
        this.notes = notes;
        this.note = note;
    }

    public function undo() {
        notes.remove(note);
    }

    public function redo() {
        notes.push(note);
    }

    public function getLabel() {
        return "Add Note";
    }
}

class DeleteNoteTransaction implements Transaction {
    var notes:Array<Note>;
    var note:Note;

    public function new(notes:Array<Note>, note:Note) {
        this.notes = notes;
        this.note = note;
    }

    public function undo() {
        notes.push(note);
    }

    public function redo() {
        notes.remove(note);
    }

    public function getLabel() {
        return "Delete Note";
    }
}

class MoveNoteTransaction implements Transaction {
    var note:Note;
    var startX:Float;
    var startY:Float;
    var endX:Float;
    var endY:Float;

    public function new(note:Note, startX:Float, startY:Float, endX:Float, endY:Float) {
        this.note = note;
        this.startX = startX;
        this.startY = startY;
        this.endX = endX;
        this.endY = endY;
    }

    public function undo() {
        note.x = startX;
        note.y = startY;
    }

    public function redo() {
        note.x = endX;
        note.y = endY;
    }

    public function getLabel() {
        return "Move Note";
    }
}

class EditNoteTextTransaction implements Transaction {
    var note:Note;
    var oldText:String;
    var newText:String;

    public function new(note:Note, oldText:String, newText:String) {
        this.note = note;
        this.oldText = oldText;
        this.newText = newText;
    }

    public function undo() {
        note.text = oldText;
    }

    public function redo() {
        note.text = newText;
    }

    public function getLabel() {
        return "Edit Note Text";
    }
}

class ResizeNoteTransaction implements Transaction {
    var note:Note;
    var startWidth:Float;
    var startHeight:Float;
    var endWidth:Float;
    var endHeight:Float;

    public function new(note:Note, startWidth:Float, startHeight:Float, endWidth:Float, endHeight:Float) {
        this.note = note;
        this.startWidth = startWidth;
        this.startHeight = startHeight;
        this.endWidth = endWidth;
        this.endHeight = endHeight;
    }

    public function undo() {
        note.width = startWidth;
        note.height = startHeight;
    }

    public function redo() {
        note.width = endWidth;
        note.height = endHeight;
    }

    public function getLabel() {
        return "Resize Note";
    }
}
