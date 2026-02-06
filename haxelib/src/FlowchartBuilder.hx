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
import serialize.IFlowchartSerializer;
import ops.IFlowchartOps;
import ops.DefaultFlowchartOps;
import ops.BrowserFlowchartOps;
import types.CustomParamType;

import model.Note;
import history.TransactionManager;
import history.Transactions;
import ui.ContextMenu;
import ui.FlowchartUILoader;
import FlowchartPlayAdapter;

import ludi.compose.Composition;
import controller.FlowchartController;

class FlowchartBuilder {
    var templates:Array<NodeTemplate>;
    var customParamTypes:Array<CustomParamType>;
    var ops:IFlowchartOps;
    var serializer:IFlowchartSerializer;
    var playAdapter:FlowchartPlayAdapter;
    var onSave:Void->Void;
    
    public function new(templates:Array<NodeTemplate>, ?customParamTypes:Array<CustomParamType>, ?ops:IFlowchartOps, ?serializer:IFlowchartSerializer, ?playAdapter:FlowchartPlayAdapter, ?onSave:Void->Void) {
        this.templates = templates;
        this.customParamTypes = customParamTypes != null ? customParamTypes : [];
        if (ops != null) {
            this.ops = ops;
        } else {
            #if hxnodejs
            this.ops = new DefaultFlowchartOps();
            #else
            this.ops = new BrowserFlowchartOps();
            #end
        }
        this.serializer = serializer != null ? serializer : new FlowchartSerializer();
        this.playAdapter = playAdapter;
        this.onSave = onSave;
    }

    public function loadUI(container:js.html.Element) {
        FlowchartUILoader.load(container, init);
    }

    function init() {
        trace("Flowchart Builder Initialized");
        
        var graph = new Graph<FlowchartNode, FlowchartConnection>();
        var notes:Array<Note> = [];
        
        var composition = Composition.create({
            graph: graph,
            notes: notes,
            transactionManager: new TransactionManager(),
            canvasView: new CanvasView("flowchart-canvas", graph, notes),
            paletteView: new PaletteView("palette", templates),
            dialogView: new DialogView("node-editor", customParamTypes),
            previewDialog: new PreviewDialog("preview-dialog"),
            optionsDialog: new OptionsDialog("options-dialog"),
            templates: templates,
            customParamTypes: customParamTypes,
            ops: ops,
            serializer: serializer,
            playAdapter: playAdapter,
            onSave: onSave,
            controller: new FlowchartController()
        });
        
        composition.load();
    }
}
