package ludi.flowchart;

import ludi.flowchart.model.Graph;
import ludi.flowchart.model.FlowchartNode;
import ludi.flowchart.model.FlowchartConnection;
import ludi.flowchart.model.NodeTemplate;
import ludi.flowchart.ui.CanvasView;
import ludi.flowchart.ui.PaletteView;
import ludi.flowchart.ui.DialogView;
import ludi.flowchart.ui.PreviewDialog;
import ludi.flowchart.ui.OptionsDialog;
import ludi.flowchart.serialize.FlowchartSerializer;
import ludi.flowchart.serialize.IFlowchartSerializer;
import ludi.flowchart.ops.IFlowchartOps;
import ludi.flowchart.ops.DefaultFlowchartOps;
import ludi.flowchart.ops.BrowserFlowchartOps;
import ludi.flowchart.types.CustomParamType;

import ludi.flowchart.model.Note;
import ludi.flowchart.history.TransactionManager;
import ludi.flowchart.history.Transactions;
import ludi.flowchart.ui.ContextMenu;
import ludi.flowchart.ui.FlowchartUILoader;
import ludi.flowchart.FlowchartPlayAdapter;

import ludi.compose.Composition;
import ludi.flowchart.controller.FlowchartController;

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
        this.serializer = serializer != null ? serializer : new FlowchartSerializer(this.customParamTypes);
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
